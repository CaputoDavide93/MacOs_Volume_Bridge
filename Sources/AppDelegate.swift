import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var haServer: HomeAssistantServer!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "hifispeaker.2.fill", accessibilityDescription: "Volume")
            button.image?.isTemplate = true
        }
        
        // Start Home Assistant API server
        haServer = HomeAssistantServer()
        haServer.start()
        
        // Create menu
        setupMenu()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        haServer?.stop()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Change Port
        let portItem = NSMenuItem(title: "Change Port...", action: #selector(changePort), keyEquivalent: "")
        portItem.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Change Port")
        menu.addItem(portItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Launch at startup
        let startupItem = NSMenuItem(title: "Launch at Startup", action: #selector(toggleStartupAtLogin), keyEquivalent: "")
        startupItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Launch at Startup")
        let status = SMAppService.mainApp.status
        startupItem.state = (status == .enabled) ? .on : .off
        menu.addItem(startupItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: "Quit")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func changePort() {
        let alert = NSAlert()
        alert.messageText = "Change API Port"
        alert.informativeText = "Enter new port number (1-65535). Restart required after change."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        let currentPort = UserDefaults.standard.integer(forKey: "api_port") > 0 ? UserDefaults.standard.integer(forKey: "api_port") : 8888
        input.stringValue = "\(currentPort)"
        alert.accessoryView = input
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            if let port = Int(input.stringValue), port > 0 && port <= 65535 {
                UserDefaults.standard.set(port, forKey: "api_port")
                
                let successAlert = NSAlert()
                successAlert.messageText = "Port Updated"
                successAlert.informativeText = "Please restart the app for the port change to take effect."
                successAlert.alertStyle = .informational
                successAlert.addButton(withTitle: "OK")
                successAlert.runModal()
                
                // Update menu
                setupMenu()
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Invalid Port"
                errorAlert.informativeText = "Port must be a number between 1 and 65535."
                errorAlert.alertStyle = .warning
                errorAlert.addButton(withTitle: "OK")
                errorAlert.runModal()
            }
        }
    }
    
    @objc private func toggleStartupAtLogin(_ sender: NSMenuItem) {
        let shouldEnable = sender.state == .off
        
        do {
            if shouldEnable {
                let status = SMAppService.mainApp.status
                if status == .notRegistered || status == .notFound {
                    try SMAppService.mainApp.register()
                    print("✅ Registered for launch at startup")
                }
            } else {
                try SMAppService.mainApp.unregister()
                print("❌ Unregistered from launch at startup")
            }
            
            // Update menu to reflect new state
            setupMenu()
        } catch let error as NSError {
            let alert = NSAlert()
            alert.messageText = "Failed to Update Launch at Startup"
            
            // More detailed error message
            if error.domain == "SMAppServiceErrorDomain" {
                if error.code == 1 {
                    alert.informativeText = "Permission denied. This app needs to be in your Applications folder to enable launch at startup."
                } else {
                    alert.informativeText = "Error code \(error.code): \(error.localizedDescription)\n\nThe app may need to be signed or moved to /Applications folder."
                }
            } else {
                alert.informativeText = "Error: \(error.localizedDescription)"
            }
            
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            print("❌ Error toggling launch at startup: \(error)")
        }
    }
}
