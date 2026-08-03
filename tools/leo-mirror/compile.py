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
    return s.replace('\\', '\\\\').replace('`', '\\`').replace('${', '\\${')


def expr_of(v: str):
    """If an attribute value is exactly one {{ expr }}, return the expr."""
    m = re.fullmatch(r'\s*\{\{(.*?)\}\}\s*', v, re.S)
    return m.group(1).strip() if m else None


def interp(s: str, fn: str = '__e') -> str:
    """Literal text with {{ }} -> a JS template-literal body.

    fn selects the runtime escaper: __e for anything that ends up as text or a
    plain attribute, __u for href (adds a URL scheme allowlist)."""
    out, last = [], 0
    for m in re.finditer(r'\{\{(.*?)\}\}', s, re.S):
        out.append(esc_literal(s[last:m.start()]))
        out.append('${' + fn + '(function(){return ' + m.group(1).strip() + '})}')
        last = m.end()
    out.append(esc_literal(s[last:]))
    return ''.join(out)


def find_close(src: str, tag: str, start: int) -> int:
    """Index of the matching </tag>, honouring nesting. start = after the open tag."""
    depth, i = 1, start
    op, cl = '<%s' % tag, '</%s>' % tag
    while i < len(src):
        no, nc = src.find(op, i), src.find(cl, i)
        if nc == -1:
            raise SystemExit('unclosed <%s> at %d' % (tag, start))
        if no != -1 and no < nc:
            depth += 1; i = no + len(op)
        else:
            depth -= 1
            if depth == 0:
                return nc
            i = nc + len(cl)
    raise SystemExit('unclosed <%s>' % tag)


def parse_attrs(s: str):
    return re.findall(r'([:\w][-:\w.]*)\s*=\s*"([^"]*)"', s)


def rewrite_tag(tag_src: str) -> str:
    """Rewrite one open tag: sc-camel-*, style-hover, event props, {{ }} in values."""
    m = re.match(r'<([\w-]+)([\s\S]*?)(/?)>$', tag_src)
    if not m:
        return interp(tag_src)
    name, attrs_src, selfclose = m.group(1), m.group(2), m.group(3)
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
            cls = hover_rules.get(v)
            if not cls:
                cls = 'h%d' % (len(hover_rules) + 1)
                hover_rules[v] = cls
            classes.append(cls)
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


def compile_frag(src: str) -> str:
    """Compile a fragment into the body of a JS template literal."""
    out, i = [], 0
    while i < len(src):
        nf, ni = src.find('<sc-for', i), src.find('<sc-if', i)
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
            lst = expr_of(attrs.get('list', '')) or 'null'
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
            cond = expr_of(attrs.get('value', '')) or 'false'
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


def main():
    markup = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'markup.html'), encoding='utf-8').read()
    body = compile_frag(markup)
    css = '\n'.join('.%s:hover{%s}' % (cls, rules) for rules, cls in hover_rules.items())

    js = ('// GENERATED by compile.py from the design reference template -- do not hand-edit.\n'
          'function __tpl(V, __h, __e){ with(V){ return `' + body + '`; } }\n')
    open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'template.gen.js'), 'w', encoding='utf-8').write(js)
    open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'hover.gen.css'), 'w', encoding='utf-8').write(css)
    print('template.gen.js  %d bytes' % len(js))
    print('hover.gen.css    %d bytes  (%d rules)' % (len(css), len(hover_rules)))


if __name__ == '__main__':
    main()
