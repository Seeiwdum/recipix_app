#!/usr/bin/env bash
# Writes the hand-drawn UI icon set into assets/icons/.
# Spec: 24 grid, stroke 1.75, round caps and joins, currentColor, no fill.
# Edit the path data here and re-run; do not hand-edit the generated files.
set -euo pipefail
cd "$(dirname "$0")/../assets/icons"

icon() {
  local name="$1" body="$2"
  printf '%s\n' \
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">' \
    "  $body" \
    '</svg>' > "$name.svg"
}

# Tabs
icon home      '<rect x="5" y="3.5" width="14" height="17" rx="2.5"/><path d="M8.5 8h7M8.5 12h7M8.5 16h4"/>'
icon fridge    '<rect x="5.5" y="2.5" width="13" height="19" rx="2.5"/><path d="M5.5 10h13M8.5 6v1.5M8.5 13v3"/>'
icon scan      '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2M8 12h8"/>'
icon random    '<rect x="3" y="5" width="5" height="14" rx="2"/><rect x="9.5" y="5" width="5" height="14" rx="2"/><rect x="16" y="5" width="5" height="14" rx="2"/><path d="M4.75 12h1.5M11.25 12h1.5M17.75 12h1.5"/>'
icon dashboard '<path d="M4 20h16M7 16v-4M12 16V7M17 16v-6"/>'

# Actions
icon plus      '<path d="M12 5v14M5 12h14"/>'
icon minus     '<path d="M5 12h14"/>'
icon check     '<path d="M5 12.5l4.5 4.5L19 7.5"/>'
icon close     '<path d="M6 6l12 12M18 6L6 18"/>'
icon chevron_right '<path d="M10 6l6 6-6 6"/>'
icon trash     '<path d="M4.5 7h15M10 4h4M6.5 7l.9 11.2a2 2 0 0 0 2 1.8h5.2a2 2 0 0 0 2-1.8L17.5 7M10 11v5M14 11v5"/>'
icon lock      '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8.5 10.5v-3a3.5 3.5 0 0 1 7 0v3"/>'
icon unlock    '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8.5 10.5v-3a3.5 3.5 0 0 1 6.8-1.2"/>'
icon undo      '<path d="M9 7l-4 4 4 4M5 11h9a5 5 0 0 1 0 10h-2"/>'

# Content
icon barcode   '<path d="M4 6v12M7.5 6v12M10 6v12M13.5 6v12M16 6v12M20 6v12"/>'
icon receipt   '<path d="M6 3.5h12v17l-2-1.25-2 1.25-2-1.25-2 1.25-2-1.25-2 1.25z"/><path d="M9 8h6M9 11.5h6M9 15h3.5"/>'
icon leaf      '<path d="M5 19c0-8 5-13 14-14 0 9-5 14-13 14zM5 19l7-7"/>'
icon clock     '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>'
icon basket    '<path d="M3.5 10h17l-1.6 8.2a2 2 0 0 1-2 1.8H7.1a2 2 0 0 1-2-1.8zM8 10l3-5.5M16 10l-3-5.5M9.5 13.5v3M14.5 13.5v3"/>'

echo "icons: $(ls *.svg | wc -l)"
