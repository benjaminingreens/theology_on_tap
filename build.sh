#!/bin/sh
set -eu

MD="content.md"
OUT="index.html"

# --- choose a markdown renderer (no hard-coding of structure) ---
render() {
  if command -v lowdown >/dev/null 2>&1; then
    # fast C renderer
    lowdown -s -Thtml "$MD"
  elif python3 - <<'PY' >/dev/null 2>&1
import importlib.util; import sys
sys.exit(0 if importlib.util.find_spec("markdown") else 1)
PY
  then
    # Python markdown lib
    python3 - "$MD" <<'PY'
import sys, markdown
print(markdown.markdown(open(sys.argv[1], 'r', encoding='utf-8').read()))
PY
  elif command -v cmark >/dev/null 2>&1; then
    # CommonMark reference parser
    cmark "$MD"
  else
    # last-resort: keep content readable without guessing structure
    # (escape HTML and wrap in <pre>)
    esc="$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$MD")"
    printf '<pre>%s</pre>\n' "$esc"
  fi
}

CONTENT_HTML="$(render)"

# --- write the styled page wrapper (your exact style) ---
cat > "$OUT" <<HTML
<!DOCTYPE html>
<html lang="en">
<script data-goatcounter="https://benjaminingreens.goatcounter.com/count"
        async src="//gc.zgo.at/count.js"></script>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link href="https://fonts.googleapis.com/css2?family=Source+Code+Pro:wght@400;700&display=swap" rel="stylesheet">
  <style>
    html { height: 100%; box-sizing: border-box; }
    *, *::before, *::after { box-sizing: inherit; }
    body {
      font-family: 'Source Code Pro', monospace;
      display: flex; justify-content: center; align-items: flex-start;
      min-height: 100%; margin: 0; padding: 20px;
      background-color: black; color: white;
      font-size: 17px; line-height: 1.7;
    }
    @media (min-width: 768px) { body { padding: 50px; font-size: 20px; } }
    .content { max-width: 600px; width: 100%; text-align: left; }
    @media (min-width: 1024px) { .content { max-width: 900px; } }
    h1 { font-size: 2em; margin-bottom: 0.2em; text-align: left; }
    h2 { font-size: 1em; font-style: italic; color: grey; margin-bottom: 1em; text-align: left; font-weight: normal; }
    .date { color: grey; margin: 0 0 2em 0; }
    ul { list-style-type: none; padding: 0; }
    li { margin: 1em 0; text-indent: -1em; padding-left: 1em; }
    li::before { content: '* '; }
    a { color: white; text-decoration: underline; }
    a:hover { text-decoration: none; }
    img {max-width: 100%; height: auto; display: block; margin: 1em 0; }
  </style>
</head>
<body>
  <div class="content">
${CONTENT_HTML}
  </div>
</body>
</html>
HTML

echo "Wrote $OUT"