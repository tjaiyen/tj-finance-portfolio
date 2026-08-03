#!/usr/bin/env python3
"""Gate tests for the template dialect.

Every case here is an input shape that used to fail SILENTLY -- a dropped
attribute, a condition that collapsed to false, a broken-out script tag -- and
now stops the build. None of them occur in reference.html today, which is
exactly why they need a test: a gate with no live trigger is indistinguishable
from a gate that does not work.

    python3 tools/leo-mirror/test_compile.py
"""
import os, re, sys, importlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import compile as C

FAILURES = []


def _fresh():
    """compile_frag appends to a module-level hover_rules; isolate each case."""
    C.hover_rules.clear()


def rejects(label, src, expect_in_msg):
    _fresh()
    try:
        C.compile_frag(src)
    except SystemExit as e:
        if expect_in_msg.lower() in str(e).lower():
            return print('  ok    reject  %s' % label)
        return FAILURES.append('%s: rejected, but message was %r (wanted %r)'
                               % (label, str(e)[:90], expect_in_msg))
    FAILURES.append('%s: NOT REJECTED -- the gate is inert' % label)


def accepts(label, src, expect_in_out=None):
    _fresh()
    try:
        out = C.compile_frag(src)
    except SystemExit as e:
        return FAILURES.append('%s: unexpectedly rejected (%s)' % (label, str(e)[:90]))
    if expect_in_out is not None and expect_in_out not in out:
        return FAILURES.append('%s: output missing %r -- got %r' % (label, expect_in_out, out[:110]))
    print('  ok    accept  %s' % label)


print('rejections (each was a silent failure before):')
# </script> in a text node ends the host <script> element, whatever JS thinks
accepts('</script> in text is neutralised', '<p>see </script> here</p>', '<\\/script')
rejects('> inside an attribute value truncates the tag',
        '<div title="a > b" class="c">z</div>', 'unparsed attribute')
rejects('single-quoted attribute would be dropped',
        "<a aria-current='page' class=\"x\">hi</a>", 'unparsed attribute')
rejects('unquoted attribute would be dropped',
        '<div class=box data-x="1">y</div>', 'unparsed attribute')
rejects('bare boolean attribute would be dropped',
        '<button disabled class="x">go</button>', 'unparsed attribute')
rejects('two expressions in one control attribute',
        '<sc-if value="{{a}} {{b}}">Y</sc-if>', 'single {{ expr }}')
rejects('sc-if value that is not an interpolation',
        '<sc-if value="a && b">Y</sc-if>', 'single {{ expr }}')
rejects('sc-for list that is not an interpolation',
        '<sc-for list="rows" as="r">Y</sc-for>', 'single {{ expr }}')
rejects('backtick in an expression closes the template literal',
        '<p>{{ `x` }}</p>', 'backtick or ${' if False else '` or ${')
rejects('${ in an expression closes the template literal',
        '<p>{{ "${x}" }}</p>', '` or ${')
rejects('style-hover escaping its own CSS rule',
        '<div style-hover="color:red}body{display:none">z</div>', 'style-hover may not contain')
rejects('style-hover with {{ }} would be silently dead CSS',
        '<div style-hover="color:{{c}}">z</div>', 'style-hover may not contain')
rejects('an event prop the shim does not delegate',
        '<div sc-camel-on-mouse-enter="{{ f }}">z</div>', 'only delegates')
rejects('HTML comment would still compile its contents',
        '<!-- <div class="{{x}}">c</div> -->', 'comments are not supported')

print('acceptances (the dialect still works):')
accepts('plain interpolation', '<p>{{ a.b }}</p>', '__e(function(){return a.b})')
accepts('href routes through the URL allowlist', '<a href="{{ r.url }}">x</a>',
        '__u(function(){return r.url})')
accepts('non-href attribute uses the plain escaper', '<img alt="{{ r.alt }}">',
        '__e(function(){return r.alt})')
accepts('sc-for', '<sc-for list="{{ rows }}" as="r">{{ r.x }}</sc-for>', '.map(function(r,r_i)')
accepts('sc-if', '<sc-if value="{{ ok }}">Y</sc-if>', '?`Y`:""')
accepts('nested sc-for inside sc-if',
        '<sc-if value="{{ ok }}"><sc-for list="{{ rows }}" as="r">{{ r.x }}</sc-for></sc-if>',
        '.map(function(r,r_i)')
accepts('a tag merely prefixed sc-if does not break nesting',
        '<sc-if value="{{ a }}"><sc-iffy>x</sc-iffy>Y</sc-if>', 'sc-iffy')
accepts('sc-camel-* maps to the real attribute name',
        '<svg sc-camel-view-box="0 0 1 1"></svg>', 'viewBox="0 0 1 1"')
accepts('event prop becomes a handler index, never inline JS',
        '<button sc-camel-on-click="{{ f }}">x</button>', 'data-ev-click="${__h(')
accepts('style-hover becomes a generated class', '<div style-hover="color:red">z</div>', 'class="h1"')

print('structure:')
if hasattr(C, 'main'):
    FAILURES.append('compile.main() still exists -- it is a divergent second entry point')
else:
    print('  ok    no divergent main() entry point')

# the built page must never contain a live </script inside the emitted script
page = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    '..', '..', 'site', 'src', 'public', 'leo-program-finance.html')
if os.path.exists(page):
    s = open(page, encoding='utf-8').read()
    inner = s[s.find('<script>') + 8:s.rfind('</script>')]
    if inner.lower().count('</script'):
        FAILURES.append('built page: %d live </script inside the emitted script' % inner.lower().count('</script'))
    else:
        print('  ok    built page has no premature </script')
    if s.count('@font-face') != 49:
        FAILURES.append('built page: %d @font-face rules, expected 49 (duplicate style block?)'
                        % s.count('@font-face'))
    else:
        print('  ok    built page ships one copy of the font block')

print()
if FAILURES:
    print('FAILED (%d):' % len(FAILURES))
    for f in FAILURES:
        print('  - ' + f)
    sys.exit(1)
print('all gates fire, dialect intact')
