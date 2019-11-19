//
//  AsynchronousOperation.swift
//  LMGeocoderSwift
//
//  Created by LMinh on 11/19/19.
//

import UIKit

/// Concurrent operation state
@objc private enum OperationState: Int {
    case ready
    case executing
    case finished
}

/// An abstract class that makes building simple asynchronous operations easy.
/// Subclasses must implement `execute()` to perform any work and call
/// `finish()` when they are done. All `NSOperation` work will be handled
/// automatically.
class AsynchronousOperation: Operation {
    
    // MARK: STATE
    
    private let stateQueue = DispatchQueue(
        label: "com.lmgeocoder.operation.state",
        attributes: .concurrent)

    private var rawState = OperationState.ready

    @objc private dynamic var state: OperationState {
        get {
            return stateQueue.sync(execute: { rawState })
        }
        set {
            willChangeValue(forKey: "state")
            stateQueue.sync(flags: .barrier, execute: { rawState = newValue })
            didChangeValue(forKey: "state")
        }
    }

    public final override var isReady: Bool {
        return state == .ready && super.isReady
    }

    public final override var isExecuting: Bool {
        return state == .executing
    }

    public final override var isFinished: Bool {
        return state == .finished
    }

    public final override var isAsynchronous: Bool {
        return true
    }
    
    // MARK: - NSObject
    
    @objc private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return ["state"]
    }

    @objc private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return ["state"]
    }

    @objc private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return ["state"]
    }
    
    // MARK: CONTROL
    
    func finish() {
        state = .finished
    }
    
    override func cancel() {
        super.cancel()
        finish()
    }
    
    override func start() {
        super.start()
        
        if isCancelled {
            finish()
            return
        }
        
        state = .executing
        execute()
    }
    
    
    public func execute() {
        
    }
}
