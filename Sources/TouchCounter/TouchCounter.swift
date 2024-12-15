// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

fileprivate var isSwizzled = false

public final class TouchCounter {
    public static let shared = TouchCounter()
    
    /// The number of active direct touches on the screen
    public private(set) var numDirectActiveTouches: Int = 0
    
    private override init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationDidBecomeActive() {
        UIApplication.shared.keyWindow?.swizzle()
    }
    
    func handleEvent(_ event: UIEvent) {
        guard event.type == .touches,
              let allTouches = event.allTouches else {
            return
        }
        
        numDirectActiveTouches = allTouches
            .filter { $0.type == .direct && $0.phase != .ended && $0.phase != .cancelled }
            .count
    }
}

extension UIWindow {
    public func swizzle() {
        guard isSwizzled == false else { return }
        
        let sendEvent = class_getInstanceMethod(
            object_getClass(self),
            #selector(UIApplication.sendEvent(_:))
        )
        let swizzledSendEvent = class_getInstanceMethod(
            object_getClass(self),
            #selector(UIWindow.swizzledSendEvent(_:))
        )
        method_exchangeImplementations(sendEvent!, swizzledSendEvent!)
        
        isSwizzled = true
    }
    
    @objc public func swizzledSendEvent(_ event: UIEvent) {
        TouchCounter.shared.handleEvent(event)
        swizzledSendEvent(event)
    }
}
