import SwiftUI
import AppKit

@main
struct ChimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var currentSound: NSSound?
    var currentOverlayWindow: CursorTimeWindow?
    
    var countdownTimer: Timer?
    var timerEndDate: Date?
    
    @AppStorage("beepEnabled") var beepEnabled: Bool = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        _ = AXIsProcessTrustedWithOptions(options)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        updateIcon()
        setupMenu()
        scheduleNextBeep()
    }
    
    func updateIcon() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: beepEnabled ? "bell.fill" : "bell.slash.fill", accessibilityDescription: "Chime")
            if let endDate = timerEndDate {
                let remaining = endDate.timeIntervalSince(Date())
                if remaining > 0 {
                    let mins = Int(ceil(remaining / 60.0))
                    button.title = " -\(mins)m"
                } else {
                    button.title = ""
                }
            } else {
                button.title = ""
            }
        }
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: beepEnabled ? "Disable Chime" : "Enable Chime", action: #selector(toggleBeep), keyEquivalent: "")
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let timerMenu = NSMenu()
        timerMenu.addItem(NSMenuItem(title: "5 Minutes", action: #selector(startTimer5), keyEquivalent: ""))
        timerMenu.addItem(NSMenuItem(title: "15 Minutes", action: #selector(startTimer15), keyEquivalent: ""))
        timerMenu.addItem(NSMenuItem(title: "30 Minutes", action: #selector(startTimer30), keyEquivalent: ""))
        timerMenu.addItem(NSMenuItem(title: "60 Minutes", action: #selector(startTimer60), keyEquivalent: ""))
        timerMenu.addItem(NSMenuItem(title: "90 Minutes", action: #selector(startTimer90), keyEquivalent: ""))
        timerMenu.addItem(NSMenuItem(title: "120 Minutes", action: #selector(startTimer120), keyEquivalent: ""))
        
        let timerItem = NSMenuItem(title: "Start Timer", action: nil, keyEquivalent: "")
        timerItem.submenu = timerMenu
        menu.addItem(timerItem)
        
        if countdownTimer != nil {
            menu.addItem(NSMenuItem(title: "Cancel Timer...", action: #selector(cancelTimer), keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Test Chime", action: #selector(playBeep), keyEquivalent: "t"))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Chime", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func toggleBeep() {
        beepEnabled.toggle()
        updateIcon()
        setupMenu()
    }
    
    @objc func startTimer5() { startTimer(minutes: 5) }
    @objc func startTimer15() { startTimer(minutes: 15) }
    @objc func startTimer30() { startTimer(minutes: 30) }
    @objc func startTimer60() { startTimer(minutes: 60) }
    @objc func startTimer90() { startTimer(minutes: 90) }
    @objc func startTimer120() { startTimer(minutes: 120) }
    
    func startTimer(minutes: Int) {
        cancelTimer()
        timerEndDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        updateIcon()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
        setupMenu()
    }
    
    @objc func cancelTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        timerEndDate = nil
        updateIcon()
        setupMenu()
    }
    
    @objc func timerTick() {
        guard let endDate = timerEndDate else { return }
        let remaining = endDate.timeIntervalSince(Date())
        if remaining <= 0 {
            cancelTimer()
            triggerAlert()
        } else {
            updateIcon()
        }
    }
    
    func playSoundEffect() {
        let soundName = "glass-004"
        if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3"),
           let sound = NSSound(contentsOf: url, byReference: true) {
            self.currentSound = sound
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    func blinkMenuBarIcon() {
        guard let button = statusItem.button else { return }
        
        let blinkCount = 6
        let blinkDuration = 0.3
        
        for i in 0..<blinkCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * blinkDuration) {
                button.alphaValue = (i % 2 == 0) ? 0.3 : 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(blinkCount) * blinkDuration) {
            button.alphaValue = 1.0
        }
    }
    
    func showCursorTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        
        let overlayWindow = CursorTimeWindow(timeString: timeString)
        self.currentOverlayWindow = overlayWindow
        
        overlayWindow.alphaValue = 0.0
        overlayWindow.makeKeyAndOrderFront(nil)
        
        overlayWindow.contentView?.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            overlayWindow.animator().alphaValue = 1.0
            overlayWindow.contentView?.animator().layer?.transform = CATransform3DIdentity
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                guard let window = self?.currentOverlayWindow else { return }
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.5
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    window.animator().alphaValue = 0.0
                    window.contentView?.animator().layer?.transform = CATransform3DMakeScale(1.1, 1.1, 1.0)
                }) {
                    window.close()
                    self?.currentOverlayWindow = nil
                }
            }
        }
    }
    
    @objc func playBeep() {
        triggerAlert()
    }
    
    func triggerAlert() {
        if beepEnabled {
            playSoundEffect()
        }
        // Always show the visual cues even if beep is disabled
        blinkMenuBarIcon()
        showCursorTime()
    }
    
    func scheduleNextBeep() {
        let now = Date()
        let calendar = Calendar.current
        
        // Find next hour start top (minute 0, second 0)
        let nextMinute = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime, direction: .forward)
        
        guard let next = nextMinute else { return }
        
        let timeInterval = next.timeIntervalSince(now)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            self?.triggerAlert()
            self?.scheduleNextBeep()
        }
    }
}

class CursorTimeWindow: NSWindow {
    init(timeString: String) {
        let mouseLoc = NSEvent.mouseLocation
        let width: CGFloat = 140
        let height: CGFloat = 50
        
        let winRect = NSRect(x: mouseLoc.x - width/2, y: mouseLoc.y + 20, width: width, height: height)
        super.init(contentRect: winRect, styleMask: .borderless, backing: .buffered, defer: false)
        
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.level = .screenSaver
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isReleasedWhenClosed = false
        
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        containerView.layer?.cornerRadius = height/2
        
        // Use styled text
        let label = NSTextField(labelWithString: timeString)
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.frame = NSRect(x: 0, y: (height - 30)/2, width: width, height: 30)
        
        containerView.addSubview(label)
        self.contentView = containerView
    }
}
