#!/usr/bin/env python3
"""Compile the reference's sc-* template dialect into a plain JS render function.

The dialect is small and closed:
  {{ expr }}                          interpolation (text and attribute values)
  <sc-for list="{{X}}" as="p">...     loop
  <sc-if value="{{X}}">...            conditional
  sc-camel-<kebab>="v"                a camelCase prop serialised to kebab
  style-hover="css"                   hover variant of the inline style

Output is string-building JS only -- no eval, no Function(), no runtime engine.
Event props become indices into a per-render handler array, dispatched by one
delegated listener, so no JS ever lands in an inline attribute.
"""
import re, sys, json, os

# SVG/HTML attributes whose real spelling is camelCase, not kebab.
CAMEL_ATTRS = {
    'view-box': 'viewBox', 'preserve-aspect-ratio': 'preserveAspectRatio',
    'gradient-units': 'gradientUnits', 'gradient-transform': 'gradientTransform',
    'spread-method': 'spreadMethod', 'clip-path-units': 'clipPathUnits',
    'pattern-units': 'patternUnits', 'pattern-content-units': 'patternContentUnits',
    'marker-width': 'markerWidth', 'marker-height': 'markerHeight',
    'ref-x': 'refX', 'ref-y': 'refY', 'text-length': 'textLength',
    'start-offset': 'startOffset', 'base-frequency': 'baseFrequency',
    'num-octaves': 'numOctaves', 'std-deviation': 'stdDeviation',
    'tab-index': 'tabindex',
}
# Exactly the three the shim delegates. The reference only uses these three.
# mouseenter/mouseleave/focus/blur do not bubble at all, so they cannot be
# delegated from the host without capture-phase or the focusin/focusout pair --
# listing them here would have compiled handlers that silently never fire.
EVENT_PROPS = {'on-click': 'click', 'on-input': 'input', 'on-change': 'change'}

hover_rules = {}   # css text -> generated class name


def esc_literal(s: str) -> str:
    """Escape a run of literal HTML for embedding in a JS template literal."""
    # The result is embedded in a <script> by assemble.py, and HTML tokenization
    # beats JS lexing: a literal </script> in a text node ends the element no
    # matter that it sits inside a template literal. <\/ decodes back to </.
    s = s.replace('\\', '\\\\').replace('`', '\\`').replace('${', '\\${')
    # Only </script matters, and only case-insensitively: that is the one
    # sequence the HTML tokenizer uses to end the element. Escaping every </
    # would work too but bloats the page for no gain. <\/ decodes back to </.
    return re.sub(r'</(?=script)', '<\\/', s, flags=re.I)


def check_expr(e: str, where: str) -> str:
    """{{ }} bodies are emitted verbatim into the generated JS, so a backtick or
    a ${ closes the template literal the whole page is built from. The input is
    a trusted design-tool export, but nothing enforced that until now."""
    if '`' in e or '${' in e:
        raise SystemExit('%s: expression may not contain ` or ${{ -- got %r' % (where, e[:60]))
    return e


def expr_of(v: str):
    """If an attribute value is exactly one {{ expr }}, return the expr."""
    # (?:(?!\}\}).)* forbids }} inside the group: the old .*? matched
    # "{{a}} {{b}}" as one expression and emitted `a}} {{b` into the JS.
    m = re.fullmatch(r'\s*\{\{((?:(?!\}\}).)*)\}\}\s*', v, re.S)
    return check_expr(m.group(1).strip(), 'attribute value') if m else None


def interp(s: str, fn: str = '__e') -> str:
    """Literal text with {{ }} -> a JS template-literal body.

    fn selects the runtime escaper: __e for anything that ends up as text or a
    plain attribute, __u for href (adds a URL scheme allowlist)."""
    out, last = [], 0
    for m in re.finditer(r'\{\{(.*?)\}\}', s, re.S):
        out.append(esc_literal(s[last:m.start()]))
        out.append('${' + fn + '(function(){return '
                   + check_expr(m.group(1).strip(), 'interpolation') + '})}')
        last = m.end()
    out.append(esc_literal(s[last:]))
    return ''.join(out)


def find_close(src: str, tag: str, start: int) -> int:
    """Index of the matching </tag>, honouring nesting. start = after the open tag."""
    depth, i = 1, start
    # (?=[\s/>]) so <sc-iffy> does not count as a nested <sc-if>
    op_re, cl = re.compile(r'<%s(?=[\s/>])' % tag), '</%s>' % tag
    while i < len(src):
        m_open = op_re.search(src, i)
        no, nc = (m_open.start() if m_open else -1), src.find(cl, i)
        if nc == -1:
            raise SystemExit('unclosed <%s> at %d' % (tag, start))
        if no != -1 and no < nc:
            depth += 1; i = no + len(tag) + 1
        else:
            depth -= 1
            if depth == 0:
                return nc
            i = nc + len(cl)
    raise SystemExit('unclosed <%s>' % tag)


ATTR_RE = re.compile(r'([:\w][-:\w.]*)\s*=\s*"([^"]*)"')


def parse_attrs(s: str):
    return ATTR_RE.findall(s)


def check_attrs_consumed(name: str, attrs_src: str):
    """rewrite_tag rebuilds a tag purely from parse_attrs output, so anything the
    double-quote-only pattern misses -- a single-quoted value, an unquoted one, a
    bare boolean like `disabled`, or a value containing > that truncated the tag --
    was silently dropped from the page. Now it stops the build."""
    residue = ATTR_RE.sub('', attrs_src).strip().strip('/')
    if residue:
        raise SystemExit('<%s ...>: unparsed attribute text %r -- only double-quoted '
                         'attributes are supported' % (name, residue[:60]))


def rewrite_tag(tag_src: str) -> str:
    """Rewrite one open tag: sc-camel-*, style-hover, event props, {{ }} in values."""
    m = re.match(r'<([\w-]+)([\s\S]*?)(/?)>$', tag_src)
    if not m:
        return interp(tag_src)
    name, attrs_src, selfclose = m.group(1), m.group(2), m.group(3)
    check_attrs_consumed(name, attrs_src)
    out_attrs, classes, handlers = [], [], []

    for k, v in parse_attrs(attrs_src):
        if k.startswith('sc-camel-'):
            prop = k[len('sc-camel-'):]
            if prop in EVENT_PROPS:
                e = expr_of(v)
                if e:
                    handlers.append((EVENT_PROPS[prop], e))
                continue
            if prop.startswith('on-'):
                # falling through would emit a literal on-mouse-enter="..."
                # attribute: a handler that looks wired and never fires
                raise SystemExit('%s: the shim only delegates %s -- add it there first'
                                 % (k, ', '.join(sorted(EVENT_PROPS.values()))))
            k = CAMEL_ATTRS.get(prop, prop)
        elif k == 'style-hover':
            # the value is spliced into `.cls:hover{%s}`, so a } escapes the rule
            # and injects arbitrary CSS; a { also catches {{ }} in style-hover,
            # which is never interpolated and so would be silently dead CSS
            if any(ch in v for ch in '{}<@'):
                raise SystemExit('style-hover may not contain { } < or @ -- got %r' % v[:60])
            cls = hover_rules.get(v)
            if not cls:
                cls = 'h%d' % (len(hover_rules) + 1)
                hover_rules[v] = cls
            classes.append(cls)
            continue
        if k == 'href':
            e = expr_of(v)
            if e is not None:
                # whole-attribute or nothing: an empty href="" resolves to the
                # current page, so a row with no source URL plus target="_blank"
                # opened a second copy of the page in a new tab
                out_attrs.append('${__a("href", function(){return %s})}' % e)
                continue
        out_attrs.append('%s="%s"' % (k, interp(v, '__u' if k == 'href' else '__e')))

    for ev, fn in handlers:
        out_attrs.append('data-ev-%s="${__h(__g(function(){return %s}))}"' % (ev, fn))
    if classes:
        merged = False
        for i, a in enumerate(out_attrs):
            if a.startswith('class="'):
                out_attrs[i] = a[:-1] + ' ' + ' '.join(classes) + '"'
                merged = True
                break
        if not merged:
            out_attrs.append('class="%s"' % ' '.join(classes))

    return '<' + name + (' ' + ' '.join(out_attrs) if out_attrs else '') + selfclose + '>'


OPEN_FOR = re.compile(r'<sc-for(?=[\s/>])')
OPEN_IF = re.compile(r'<sc-if(?=[\s/>])')


def compile_frag(src: str) -> str:
    """Compile a fragment into the body of a JS template literal."""
    if '<!--' in src:
        raise SystemExit('HTML comments are not supported: tags and {{ }} inside one '
                         'are still compiled and still evaluate every render')
    out, i = [], 0
    while i < len(src):
        # same word-boundary rule as find_close: a literal find('<sc-if')
        # also matches <sc-iffy>, which then fails as an unclosed <sc-if>
        m_for, m_if = OPEN_FOR.search(src, i), OPEN_IF.search(src, i)
        nf = m_for.start() if m_for else -1
        ni = m_if.start() if m_if else -1
        cands = [x for x in (nf, ni) if x != -1]
        nxt = min(cands) if cands else -1
        if nxt == -1:
            out.append(compile_plain(src[i:]))
            break
        out.append(compile_plain(src[i:nxt]))
        if nxt == nf:
            close_open = src.index('>', nxt)
            attrs = dict(parse_attrs(src[nxt:close_open]))
            body_start = close_open + 1
            body_end = find_close(src, 'sc-for', body_start)
            lst = expr_of(attrs.get('list', ''))
            if lst is None:
                raise SystemExit('<sc-for list=...> must be a single {{ expr }}, got %r'
                                 % attrs.get('list', '')[:60])
            it = attrs.get('as', 'item')
            body = compile_frag(src[body_start:body_end])
            out.append('${(__g(function(){return %s})||[]).map(function(%s,%s_i){return `%s`}).join("")}'
                       % (lst, it, it, body))
            i = body_end + len('</sc-for>')
        else:
            close_open = src.index('>', nxt)
            attrs = dict(parse_attrs(src[nxt:close_open]))
            body_start = close_open + 1
            body_end = find_close(src, 'sc-if', body_start)
            cond = expr_of(attrs.get('value', ''))
            if cond is None:
                raise SystemExit('<sc-if value=...> must be a single {{ expr }}, got %r'
                                 % attrs.get('value', '')[:60])
            body = compile_frag(src[body_start:body_end])
            out.append('${(__g(function(){return %s}))?`%s`:""}' % (cond, body))
            i = body_end + len('</sc-if>')
    return ''.join(out)


def compile_plain(src: str) -> str:
    """Compile a run with no sc-for/sc-if: rewrite tags, interpolate text."""
    out, last = [], 0
    for m in re.finditer(r'<[\w-]+[^>]*?/?>', src):
        out.append(interp(src[last:m.start()]))
        out.append(rewrite_tag(m.group(0)))
        last = m.end()
    out.append(interp(src[last:]))
    return ''.join(out)


# There is deliberately no main(): assemble.py is the only entry point. The one
# that used to live here emitted `__tpl(V, __h, __e)` -- two arguments short of
# what the shim passes -- used `with(V)` instead of `with(__scope(V))`, and read
# markup.html, which skips every deviation assemble.py applies. Its outputs were
# read by nothing.
