#!/bin/sh
set -eu

# Usage:
#   ./build.sh               # build all *.md in current dir
#   ./build.sh file1.md ...  # build only specific files

# --- choose a renderer once ---
RENDER=""
if command -v lowdown >/dev/null 2>&1; then
  RENDER="lowdown"
elif python3 - <<'PY' >/dev/null 2>&1
import importlib.util, sys
sys.exit(0 if importlib.util.find_spec("markdown") else 1)
PY
then
  RENDER="py"
elif command -v cmark >/dev/null 2>&1; then
  RENDER="cmark"
else
  RENDER="plain"
fi

render_md() {
  md="$1"
  case "$RENDER" in
    lowdown)
      lowdown -s -Thtml "$md"
      ;;
    py)
      python3 - "$md" <<'PY'
import sys, markdown
p = sys.argv[1]
text = open(p, 'r', encoding='utf-8').read()
html = markdown.markdown(
    text,
    extensions=["extra","sane_lists","attr_list"]
)
print(html)
PY
      ;;
    cmark)
      cmark --unsafe "$md"
      ;;
    plain)
      sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$md" |
      sed '1s/^/<pre>/' -e '$s/$/<\/pre>/'
      ;;
  esac
}

write_page() {
  md="$1"
  out="$2"

  # --- detect optional layout hint in first 20 lines ---
  PAGE_CLASS="$(
    head -n 20 "$md" | tr -d '\r' \
    | grep -i -m1 -E '<!--[[:space:]]*layout:[[:space:]]*(left|center|justify|center-vert)[[:space:]]*-->' \
    | sed -E 's/.*layout:[[:space:]]*([a-z-]+).*/\1/i'
  )"
  [ -n "${PAGE_CLASS:-}" ] || PAGE_CLASS="left"

  CONTENT_HTML="$(render_md "$md")"

  cat > "$out" <<HTML
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
      background: #000; color: #fff; font-size: 20px; line-height: 1.7;
    }
    @media (min-width: 768px) { body { padding: 50px; font-size: 20px; } }

    /* Core content block */
    .content { max-width: 900px; width: 100%; text-align: left; }

    /* Headings */
    h1 { font-size: 2.0em; margin: 0.2em 0 0.6em; font-weight: 700; }
    h2 { font-size: 1.5em; margin: 1.4em 0 0.5em; font-weight: 700; color: #fff; }
    h3 { font-size: 1.25em; margin: 1.2em 0 0.4em; font-weight: 600; }
    h4, h5, h6 { margin: 1em 0 0.3em; }

    /* Lists */
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

    /* Helpers */
    .date { color: #aaa; margin: 0 0 2em 0; }
    .center { text-align: center; }
    img { max-width: 100%; height: auto; display: block; margin: 1em auto; }

    /* Layout variants */
    .content.left    { text-align: left; }
    .content.center  { text-align: center; }
    .content.justify { text-align: justify; text-justify: inter-word; }
    .content.center-vert { align-self: center; }
  </style>
</head>
<body>
  <div class="content ${PAGE_CLASS}">
${CONTENT_HTML}
  </div>
  <script data-goatcounter="https://benjaminingreens.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>
</body>
</html>
HTML

  echo "Wrote $out"
}

build_one() {
  md="$1"
  case "$md" in
    *.md) ;;
    *) echo "Skip (not .md): $md" >&2; return ;;
  esac
  base=$(basename "$md" .md)
  out="${base}.html"
  write_page "$md" "$out"
}

if [ "$#" -gt 0 ]; then
  for md in "$@"; do
    build_one "$md"
  done
else
  set -- ./*.md
  if [ ! -e "$1" ] || [ "$1" = "./*.md" ]; then
    echo "No .md files found."
  else
    for md in "$@"; do
      build_one "${md#./}"
    done
  fi
fi