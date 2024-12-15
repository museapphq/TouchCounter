// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

@MainActor
public final class TouchCounter: Sendable {
    public static let shared = TouchCounter()
    
    /// The number of active direct touches on the screen
    @Published public private(set) var numDirectActiveTouches: Int = 0
    private var isSwizzled = false
    
    private init() {}
    
    func handleEvent(_ event: UIEvent) {
        guard event.type == .touches,
              let allTouches = event.allTouches else {
            return
        }
        
        let count = allTouches
            .filter { $0.type == .direct && $0.phase != .ended && $0.phase != .cancelled }
            .count
        
        self.updateTouchCount(count)
    }
    
    private func updateTouchCount(_ count: Int) {
        self.numDirectActiveTouches = count
    }
    
    func getSwizzled() -> Bool {
        isSwizzled
    }
    
    func setSwizzled() {
        isSwizzled = true
    }
}

extension UIWindow {
    public static func swizzle() {
        guard TouchCounter.shared.getSwizzled() == false else { return }
        
        let sendEvent = class_getInstanceMethod(
            UIWindow.self,
            #selector(UIWindow.sendEvent(_:))
        )
        let swizzledSendEvent = class_getInstanceMethod(
            UIWindow.self,
            #selector(UIWindow.swizzledSendEvent(_:))
        )
        method_exchangeImplementations(sendEvent!, swizzledSendEvent!)
        
        TouchCounter.shared.setSwizzled()
    }

    @objc public func swizzledSendEvent(_ event: UIEvent) {
        TouchCounter.shared.handleEvent(event)
        swizzledSendEvent(event)
    }
}
