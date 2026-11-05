// keyboard-cleaner: swallow all keyboard input until the "Unlock & Quit" button is clicked.
//
// Usage: keyboard-cleaner [--timeout SECONDS]
//
// Uses a CGEventTap, which requires Accessibility permission for the process
// (or, when launched from a terminal, for the terminal app).

import AppKit
import ApplicationServices

// MARK: - Arguments

nonisolated(unsafe) var timeout: TimeInterval?
let args = Array(CommandLine.arguments.dropFirst())
if args.contains(where: { $0 == "-h" || $0 == "--help" }) {
    print("Usage: keyboard-cleaner [--timeout SECONDS]")
    print("Blocks all keyboard input until you click \"Unlock & Quit\" (or the timeout elapses).")
    exit(0)
}
if let i = args.firstIndex(where: { $0 == "--timeout" || $0 == "-t" }) {
    guard i + 1 < args.count, let seconds = TimeInterval(args[i + 1]), seconds > 0 else {
        fputs("--timeout requires a positive number of seconds\n", stderr)
        exit(2)
    }
    timeout = seconds
}

// MARK: - Permission

let promptKey = "AXTrustedCheckOptionPrompt" // kAXTrustedCheckOptionPrompt
guard AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary) else {
    fputs("""
    keyboard-cleaner needs Accessibility permission to block the keyboard.
    Grant it in System Settings → Privacy & Security → Accessibility
    (to this binary, or to your terminal app if you run it from a terminal), then run again.

    """, stderr)
    exit(1)
}

// MARK: - Event tap

// Key down/up, modifier changes, and NX_SYSDEFINED (media, volume, brightness keys).
let blockedTypes: [UInt32] = [
    CGEventType.keyDown.rawValue,
    CGEventType.keyUp.rawValue,
    CGEventType.flagsChanged.rawValue,
    14, // NX_SYSDEFINED
]
let eventMask = blockedTypes.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }

nonisolated(unsafe) var eventTap: CFMachPort?

let callback: CGEventTapCallBack = { _, type, event, _ in
    // The system disables slow or interrupted taps; turn it straight back on.
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    return nil // swallow
}

guard let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: eventMask,
    callback: callback,
    userInfo: nil
) else {
    fputs("Failed to create event tap. Check Accessibility permission.\n", stderr)
    exit(1)
}
eventTap = tap
let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

// MARK: - Window

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 260, height: 110),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let label = NSTextField(labelWithString: "⌨️  Keyboard locked — clean away.")
        label.alignment = .center

        let button = NSButton(title: "Unlock & Quit", target: self, action: #selector(unlock))
        button.bezelStyle = .rounded
        button.controlSize = .large

        let stack = NSStackView(views: [label, button])
        stack.orientation = .vertical
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        window.title = "Keyboard Cleaner"
        window.contentView = stack
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if let timeout {
            Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                MainActor.assumeIsolated { NSApp.terminate(nil) }
            }
        }
    }

    @objc func unlock() {
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: false) }
        print("Keyboard unlocked.")
    }
}

print("Keyboard locked. Click \"Unlock & Quit\" to restore input.")
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
