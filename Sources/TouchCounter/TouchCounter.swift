// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

public actor TouchCounter: Sendable {
    public static let shared = TouchCounter()
    
    /// The number of active direct touches on the screen
    @Published public private(set) var numDirectActiveTouches: Int = 0
    private var isSwizzled = false
    
    private init() {
        Task { @MainActor in
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(Self.applicationDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @MainActor
    @objc private static func applicationDidBecomeActive() {
        UIApplication.shared.keyWindow?.swizzle()
    }
    
    @MainActor
    func handleEvent(_ event: UIEvent) {
        guard event.type == .touches,
              let allTouches = event.allTouches else {
            return
        }
        
        let count = allTouches
            .filter { $0.type == .direct && $0.phase != .ended && $0.phase != .cancelled }
            .count
        
        Task {
            await self.updateTouchCount(count)
        }
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
    public func swizzle() {
        Task {
            guard await TouchCounter.shared.getSwizzled() == false else { return }
            
            let sendEvent = class_getInstanceMethod(
                object_getClass(self),
                #selector(UIApplication.sendEvent(_:))
            )
            let swizzledSendEvent = class_getInstanceMethod(
                object_getClass(self),
                #selector(UIWindow.swizzledSendEvent(_:))
            )
            method_exchangeImplementations(sendEvent!, swizzledSendEvent!)
            
            await TouchCounter.shared.setSwizzled()
        }
    }
    
    @objc public func swizzledSendEvent(_ event: UIEvent) {
        TouchCounter.shared.handleEvent(event)
        swizzledSendEvent(event)
    }
}
