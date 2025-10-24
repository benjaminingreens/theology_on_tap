#!/bin/sh
set -eu

MD="content.md"
OUT="index.html"

render() {
  if command -v lowdown >/dev/null 2>&1; then
    lowdown -s -Thtml "$MD"
  elif python3 - <<'PY' >/dev/null 2>&1
import importlib.util, sys
sys.exit(0 if importlib.util.find_spec("markdown") else 1)
PY
  then
    python3 - "$MD" <<'PY'
import sys, markdown
text = open(sys.argv[1], 'r', encoding='utf-8').read()
html = markdown.markdown(
    text,
    extensions=[
        "extra",        # tables, fenced code, etc.
        "sane_lists",
        "attr_list"     # enables "{: .center}" after blocks
    ]
)
print(html)
PY
  elif command -v cmark >/dev/null 2>&1; then
    cmark "$MD"
  else
    esc="$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$MD")"
    printf '<pre>%s</pre>\n' "$esc"
  fi
}

CONTENT_HTML="$(render)"

cat > "$OUT" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    html { height: 100%; box-sizing: border-box; }
    *, *::before, *::after { box-sizing: inherit; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
                   Helvetica, Arial, "Apple Color Emoji", "Segoe UI Emoji",
                   "Segoe UI Symbol", sans-serif;
      display: flex; justify-content: center; align-items: flex-start;
      min-height: 100%; margin: 0; padding: 20px;
      background: #000; color: #fff; font-size: 17px; line-height: 1.7;
    }
    @media (min-width: 768px) { body { padding: 50px; font-size: 20px; } }
    .content { max-width: 900px; width: 100%; text-align: left; }

    /* Headings: normal colors/weights, sensible sizes */
    h1 { font-size: 2.0em; margin: 0.2em 0 0.6em; font-weight: 700; }
    h2 { font-size: 1.5em; margin: 1.4em 0 0.5em; font-weight: 700; color: #fff; }
    h3 { font-size: 1.25em; margin: 1.2em 0 0.4em; font-weight: 600; }
    h4, h5, h6 { margin: 1em 0 0.3em; }

    /* Lists: standard bullets/numbers */
    ul { list-style: disc; padding-left: 1.5em; }
    ol { list-style: decimal; padding-left: 1.5em; }
    li { margin: 0.4em 0; }

    /* Links */
    a { color: #fff; text-decoration: underline; }
    a:hover { text-decoration: none; }

    /* Code */
    code, pre { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; }
    pre { overflow: auto; padding: 0.8em; background: #0f0f0f; border-radius: 6px; }

    /* Blockquotes, hr */
    blockquote { margin: 1em 0; padding-left: 1em; border-left: 4px solid #333; color: #ddd; }
    hr { border: 0; border-top: 1px solid #222; margin: 2em 0; }

    /* Optional helpers */
    .date { color: #aaa; margin: 0 0 2em 0; }
    .center { text-align: center; }
    img { max-width: 100%; height: auto; display: block; margin: 1em auto; }
  </style>
</head>
<body>
  <div class="content">
${CONTENT_HTML}
  </div>
  <script data-goatcounter="https://benjaminingreens.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>
</body>
</html>
HTML

echo "Wrote $OUT"