#!/usr/bin/env bash
#
# Fix warm tint on Xiaomi G Pro 27i after wake/connect by issuing a DDC
# "restore factory color defaults" command (VCP 0x08). Same effect as the
# OSD trick where you switch picture mode to Eco and back to Standard.
# Routed through BetterDisplay's HTTP integration because direct DDC via
# m1ddc is unreliable on this monitor (BetterDisplay discussion #3652).
#
# Requires BetterDisplay running with HTTP integration enabled on port 55777.
#
# @raycast.schemaVersion 1
# @raycast.title Fix Monitor Tint
# @raycast.mode silent
# @raycast.packageName Display
# @raycast.icon 🖥️
# @raycast.description Clear post-wake warm tint on Xiaomi G Pro 27i

curl -fsS --max-time 3 \
  "http://localhost:55777/set?nameLike=Mi&ddc&vcp=restoreFactoryColorDefaults&value=1" \
  >/dev/null 2>&1 || true
