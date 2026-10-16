#!/usr/bin/env bash
# Writes flat ingredient illustrations into assets/ingredients/<key>.svg.
# Spec: 48 grid, flat shapes, 3-4 colours, no outlines, no gradients.
# The rounded frame is drawn by IngredientTile, not by the art.
# File names are recipix_core ingredient keys.
set -euo pipefail
cd "$(dirname "$0")/../assets/ingredients"

art() {
  local key="$1" body="$2"
  printf '%s\n' \
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">' \
    "  $body" \
    '</svg>' > "$key.svg"
}

art egg       '<ellipse cx="24" cy="26" rx="12" ry="15" fill="#E7C8A0"/><path d="M24 41c6.6 0 12-6.7 12-15 0-1.6-.2-3.1-.6-4.6C33 31 27 36 18 38.6c1.8 1.5 3.8 2.4 6 2.4z" fill="#D6AE80"/><ellipse cx="19.5" cy="19" rx="3" ry="4.5" fill="#F3E2C8"/>'
art tomato    '<circle cx="24" cy="27" r="14" fill="#D4553F"/><path d="M38 27c0 7.7-6.3 14-14 14-5 0-9.3-2.6-11.8-6.5 9.4 2.4 21.5-1.8 25.6-11.6.1 1.4.2 2.7.2 4.1z" fill="#B5412E"/><path d="M24 14l2.5-4 1 4.6 4.5-.6-3.4 3.4 2.4 3-4.6-1.4L24 22l-2.4-3-4.6 1.4 2.4-3-3.4-3.4 4.5.6 1-4.6z" fill="#3F7A4F"/>'
art chili     '<path d="M13 15c6 1 9 6 12 13s7 11 12 12c-9 3-19-2-24-11-2-4-2-9 0-14z" fill="#C9432F"/><path d="M15 26c3 7 9 12 17 13.8-6 .8-12.6-2.2-16.4-8.3-.7-1.8-1-3.6-.6-5.5z" fill="#A93424"/><path d="M13 15c-1-3 0-6 3-8l1.5 1.5c-2 1.4-2.6 3.4-2 5.6z" fill="#3F7A4F"/>'
art holy_basil '<path d="M24 42V20" stroke="#2F5A3C" stroke-width="2.5" stroke-linecap="round"/><path d="M24 22c-8 0-13-5-13-12 8 0 13 5 13 12z" fill="#4E8A5A"/><path d="M24 22c8 0 13-5 13-12-8 0-13 5-13 12z" fill="#3F7A4F"/><path d="M24 33c-6 0-10-4-10-9 6 0 10 4 10 9z" fill="#3F7A4F"/><path d="M24 33c6 0 10-4 10-9-6 0-10 4-10 9z" fill="#4E8A5A"/>'
art pork      '<path d="M9 18c0-4 4-7 9-7h14c5 0 8 3 8 7v10c0 5-4 9-9 9H17c-5 0-8-4-8-9z" fill="#E6A496"/><path d="M9 25h31v3c0 5-4 9-9 9H17c-5 0-8-4-8-9z" fill="#CB7F70"/><path d="M14 17c4-2 9-2 13 0s9 2 13 0" stroke="#F6E4DA" stroke-width="3" stroke-linecap="round" fill="none"/>'
art rice      '<path d="M8 25h32c0 9-7 15-16 15S8 34 8 25z" fill="#B9A487"/><path d="M8 25h32c0 2-.4 3.9-1.2 5.6H9.2C8.4 28.9 8 27 8 25z" fill="#A08B6E"/><path d="M10 25c0-6 6-11 14-11s14 5 14 11z" fill="#FBF7EF"/><path d="M17 20h2M23 18h2M28 21h2M21 23h2" stroke="#E3DBCE" stroke-width="2" stroke-linecap="round"/>'
art lime      '<circle cx="24" cy="25" r="14" fill="#7BA54A"/><circle cx="24" cy="25" r="10.5" fill="#B9D38A"/><path d="M24 15.5v19M14.5 25h19M17.3 18.3l13.4 13.4M30.7 18.3L17.3 31.7" stroke="#E3EDCB" stroke-width="1.5"/><circle cx="24" cy="25" r="1.8" fill="#E3EDCB"/>'
art milk      '<path d="M15 16l4-7h10l4 7z" fill="#E3DBCE"/><rect x="15" y="16" width="18" height="25" rx="2" fill="#FBF8F2"/><rect x="15" y="24" width="18" height="9" fill="#6E8FA3"/><path d="M33 16v23a2 2 0 0 1-2 2h-3V16z" fill="#E9E3D8"/>'
art cabbage   '<circle cx="24" cy="25" r="15" fill="#8DB46A"/><path d="M24 10c-5 4-7 9-7 15s2 11 7 15c5-4 7-9 7-15s-2-11-7-15z" fill="#A9C98A"/><path d="M24 14v22M24 22l-4-3M24 28l4-3" stroke="#D3E3BE" stroke-width="1.75" stroke-linecap="round"/>'

echo "ingredients: $(ls *.svg | wc -l)"
