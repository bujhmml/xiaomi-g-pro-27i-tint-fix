# Xiaomi G Pro 27i — fix warm tint after wake (macOS)

A one-line shell script that does in software what the OSD button trick does manually:
switch the picture mode to a different color preset and back, which forces the monitor's
color pipeline to re-converge and clears the warm/yellow/red tint that appears on every
sleep/wake or cold start.

The monitor: **Xiaomi Gaming Monitor G Pro 27i (ELA5585EU)**, MiniLED, 1440p@180Hz.
Tested on firmware `1.0.07`. The tint is a documented firmware-level issue across
revisions `1.0.06`–`1.0.10`. There is no public firmware update path — see *Background*.

## What it does

Sends one DDC command to set `selectColorPreset` (VCP `0x14`) to `6` (7500K), waits
1.2 seconds, then sets it back to `5` (6500K). From the monitor's point of view this is
the same kind of event as pressing the OSD joystick to switch picture mode and back.

If your monitor reports a different value for the standard preset, change the two
arguments in the script. See *Tuning* below.

## Requirements

- macOS on Apple Silicon (tested on macOS 26 Tahoe, M1 Pro)
- [BetterDisplay](https://github.com/waydabber/BetterDisplay) running, with HTTP
  integration enabled:
  - Settings → Application → Integration → toggle **Enable integrated HTTP server**
  - Leave the default port `55777` and no security token
- `curl` (preinstalled on macOS)

## Why BetterDisplay and not m1ddc

Direct DDC via `m1ddc` is unreliable on this specific monitor. The first write per
session usually applies, subsequent writes are silently dropped, and reads return
placeholder values (e.g. `-120` for luminance). This is independently documented in
[BetterDisplay discussion #3652](https://github.com/waydabber/BetterDisplay/discussions/3652).

BetterDisplay's DDC engine reaches the monitor through a different IOKit pathway that
this panel honours consistently. Every brightness key press on macOS Tahoe goes through
that pathway too — which is why pressing brightness up once on the keyboard happens to
"fix" the tint in one keystroke.

## Install

```sh
mkdir -p ~/bin
curl -fsSL https://raw.githubusercontent.com/bujhmml/xiaomi-g-pro-27i-tint-fix/main/fix-monitor-tint.sh \
  -o ~/bin/fix-monitor-tint.sh
chmod +x ~/bin/fix-monitor-tint.sh
```

## Run

```sh
~/bin/fix-monitor-tint.sh
```

The screen should not flicker. If the script runs and nothing visible changes when the
tint is present, jump to *Tuning*.

## Bind to a hotkey

### Raycast

The script ships with Raycast Script Command headers.

1. Raycast → Settings → Extensions
2. `+` at the bottom of the sidebar → **Add Script Directory** → select `~/bin`
3. The command **Fix Monitor Tint** appears under "Display" — assign any hotkey
   (`⌥⇧↩` is a safe pick; it doesn't conflict with AeroSpace, Karabiner, or any default
   macOS shortcut)

### Anything else

It's a plain shell script. Bind it via Alfred, Karabiner-Elements complex modifications,
a launchd agent on wake, sleepwatcher `~/.wakeup`, BetterTouchTool, Stream Deck — pick
your tool.

### Auto on wake (not yet validated)

The natural next step is running the script on every wake via `sleepwatcher`:

```sh
brew install sleepwatcher
brew services start sleepwatcher
cat > ~/.wakeup <<'EOF'
#!/usr/bin/env bash
sleep 3   # let BetterDisplay's HTTP server come back up
~/bin/fix-monitor-tint.sh
EOF
chmod +x ~/.wakeup
```

I have not personally run this for a long enough period to be sure the BetterDisplay
HTTP server is consistently ready by the time the script fires. Start with the manual
hotkey, observe for a week, then automate.

## Tuning

If the toggle `6 → 5` doesn't produce the fix on your firmware, try larger jumps. Edit
the last two lines of the script:

```sh
bd_set 8   # 9300K instead of 7500K — bigger color delta
sleep 1.2
bd_set 5
```

DDC color preset values per the standard:
| Value | Color preset |
|------:|--------------|
| `1`   | sRGB |
| `2`   | Display Native |
| `3`   | 4000K |
| `4`   | 5000K |
| `5`   | 6500K (standard for most users) |
| `6`   | 7500K |
| `7`   | 8200K |
| `8`   | 9300K |
| `9`   | 10000K |
| `10`  | 11500K |
| `11`  | User 1 |

You can read your monitor's current value:

```sh
curl -s "http://localhost:55777/get?nameLike=Mi&ddc&vcp=selectColorPreset"
```

If the script doesn't find your monitor, change `ID="nameLike=Mi"` to match a substring
of the name BetterDisplay shows for it. List your displays:

```sh
curl -s "http://localhost:55777/get?identifiers"
```

## Background

Symptom: every time the monitor wakes from sleep, returns from a DisplayPort handshake,
or is first powered on, it shows a warm yellow/red tint. The tint fades on its own after
10–15 minutes (Quantum Dot panel thermal warmup, normal) — or instantly, by switching
the picture mode in the OSD to anything else and back.

This is not a bad unit. The warmup is normal for QD panels, but the *failure to converge
to a neutral state on its own* is a firmware bug present in multiple firmware revisions:

- `1.0.06` — strong red tint, especially in HDR
- `1.0.07` — partial fix, still warm on wake
- `1.0.08` — additional HDR-related fixes
- `1.0.10` — red tint regression

Xiaomi has not released a user-flashable firmware update for this monitor. The monitor
has no USB ports and no "Mi Display Manager" utility exists for the G-series. RMA
outcomes are inconsistent — several users report receiving an exchange unit with the
same firmware.

References:

- [Linus Tech Tips — Red Tint In Display (Xiaomi G Pro 27i)](https://linustechtips.com/topic/1608868-red-tint-in-display-xiaomi-g-pro-27i/)
- [Overclockers UK forum thread](https://forums.overclockers.co.uk/threads/xiaomi-mini-led-gaming-monitor-g-pro-27i.19000359/)
- [Galaxus Q&A — firmware 1.06 issues](https://www.galaxus.it/en/s1/questionandanswer/lots-of-the-reviews-are-mentioning-a-buggy-firmware-1006-du-firmware-and-that-the-monitor-doesnt-all-766867)
- [BetterDisplay #3652 — DDC unreliable on this monitor](https://github.com/waydabber/BetterDisplay/discussions/3652)

## What didn't work, in case you're investigating the same problem

- **m1ddc** — accepts writes but the monitor silently drops everything after the first
  command per session. Reads return junk (`-120` for luminance and contrast).
- **`reinitialize` via BetterDisplay** — works, but is too heavy. macOS treats it as a
  display disconnect/reconnect and may lock the screen.
- **Pure brightness toggle** — does clear the tint visually because brightness writes
  are accepted by this monitor, but it's more disruptive than a color preset detour
  that returns to the same temperature.
- **Firmware update** — not an option. Xiaomi has not released one and the monitor has
  no input port that could carry it.

## Contributing

If you have a different firmware revision, a different Xiaomi G-series model, or you
found that a different VCP works better — open an issue or PR with what you tested and
what happened. Including your firmware version (Settings → System Info on the monitor)
helps.

## License

MIT — see [LICENSE](LICENSE).
