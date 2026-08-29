//
// --------------------------------------------------------------------------
// ButtonOptionsViewController.swift
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2022
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

import Cocoa
import ReactiveCocoa
import ReactiveSwift

class ButtonOptionsViewController: NSViewController {

    /// Vars
    
    static var instance: ButtonOptionsViewController? = nil
    
    var lockPointer = ConfigValue<Bool>(configPath: "General.lockPointerDuringDrag")
    var dragActivationThreshold = ConfigValue<Int>(configPath: "General.dragActivationThreshold")
    
    /// IB outlets & actions
    
    @IBOutlet weak var doneButton: NSButton!
    @IBOutlet weak var lockPointerButton: NSButton!
    @IBOutlet weak var dragActivationThresholdSlider: NSSlider!
    @IBOutlet weak var dragActivationThresholdLabel: NSTextField!
        
    @IBAction func done(_ sender: Any) {
        ButtonOptionsViewController.remove()
    }
    
    /// Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lockPointerButton.reactive.boolValue <~ lockPointer
        lockPointer <~ lockPointerButton.reactive.boolValues

        dragActivationThresholdSlider.minValue = Double(DragActivationThreshold.minimumValue)
        dragActivationThresholdSlider.maxValue = Double(DragActivationThreshold.maximumValue)
        dragActivationThresholdSlider.reactive.doubleValue <~ dragActivationThreshold.producer.map(Double.init)
        dragActivationThreshold <~ dragActivationThresholdSlider.reactive.doubleValues
            .map { Int($0.rounded()) }
            .skipRepeats()
        dragActivationThreshold.producer.startWithValues { [weak self] value in
            self?.dragActivationThresholdLabel.stringValue = "\(value) px"
        }
        
        /// Adjust views for Tahoe
        if #available(macOS 26.0, *) {
            self.view.prefersCompactControlSizeMetrics = true;
        }
    }
    
    /// Interface
    
    @objc static func add() {
        
        /// Create new instance every time. Otherwise the done button won't be blue after the first open
        instance?.nibBundle?.unload()
        instance = nil
        instance = ButtonOptionsViewController(nibName: "ButtonOptionsViewController", bundle: Bundle.main)
        
        /// Open sheet
        guard let tabViewController = MainAppState.shared.tabViewController else { assert(false); return }
        tabViewController.presentAsSheet(instance!)
    }
    
    @objc static func remove() {
        
        /// Close sheet
        guard let tabViewController = MainAppState.shared.tabViewController else { assert(false); return }
        tabViewController.dismiss(instance!)
    }
    
    
    
}
