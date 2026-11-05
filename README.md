# keyboard-cleaner

A tiny macOS CLI that blocks all keyboard input so you can wipe the keyboard
while the Mac is on. A small floating window with an **Unlock & Quit** button
(clicked with the mouse/trackpad) restores input.

## Build

```sh
./build.sh                      # release build, signed with your Developer ID + hardened runtime
SIGN_IDENTITY="Apple Development" ./build.sh   # or pick another identity
```

The signed binary lands in `bin/keyboard-cleaner`.

## Use

```sh
bin/keyboard-cleaner              # lock until you click "Unlock & Quit"
bin/keyboard-cleaner --timeout 60 # also auto-unlock after 60 seconds
```

Closing the window also unlocks and quits.

## Permissions

Blocking keys uses a `CGEventTap`, which needs **Accessibility** permission
(System Settings → Privacy & Security → Accessibility). macOS grants it to the
*responsible* app: if you run the tool from Terminal/iTerm/etc., enable that
terminal app; if you launch the binary directly, enable `keyboard-cleaner`.
On first run without permission it prompts and exits — grant it and run again.

## What isn't blocked

The power button / Touch ID and the hardware-level Fn/Globe behaviour are
handled below the event-tap layer and can't be intercepted. Avoid pressing the
power button while cleaning.
