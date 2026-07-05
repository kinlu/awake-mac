import Foundation
import CoreGraphics

final class VirtualDisplayManager: ObservableObject {
    @Published private(set) var isEnabled = false

    private enum DisplayMode {
        static let pixelsWide = 3840
        static let pixelsHigh = 2160
        static let refreshRate = 60.0
    }

    private var virtualDisplay: NSObject?

    func enable() {
        guard !isEnabled else { return }

        guard let descriptorClass = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type,
              let displayClass = NSClassFromString("CGVirtualDisplay") as? NSObject.Type,
              let modeClass = NSClassFromString("CGVirtualDisplayMode") as? NSObject.Type,
              let settingsClass = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type else {
            return
        }

        // Create descriptor
        let descriptor = descriptorClass.init()
        descriptor.perform(Selector(("setMaxPixelsWide:")), with: NSNumber(value: DisplayMode.pixelsWide))
        descriptor.perform(Selector(("setMaxPixelsHigh:")), with: NSNumber(value: DisplayMode.pixelsHigh))
        descriptor.perform(Selector(("setSizeInMillimeters:")), with: NSValue(size: CGSize(width: 530, height: 300)))
        descriptor.perform(Selector(("setName:")), with: "Awake Virtual Display" as NSString)
        descriptor.perform(Selector(("setProductID:")), with: NSNumber(value: 0xAA01))
        descriptor.perform(Selector(("setVendorID:")), with: NSNumber(value: 0xBB01))
        descriptor.perform(Selector(("setSerialNum:")), with: NSNumber(value: 0x01))

        let queue = DispatchQueue(label: "com.local.awake.virtualdisplay")
        descriptor.perform(Selector(("setDispatchQueue:")), with: queue)

        // Create display with descriptor using perform
        let initSel = Selector(("initWithDescriptor:"))
        guard displayClass.instancesRespond(to: initSel) else { return }

        // Use class method perform to create instance
        let displayInstance = displayClass.init()
        guard let initialized = displayInstance.perform(initSel, with: descriptor)?.takeUnretainedValue() as? NSObject else {
            return
        }

        // Create a mode using IMP directly for multi-arg selector.
        let modeInitSel = Selector(("initWithWidth:height:refreshRate:"))
        let modeInstance = modeClass.init()
        typealias ModeInitIMP = @convention(c) (AnyObject, Selector, Int, Int, Double) -> AnyObject?
        let imp = modeInstance.method(for: modeInitSel)
        let modeInit = unsafeBitCast(imp, to: ModeInitIMP.self)
        guard let initializedMode = modeInit(
            modeInstance,
            modeInitSel,
            DisplayMode.pixelsWide,
            DisplayMode.pixelsHigh,
            DisplayMode.refreshRate
        ) as? NSObject else {
            return
        }

        // Create settings with the mode
        let settings = settingsClass.init()
        settings.perform(Selector(("setModes:")), with: [initializedMode])
        settings.perform(Selector(("setHiDPI:")), with: NSNumber(value: false))

        // Apply settings to display
        initialized.perform(Selector(("applySettings:")), with: settings)

        // Retain the display to keep it alive
        self.virtualDisplay = initialized
        isEnabled = true
    }

    func disable() {
        guard isEnabled else { return }
        virtualDisplay = nil
        isEnabled = false
    }

    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}
