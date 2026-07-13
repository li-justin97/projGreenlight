import AppKit

@main
enum GreenlightMain {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = GreenlightAppController()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
        _ = delegate
    }
}
