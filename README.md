# Chime 🔔

A beautiful, native, and lightweight macOS menu bar app that subtly reminds you of the passage of time.

## 🌟 Features

- **Hourly Beep:** By default, gently plays a crisp, premium "Glass" chime exactly at the top of every hour.
- **Visual Cues:** Features non-intrusive visual cues that catch your eye without interrupting your workflow:
  - The menu bar icon elegantly pulses.
  - A sleek, floating time bubble briefly animates underneath your active cursor and fades away.
- **Custom Timers:** Need to focus? Start a Pomodoro or ad-hoc timer (`5m`, `15m`, `30m`, `60m`, `90m`, `120m`). Your menu bar icon will dynamically show you exactly how many minutes are remaining (`🔔 -37m`).
- **Completely Native:** Built in pure Swift using strict macOS native libraries (`NSWindow`, `NSMenu`, `NSTextField`). It takes up essentially 0 processor resources and fits perfectly into the system aesthetic.
- **Accessibility Friendly:** Chime uses macOS accessibility features to draw the exact coordinates of your cursor natively across monitors.
- **Universal Binary:** Built out of the box for both Apple Silicon (M1/M2/M3) and Intel Macs running macOS 11+.

## ⚙️ Installation

Just grab `Chime.app` and drag it into your `Applications` folder! Unzip the app, open it, and macOS will prompt you for an Accessibility permission. Toggle the switch for Chime in your System Settings, and you're perfectly set up!

## 🚀 Development / Building from Source

Chime is incredibly simple, relying only on standard Apple libraries. It can be compiled in seconds without an Xcode project file:

```bash
# Compile for Apple Silicon
swiftc Chime.swift -parse-as-library -target arm64-apple-macos11 -o Chime_arm64

# Compile for Intel
swiftc Chime.swift -parse-as-library -target x86_64-apple-macos11 -o Chime_x86

# Merge into Universal App Bundle
lipo -create -output Chime.app/Contents/MacOS/Chime Chime_arm64 Chime_x86
rm Chime_arm64 Chime_x86
```

## Credits

Sound Effect: Kenney *Glass 004* (CC0)
