//
//  ScrollTabController.swift
//  tabTestStoryboards
//
//  Created by Noah Nübling on 16.06.22.
//

import Cocoa
import ReactiveSwift
import ReactiveCocoa
import AppKit
import UniformTypeIdentifiers

private final class TrackpadAppsTableDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var bundleIDs: [String] = []

    func numberOfRows(in tableView: NSTableView) -> Int {
        bundleIDs.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let bundleID = bundleIDs[row]
        let cellID = NSUserInterfaceItemIdentifier("TrackpadAppCell")
        let cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTableCellView ?? {
            let newCell = NSTableCellView()
            newCell.identifier = cellID

            let icon = NSImageView()
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.imageScaling = .scaleProportionallyDown
            icon.identifier = NSUserInterfaceItemIdentifier("AppIcon")

            let text = NSTextField(labelWithString: "")
            text.translatesAutoresizingMaskIntoConstraints = false
            text.lineBreakMode = .byTruncatingTail
            text.identifier = NSUserInterfaceItemIdentifier("AppName")

            newCell.addSubview(icon)
            newCell.addSubview(text)
            newCell.imageView = icon
            newCell.textField = text
            NSLayoutConstraint.activate([
                icon.leadingAnchor.constraint(equalTo: newCell.leadingAnchor, constant: 6),
                icon.centerYAnchor.constraint(equalTo: newCell.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 20),
                icon.heightAnchor.constraint(equalToConstant: 20),
                text.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
                text.trailingAnchor.constraint(equalTo: newCell.trailingAnchor, constant: -6),
                text.centerYAnchor.constraint(equalTo: newCell.centerYAnchor),
            ])
            return newCell
        }()

        let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        cell.imageView?.image = appURL.map { NSWorkspace.shared.icon(forFile: $0.path) }
        cell.textField?.stringValue = appURL?.deletingPathExtension().lastPathComponent ?? bundleID
        return cell
    }
}

private final class TrackpadPolicyRulesTableDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var rules: [ApplicationPolicyRule] = []
    var selectionDidChange: ((Int) -> Void)?

    static func title(for kind: ApplicationPolicyMatchKind) -> String {
        switch kind {
        case .bundleIdentifier: return "Bundle Identifier"
        case .executablePath: return "Executable Path"
        case .wrapperBundleIdentifier: return "Wrapper Bundle ID"
        case .wrapperPath: return "Wrapper Path"
        case .processName: return "Process Name"
        }
    }

    static func title(for effect: ApplicationPolicyEffect) -> String {
        effect == .allow ? "Allow" : "Deny"
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        rules.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let rule = rules[row]
        let cellID = NSUserInterfaceItemIdentifier("TrackpadPolicyRuleCell")
        let cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTableCellView ?? {
            let newCell = NSTableCellView()
            newCell.identifier = cellID
            let text = NSTextField(labelWithString: "")
            text.translatesAutoresizingMaskIntoConstraints = false
            text.lineBreakMode = .byTruncatingMiddle
            newCell.addSubview(text)
            newCell.textField = text
            NSLayoutConstraint.activate([
                text.leadingAnchor.constraint(equalTo: newCell.leadingAnchor, constant: 8),
                text.trailingAnchor.constraint(equalTo: newCell.trailingAnchor, constant: -8),
                text.centerYAnchor.constraint(equalTo: newCell.centerYAnchor),
            ])
            return newCell
        }()

        cell.textField?.stringValue = "\(Self.title(for: rule.matchKind)) — \(Self.title(for: rule.effect)): \(rule.value)"
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        selectionDidChange?(tableView.selectedRow)
    }
}

@available(macOS 11.0, *)
class ScrollTabController: NSViewController {
    
    /// Config
    
    var verticalSmooth = ConfigValue<String>(configPath: "Scroll.verticalSmooth")
    var horizontalSmooth = ConfigValue<String>(configPath: "Scroll.horizontalSmooth")
    var trackpad = ConfigValue<Bool>(configPath: "Scroll.trackpadSimulation")
    var reverseDirectionVertical = ConfigValue<Bool>(configPath: "Scroll.reverseDirectionVertical")
    var reverseDirectionHorizontal = ConfigValue<Bool>(configPath: "Scroll.reverseDirectionHorizontal")
    var verticalSpeed = ConfigValue<String>(configPath: "Scroll.verticalSpeed")
    var horizontalSpeed = ConfigValue<String>(configPath: "Scroll.horizontalSpeed")
    var trackpadScope = ConfigValue<String>(configPath: "Scroll.trackpadSimulationScope")
    var precise = ConfigValue<Bool>(configPath: "Scroll.precise")
    var horizontalMod = ConfigValue<UInt>(configPath: "Scroll.modifiers.horizontal")
    var zoomMod = ConfigValue<UInt>(configPath: "Scroll.modifiers.zoom")
    var swiftMod = ConfigValue<UInt>(configPath: "Scroll.modifiers.swift")
    var preciseMod = ConfigValue<UInt>(configPath: "Scroll.modifiers.precise")
    
    /// Also see `ReactiveFlags` is this doesn't work
    
    /// Outlets
    
    @IBOutlet weak var masterStack: CollapsingStackView!
    @IBOutlet weak var generalTitle: NSTextField!
    @IBOutlet weak var generalDivider: NSView!
    @IBOutlet weak var smoothnessSection: NSStackView!
    

    
    
    
    
    @IBOutlet weak var smoothPicker: NSPopUpButton!
    
    @IBOutlet weak var trackpadSection: NSStackView!
    @IBOutlet weak var trackpadToggle: NSButton!
    @IBOutlet weak var trackpadHint: NSTextField!
    @IBOutlet weak var trackpadScopeStack: NSStackView!
    
    @IBOutlet weak var reverseDirectionVerticalToggle: NSButton!
    @IBOutlet weak var reverseDirectionHorizontalToggle: NSButton!
    
    @IBOutlet weak var speedPicker: NSPopUpButton!
    @IBOutlet weak var horizontalSmoothPicker: NSPopUpButton!
    @IBOutlet weak var horizontalSpeedPicker: NSPopUpButton!
    @IBOutlet weak var trackpadScopePicker: NSPopUpButton!
    @IBOutlet weak var trackpadAppsButton: NSButton!
    @IBOutlet weak var trackpadAppsSummary: NSTextField!
    @IBOutlet weak var trackpadAppsClearButton: NSButton!
    
    @IBOutlet weak var preciseSection: NSStackView!
    @IBOutlet weak var preciseToggle: NSButton!
    @IBOutlet weak var preciseHint: MarkdownTextField!
    
    @IBOutlet weak var horizontalModField: ModCaptureTextField!
    @IBOutlet weak var zoomModField: ModCaptureTextField!
    @IBOutlet weak var swiftModField: ModCaptureTextField!
    @IBOutlet weak var preciseModField: ModCaptureTextField!
    @IBOutlet weak var restoreDefaultModsButton: NSButton!

    private var trackpadScopeRow: NSView?
    private var trackpadScopeRowHeightConstraint: NSLayoutConstraint?
    private var trackpadAppsButtonTopConstraint: NSLayoutConstraint?
    private var trackpadAppsButtonHeightConstraint: NSLayoutConstraint?
    private var trackpadAppsButtonTransitionID = 0
    private var speedDivider: NSView?
    private var trackpadAppsEditorWindow: NSWindow?
    private var trackpadAppsTableView: NSTableView?
    private let trackpadAppsTableDataSource = TrackpadAppsTableDataSource()
    private var trackpadPolicyEditorWindow: NSWindow?
    private var trackpadPolicyTableView: NSTableView?
    private var trackpadPolicyEditButton: NSButton?
    private let trackpadPolicyRulesDataSource = TrackpadPolicyRulesTableDataSource()
    private var trackpadRuleEntryWindow: NSPanel?
    private var trackpadRuleEntryEditingSelectorKey: String?
    private var trackpadRuleEntryKindPopup: NSPopUpButton?
    private var trackpadRuleEntryEffectPopup: NSPopUpButton?
    private var trackpadRuleEntryValueField: NSTextField?
    private var trackpadRuleEntryChooseButton: NSButton?
    private var trackpadRuleEntryHint: NSTextField?
    private var trackpadRuleEntryError: NSTextField?

    private enum TrackpadScopeIdentifier {
        static let all = "all"
        static let include = "include"
        static let exclude = "exclude"
        static let advanced = "advanced"
    }

    private func removeWidthConstraints(from view: NSView) {
        view.removeConstraints(view.constraints.filter({ $0.firstAttribute == .width && $0.secondItem == nil }))
    }

    /// Rebuild the scope controls into a compact scope row. The included/excluded
    /// list lives in a dedicated sheet so it has room to be read and managed
    /// properly; Advanced mode uses the same row for its Edit Rules… action.
    /// The original controls are still loaded from the storyboard so their actions,
    /// accessibility identifiers, and existing localization metadata remain intact.
    private func configureTrackpadScopeUI() {
        guard trackpadScopeRow == nil else { return }
        guard let scopeStack = trackpadScopeStack,
              let scopeRow = scopeStack.arrangedSubviews.first as? NSStackView,
              let appsRow = scopeStack.arrangedSubviews.last as? NSStackView,
              let applyToLabel = scopeRow.arrangedSubviews.compactMap({ $0 as? NSTextField }).first else {
            return
        }

        scopeRow.removeArrangedSubview(applyToLabel)
        scopeRow.removeArrangedSubview(trackpadScopePicker)
        appsRow.removeArrangedSubview(trackpadAppsButton)
        appsRow.removeArrangedSubview(trackpadAppsSummary)
        appsRow.removeArrangedSubview(trackpadAppsClearButton)
        scopeStack.removeArrangedSubview(scopeRow)
        scopeStack.removeArrangedSubview(appsRow)

        applyToLabel.removeFromSuperview()
        trackpadScopePicker.removeFromSuperview()
        trackpadAppsButton.removeFromSuperview()
        trackpadAppsSummary.removeFromSuperview()
        trackpadAppsClearButton.removeFromSuperview()
        scopeRow.removeFromSuperview()
        appsRow.removeFromSuperview()

        applyToLabel.removeConstraints(applyToLabel.constraints.filter({ $0.firstAttribute == .width && $0.secondItem == nil }))
        applyToLabel.widthAnchor.constraint(equalToConstant: 70).isActive = true

        removeWidthConstraints(from: trackpadScopePicker)
        trackpadScopePicker.widthAnchor.constraint(equalToConstant: 180).isActive = true

        removeWidthConstraints(from: trackpadAppsButton)
        trackpadAppsButton.widthAnchor.constraint(equalToConstant: 132).isActive = true
        trackpadAppsButton.title = "Edit Apps…"
        trackpadAppsButton.target = self
        trackpadAppsButton.action = #selector(editTrackpadApps(_:))

        let scopeSelectionRow = NSStackView(views: [applyToLabel, trackpadScopePicker])
        scopeSelectionRow.translatesAutoresizingMaskIntoConstraints = false
        scopeSelectionRow.orientation = .horizontal
        scopeSelectionRow.alignment = .centerY
        scopeSelectionRow.spacing = 10
        scopeSelectionRow.distribution = .fill

        let compactScopeRow = NSView()
        compactScopeRow.translatesAutoresizingMaskIntoConstraints = false
        compactScopeRow.addSubview(scopeSelectionRow)
        compactScopeRow.addSubview(trackpadAppsButton)
        trackpadScopeRow = compactScopeRow

        let scopeIndex = trackpadSection.arrangedSubviews.firstIndex(of: scopeStack) ?? trackpadSection.arrangedSubviews.count
        trackpadSection.removeArrangedSubview(scopeStack)
        scopeStack.removeFromSuperview()
        trackpadSection.insertArrangedSubview(compactScopeRow, at: scopeIndex)
        compactScopeRow.widthAnchor.constraint(equalTo: trackpadSection.widthAnchor).isActive = true
        let isButtonVisible = (trackpadScope.get() ?? TrackpadScopeIdentifier.all) != TrackpadScopeIdentifier.all
        let initialHeight: CGFloat = isButtonVisible ? 54 : 24
        let scopeRowHeightConstraint = compactScopeRow.heightAnchor.constraint(equalToConstant: initialHeight)
        scopeRowHeightConstraint.isActive = true
        trackpadScopeRowHeightConstraint = scopeRowHeightConstraint
        let buttonTopConstraint = trackpadAppsButton.topAnchor.constraint(equalTo: scopeSelectionRow.bottomAnchor,
                                                                          constant: isButtonVisible ? 6 : 0)
        let buttonHeightConstraint = trackpadAppsButton.heightAnchor.constraint(equalToConstant: isButtonVisible ? 24 : 0)
        NSLayoutConstraint.activate([
            scopeSelectionRow.topAnchor.constraint(equalTo: compactScopeRow.topAnchor),
            scopeSelectionRow.leadingAnchor.constraint(equalTo: compactScopeRow.leadingAnchor),
            scopeSelectionRow.trailingAnchor.constraint(equalTo: compactScopeRow.trailingAnchor),
            buttonTopConstraint,
            trackpadAppsButton.trailingAnchor.constraint(equalTo: compactScopeRow.trailingAnchor),
            buttonHeightConstraint,
            compactScopeRow.bottomAnchor.constraint(equalTo: trackpadAppsButton.bottomAnchor),
        ])
        trackpadAppsButtonTopConstraint = buttonTopConstraint
        trackpadAppsButtonHeightConstraint = buttonHeightConstraint
        trackpadAppsButton.setContentHuggingPriority(.required, for: .horizontal)
        trackpadAppsButton.alphaValue = isButtonVisible ? 1 : 0
        trackpadAppsButton.isHidden = !isButtonVisible
    }

    private func configuredTrackpadApps() -> [String] {
        return (config("Scroll.trackpadSimulationApps") as? NSArray)?.compactMap({ $0 as? String }) ?? []
    }

    private func currentApplicationPolicySnapshot() -> ApplicationPolicySnapshot? {
        if let rawPolicy = config("Scroll.applicationPolicy") {
            guard let dictionary = rawPolicy as? NSDictionary else { return nil }
            return ApplicationPolicySnapshot.snapshotFromDictionary(dictionary)
        }

        let scope = trackpadScope.get() ?? TrackpadScopeIdentifier.all
        if scope == TrackpadScopeIdentifier.advanced {
            return ApplicationPolicySnapshot(defaultEffect: .allow, rules: [])
        }
        return ApplicationPolicySnapshot.snapshotFromLegacyScope(scope, applications: NSArray(array: configuredTrackpadApps()))
    }

    private func currentAdvancedPolicyRules() -> [ApplicationPolicyRule] {
        currentApplicationPolicySnapshot()?.rules.filter({ $0.matchKind != .bundleIdentifier }) ?? []
    }

    @discardableResult
    private func updateApplicationPolicyInConfig() -> Bool {
        let scope = trackpadScope.get() ?? TrackpadScopeIdentifier.all
        if scope == TrackpadScopeIdentifier.advanced {
            return activateAdvancedApplicationPolicyInConfig()
        }

        let applications = NSArray(array: configuredTrackpadApps())
        guard let snapshot = ApplicationPolicySnapshot.snapshotFromLegacyScope(scope, applications: applications) else {
            return false
        }
        var snapshotToStore = snapshot
        if let rawCurrent = config("Scroll.applicationPolicy") {
            guard let current = rawCurrent as? NSDictionary,
                  let currentSnapshot = ApplicationPolicySnapshot.snapshotFromDictionary(current) else {
                return false
            }
            /// Preserve advanced selectors while the legacy mode is active so
            /// switching back to Advanced does not discard the user's rules.
            let advancedRules = currentSnapshot.rules.filter({ $0.matchKind != .bundleIdentifier })
            if !advancedRules.isEmpty {
                guard let merged = ApplicationPolicySnapshot(defaultEffect: snapshot.defaultEffect,
                                                             rules: snapshot.rules + advancedRules) else {
                    return false
                }
                snapshotToStore = merged
            }
        }
        let encoded = snapshotToStore.dictionaryRepresentation
        if let current = config("Scroll.applicationPolicy") as? NSDictionary, current.isEqual(encoded) { return false }
        setConfig("Scroll.applicationPolicy", encoded)
        return true
    }

    @discardableResult
    private func activateAdvancedApplicationPolicyInConfig() -> Bool {
        let snapshot: ApplicationPolicySnapshot?
        if let rawCurrent = config("Scroll.applicationPolicy") {
            guard let current = rawCurrent as? NSDictionary,
                  let currentSnapshot = ApplicationPolicySnapshot.snapshotFromDictionary(current) else {
                return false
            }
            snapshot = currentSnapshot.advancedScopeSnapshot()
        } else {
            snapshot = ApplicationPolicySnapshot(defaultEffect: .allow, rules: [])
        }
        guard let snapshot else {
            return false
        }

        let encoded = snapshot.dictionaryRepresentation
        if let current = config("Scroll.applicationPolicy") as? NSDictionary, current.isEqual(encoded) {
            return false
        }
        setConfig("Scroll.applicationPolicy", encoded)
        return true
    }

    private func updateTrackpadAppsUI() {
        let scope = trackpadScope.get() ?? TrackpadScopeIdentifier.all
        let apps = configuredTrackpadApps()
        let isAdvanced = scope == TrackpadScopeIdentifier.advanced
        let hasEditorButton = scope != TrackpadScopeIdentifier.all

        trackpadAppsButton.title = isAdvanced ? "Edit Rules…" : "Edit Apps…"
        trackpadAppsButton.target = self
        trackpadAppsButton.action = isAdvanced
            ? #selector(editAdvancedTrackpadPolicy(_:))
            : #selector(editTrackpadApps(_:))
        trackpadAppsButton.isEnabled = hasEditorButton
        updateTrackpadAppsButtonVisibility(hasEditorButton)
        trackpadAppsTableDataSource.bundleIDs = apps
        trackpadAppsTableView?.reloadData()
    }

    private func updateTrackpadAppsButtonVisibility(_ isVisible: Bool) {
        guard let rowHeightConstraint = trackpadScopeRowHeightConstraint,
              let buttonTopConstraint = trackpadAppsButtonTopConstraint,
              let buttonHeightConstraint = trackpadAppsButtonHeightConstraint else { return }

        trackpadAppsButtonTransitionID += 1
        let transitionID = trackpadAppsButtonTransitionID
        let targetRowHeight: CGFloat = isVisible ? 54 : 24
        let targetButtonTop: CGFloat = isVisible ? 6 : 0
        let targetButtonHeight: CGFloat = isVisible ? 24 : 0
        let needsUpdate = rowHeightConstraint.constant != targetRowHeight
            || buttonTopConstraint.constant != targetButtonTop
            || buttonHeightConstraint.constant != targetButtonHeight
        guard needsUpdate else {
            trackpadAppsButton.alphaValue = isVisible ? 1 : 0
            trackpadAppsButton.isHidden = !isVisible
            return
        }

        let animate = trackpadScopeRow?.window != nil
        trackpadAppsButton.isHidden = false
        if !isVisible {
            trackpadAppsButton.alphaValue = 1
        } else {
            trackpadAppsButton.alphaValue = 0
        }

        if animate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                rowHeightConstraint.animator().constant = targetRowHeight
                buttonTopConstraint.animator().constant = targetButtonTop
                buttonHeightConstraint.animator().constant = targetButtonHeight
                trackpadAppsButton.animator().alphaValue = isVisible ? 1 : 0
                view.layoutSubtreeIfNeeded()
            } completionHandler: { [weak self] in
                guard let self, self.trackpadAppsButtonTransitionID == transitionID else { return }
                self.trackpadAppsButton.isHidden = !isVisible
                self.trackpadAppsButton.alphaValue = isVisible ? 1 : 0
            }
        } else {
            rowHeightConstraint.constant = targetRowHeight
            buttonTopConstraint.constant = targetButtonTop
            buttonHeightConstraint.constant = targetButtonHeight
            trackpadAppsButton.alphaValue = isVisible ? 1 : 0
            trackpadAppsButton.isHidden = !isVisible
            view.layoutSubtreeIfNeeded()
        }
    }

    private func saveTrackpadApps(_ bundleIDs: [String]) {
        setConfig("Scroll.trackpadSimulationApps", NSArray(array: bundleIDs))
        _ = updateApplicationPolicyInConfig()
        commitConfig()
        updateTrackpadAppsUI()
    }

    @discardableResult
    private func saveAdvancedPolicyRules(_ rules: [ApplicationPolicyRule]) -> Bool {
        guard trackpadScope.get() == TrackpadScopeIdentifier.advanced else { return false }
        let advancedRules = rules.filter({ $0.matchKind != .bundleIdentifier })
        guard let snapshot = ApplicationPolicySnapshot(defaultEffect: .allow,
                                                       rules: advancedRules) else {
            return false
        }
        let encoded = snapshot.dictionaryRepresentation
        if let current = config("Scroll.applicationPolicy") as? NSDictionary, current.isEqual(encoded) {
            return true
        }
        setConfig("Scroll.applicationPolicy", encoded)
        commitConfig()
        return true
    }

    @IBAction func chooseTrackpadApps(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.applicationBundle]
        } else {
            panel.allowedFileTypes = ["app"]
        }
        panel.allowsOtherFileTypes = false
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        let applySelection: (NSApplication.ModalResponse) -> Void = { [weak self, weak panel] response in
            guard response == .OK, let self, let panel else { return }

            var seen = Set<String>()
            let bundleIDs = panel.urls.compactMap({ Bundle(url: $0)?.bundleIdentifier }).filter({ seen.insert($0).inserted })
            self.saveTrackpadApps(bundleIDs.sorted())
        }

        if let window = trackpadAppsEditorWindow ?? view.window {
            panel.beginSheetModal(for: window, completionHandler: applySelection)
        } else {
            applySelection(panel.runModal())
        }
    }

    @objc private func editTrackpadApps(_ sender: NSButton) {
        let scope = trackpadScope.get() ?? "all"
        guard scope != "all", let parentWindow = view.window else { return }

        let title = scope == "include" ? "Choose apps for Trackpad Simulation" : "Exclude apps from Trackpad Simulation"
        let instruction = scope == "include" ? "Apply Trackpad Simulation only to these apps:" : "Do not apply Trackpad Simulation to these apps:"

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 330))
        let instructionLabel = NSTextField(wrappingLabelWithString: instruction)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.font = .systemFont(ofSize: 15)

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.rowHeight = 30
        tableView.usesAlternatingRowBackgroundColors = true
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("App"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.dataSource = trackpadAppsTableDataSource
        tableView.delegate = trackpadAppsTableDataSource
        scrollView.documentView = tableView

        let addButton = NSButton(title: "Add Apps…", target: self, action: #selector(chooseTrackpadApps(_:)))
        addButton.bezelStyle = .rounded
        addButton.translatesAutoresizingMaskIntoConstraints = false
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSelectedTrackpadApps(_:)))
        removeButton.bezelStyle = .rounded
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeTrackpadAppsEditor(_:)))
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(instructionLabel)
        contentView.addSubview(scrollView)
        contentView.addSubview(addButton)
        contentView.addSubview(removeButton)
        contentView.addSubview(doneButton)
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            removeButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 8),
            removeButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            doneButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
        ])

        let editor = NSPanel(contentRect: contentView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        editor.title = title
        editor.contentView = contentView
        editor.isReleasedWhenClosed = false
        editor.standardWindowButton(.zoomButton)?.isHidden = true
        editor.standardWindowButton(.miniaturizeButton)?.isHidden = true
        trackpadAppsEditorWindow = editor
        trackpadAppsTableView = tableView
        trackpadAppsTableDataSource.bundleIDs = configuredTrackpadApps()
        tableView.reloadData()
        parentWindow.beginSheet(editor) { [weak self] _ in
            self?.trackpadAppsEditorWindow = nil
            self?.trackpadAppsTableView = nil
        }
    }

    @objc private func removeSelectedTrackpadApps(_ sender: NSButton) {
        guard let tableView = trackpadAppsTableView else { return }
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }
        var apps = configuredTrackpadApps()
        for index in selectedRows.sorted(by: >) {
            apps.remove(at: index)
        }
        saveTrackpadApps(apps)
        tableView.deselectAll(nil)
    }

    @objc private func closeTrackpadAppsEditor(_ sender: NSButton) {
        guard let editor = trackpadAppsEditorWindow, let parent = editor.sheetParent else { return }
        parent.endSheet(editor)
    }

    @objc private func editAdvancedTrackpadPolicy(_ sender: NSButton) {
        guard let parentWindow = view.window else { return }

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 620, height: 390))
        let ruleCount = currentAdvancedPolicyRules().count
        let ruleSummary = ruleCount == 0 ? "No advanced rules are configured yet." : "\(ruleCount) advanced rule\(ruleCount == 1 ? "" : "s") configured."
        let instructionLabel = NSTextField(wrappingLabelWithString: ruleSummary)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.font = .systemFont(ofSize: 13)

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.rowHeight = 30
        tableView.usesAlternatingRowBackgroundColors = true
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Rule"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.dataSource = trackpadPolicyRulesDataSource
        tableView.delegate = trackpadPolicyRulesDataSource
        tableView.target = self
        tableView.doubleAction = #selector(editAdvancedTrackpadPolicyRuleFromTable(_:))
        scrollView.documentView = tableView

        let addButton = NSButton(title: "Add Rule…", target: self, action: #selector(addAdvancedTrackpadPolicyRule(_:)))
        addButton.bezelStyle = .rounded
        addButton.translatesAutoresizingMaskIntoConstraints = false
        let editButton = NSButton(title: "Edit Rule…", target: self, action: #selector(editSelectedAdvancedTrackpadPolicyRule(_:)))
        editButton.bezelStyle = .rounded
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.isEnabled = false
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeAdvancedTrackpadPolicyRule(_:)))
        removeButton.bezelStyle = .rounded
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeAdvancedTrackpadPolicyEditor(_:)))
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        let actionStack = NSStackView(views: [addButton, editButton, removeButton])
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        actionStack.orientation = .horizontal
        actionStack.alignment = .centerY
        actionStack.spacing = 8

        contentView.addSubview(instructionLabel)
        contentView.addSubview(scrollView)
        contentView.addSubview(actionStack)
        contentView.addSubview(doneButton)
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: actionStack.topAnchor, constant: -16),
            actionStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            doneButton.centerYAnchor.constraint(equalTo: actionStack.centerYAnchor),
        ])

        let editor = NSPanel(contentRect: contentView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        editor.title = "Advanced Application Rules"
        editor.contentView = contentView
        editor.isReleasedWhenClosed = false
        editor.standardWindowButton(.zoomButton)?.isHidden = true
        editor.standardWindowButton(.miniaturizeButton)?.isHidden = true
        trackpadPolicyEditorWindow = editor
        trackpadPolicyTableView = tableView
        trackpadPolicyEditButton = editButton
        trackpadPolicyRulesDataSource.selectionDidChange = { [weak self] _ in
            self?.updateAdvancedTrackpadPolicyEditButton()
        }
        trackpadPolicyRulesDataSource.rules = currentAdvancedPolicyRules()
        tableView.reloadData()
        updateAdvancedTrackpadPolicyEditButton()
        parentWindow.beginSheet(editor) { [weak self] _ in
            self?.trackpadPolicyRulesDataSource.selectionDidChange = nil
            self?.trackpadPolicyEditorWindow = nil
            self?.trackpadPolicyTableView = nil
            self?.trackpadPolicyEditButton = nil
        }
    }

    private func updateAdvancedTrackpadPolicyEditButton() {
        guard let tableView = trackpadPolicyTableView,
              let editButton = trackpadPolicyEditButton else { return }
        editButton.isEnabled = tableView.selectedRowIndexes.count == 1
    }

    private var advancedPolicyKinds: [ApplicationPolicyMatchKind] {
        [.executablePath, .wrapperBundleIdentifier, .wrapperPath, .processName]
    }

    @objc private func addAdvancedTrackpadPolicyRule(_ sender: NSButton) {
        presentAdvancedTrackpadPolicyRuleForm(editingRule: nil)
    }

    @objc private func editSelectedAdvancedTrackpadPolicyRule(_ sender: Any) {
        guard let tableView = trackpadPolicyTableView,
              tableView.selectedRowIndexes.count == 1,
              let selectedRule = trackpadPolicyRulesDataSource.rules[safe: tableView.selectedRow] else { return }
        presentAdvancedTrackpadPolicyRuleForm(editingRule: selectedRule)
    }

    @objc private func editAdvancedTrackpadPolicyRuleFromTable(_ tableView: NSTableView) {
        guard tableView.clickedRow >= 0,
              tableView.clickedRow == tableView.selectedRow else { return }
        editSelectedAdvancedTrackpadPolicyRule(tableView)
    }

    private func presentAdvancedTrackpadPolicyRuleForm(editingRule: ApplicationPolicyRule?) {
        guard let parentWindow = trackpadPolicyEditorWindow else { return }
        let existingRule = editingRule

        let isEditing = existingRule != nil
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 265))
        let titleLabel = NSTextField(labelWithString: isEditing ? "Edit an exact application rule" : "Add an exact application rule")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .boldSystemFont(ofSize: 15)

        let kindLabel = NSTextField(labelWithString: "Selector type")
        let effectLabel = NSTextField(labelWithString: "Effect")
        let valueLabel = NSTextField(labelWithString: "Value")
        [kindLabel, effectLabel, valueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.alignment = .right
        }

        let kindPopup = NSPopUpButton()
        kindPopup.translatesAutoresizingMaskIntoConstraints = false
        advancedPolicyKinds.forEach({ kindPopup.addItem(withTitle: TrackpadPolicyRulesTableDataSource.title(for: $0)) })

        let effectPopup = NSPopUpButton()
        effectPopup.translatesAutoresizingMaskIntoConstraints = false
        effectPopup.addItems(withTitles: ["Allow", "Deny"])

        let valueField = NSTextField()
        valueField.translatesAutoresizingMaskIntoConstraints = false
        valueField.placeholderString = "Choose an app or enter an exact value"

        let chooseButton = NSButton(title: "Choose App…", target: self, action: #selector(chooseAdvancedTrackpadPolicyApp(_:)))
        chooseButton.translatesAutoresizingMaskIntoConstraints = false
        chooseButton.bezelStyle = .rounded

        let hint = NSTextField(wrappingLabelWithString: "")
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.font = .systemFont(ofSize: 12)
        hint.textColor = .secondaryLabelColor

        let error = NSTextField(wrappingLabelWithString: "")
        error.translatesAutoresizingMaskIntoConstraints = false
        error.font = .systemFont(ofSize: 12)
        error.textColor = .systemRed
        error.isHidden = true

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelAdvancedTrackpadPolicyRule(_:)))
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"

        let confirmButton = NSButton(title: isEditing ? "Save Rule" : "Add Rule", target: self, action: #selector(confirmAdvancedTrackpadPolicyRule(_:)))
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.bezelStyle = .rounded
        confirmButton.keyEquivalent = "\r"

        let messageStack = NSStackView(views: [hint, error])
        messageStack.translatesAutoresizingMaskIntoConstraints = false
        messageStack.orientation = .vertical
        messageStack.alignment = .width
        messageStack.spacing = 5
        messageStack.detachesHiddenViews = true
        messageStack.setContentHuggingPriority(.required, for: .vertical)
        messageStack.setContentCompressionResistancePriority(.required, for: .vertical)

        let actionStack = NSStackView(views: [cancelButton, confirmButton])
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        actionStack.orientation = .horizontal
        actionStack.alignment = .centerY
        actionStack.spacing = 8
        actionStack.distribution = .fill

        let valueRow = NSStackView(views: [valueField, chooseButton])
        valueRow.translatesAutoresizingMaskIntoConstraints = false
        valueRow.orientation = .horizontal
        valueRow.alignment = .centerY
        valueRow.spacing = 8
        valueRow.distribution = .fill
        valueRow.detachesHiddenViews = true

        [titleLabel, kindLabel, kindPopup, effectLabel, effectPopup, valueLabel, valueRow,
         messageStack, actionStack].forEach({ contentView.addSubview($0) })
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),

            kindLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            kindLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            kindLabel.widthAnchor.constraint(equalToConstant: 105),
            kindPopup.leadingAnchor.constraint(equalTo: kindLabel.trailingAnchor, constant: 14),
            kindPopup.centerYAnchor.constraint(equalTo: kindLabel.centerYAnchor),
            kindPopup.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),

            effectLabel.topAnchor.constraint(equalTo: kindPopup.bottomAnchor, constant: 16),
            effectLabel.leadingAnchor.constraint(equalTo: kindLabel.leadingAnchor),
            effectLabel.widthAnchor.constraint(equalTo: kindLabel.widthAnchor),
            effectPopup.leadingAnchor.constraint(equalTo: kindPopup.leadingAnchor),
            effectPopup.centerYAnchor.constraint(equalTo: effectLabel.centerYAnchor),
            effectPopup.trailingAnchor.constraint(equalTo: kindPopup.trailingAnchor),

            valueLabel.topAnchor.constraint(equalTo: effectPopup.bottomAnchor, constant: 16),
            valueLabel.leadingAnchor.constraint(equalTo: kindLabel.leadingAnchor),
            valueLabel.widthAnchor.constraint(equalTo: kindLabel.widthAnchor),
            valueRow.leadingAnchor.constraint(equalTo: kindPopup.leadingAnchor),
            valueRow.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            valueRow.trailingAnchor.constraint(equalTo: kindPopup.trailingAnchor),
            valueRow.heightAnchor.constraint(equalToConstant: 26),
            chooseButton.widthAnchor.constraint(equalToConstant: 112),

            messageStack.topAnchor.constraint(equalTo: valueRow.bottomAnchor, constant: 10),
            messageStack.leadingAnchor.constraint(equalTo: kindPopup.leadingAnchor),
            messageStack.trailingAnchor.constraint(equalTo: kindPopup.trailingAnchor),
            actionStack.topAnchor.constraint(greaterThanOrEqualTo: messageStack.bottomAnchor, constant: 16),
            actionStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            actionStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            confirmButton.widthAnchor.constraint(equalToConstant: 100),
        ])

        if let existingRule {
            kindPopup.selectItem(at: advancedPolicyKinds.firstIndex(of: existingRule.matchKind) ?? 0)
            effectPopup.selectItem(at: existingRule.effect == .allow ? 0 : 1)
            valueField.stringValue = existingRule.value
        }

        let editor = NSPanel(contentRect: contentView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        editor.title = isEditing ? "Edit Application Rule" : "Add Application Rule"
        editor.contentView = contentView
        editor.isReleasedWhenClosed = false
        editor.initialFirstResponder = valueField

        trackpadRuleEntryWindow = editor
        trackpadRuleEntryEditingSelectorKey = existingRule.map({ selectorKey(for: $0) })
        trackpadRuleEntryKindPopup = kindPopup
        trackpadRuleEntryEffectPopup = effectPopup
        trackpadRuleEntryValueField = valueField
        trackpadRuleEntryChooseButton = chooseButton
        trackpadRuleEntryHint = hint
        trackpadRuleEntryError = error
        kindPopup.target = self
        kindPopup.action = #selector(updateAdvancedTrackpadPolicyRuleForm(_:))
        updateAdvancedTrackpadPolicyRuleForm(kindPopup)

        parentWindow.beginSheet(editor) { [weak self] _ in
            self?.clearAdvancedTrackpadPolicyRuleForm()
        }
    }

    private func resizeAdvancedTrackpadPolicyRuleEntry() {
        guard let editor = trackpadRuleEntryWindow else { return }
        let targetHeight: CGFloat = trackpadRuleEntryError?.isHidden == false ? 290 : 265
        guard editor.contentView?.bounds.height != targetHeight else { return }
        editor.setContentSize(NSSize(width: 700, height: targetHeight))
    }

    private func clearAdvancedTrackpadPolicyRuleForm() {
        trackpadRuleEntryWindow = nil
        trackpadRuleEntryKindPopup = nil
        trackpadRuleEntryEffectPopup = nil
        trackpadRuleEntryValueField = nil
        trackpadRuleEntryChooseButton = nil
        trackpadRuleEntryHint = nil
        trackpadRuleEntryError = nil
        trackpadRuleEntryEditingSelectorKey = nil
    }

    private func selectedAdvancedTrackpadPolicyKind() -> ApplicationPolicyMatchKind? {
        guard let popup = trackpadRuleEntryKindPopup,
              advancedPolicyKinds.indices.contains(popup.indexOfSelectedItem) else { return nil }
        return advancedPolicyKinds[popup.indexOfSelectedItem]
    }

    @objc private func updateAdvancedTrackpadPolicyRuleForm(_ sender: NSPopUpButton) {
        guard let kind = selectedAdvancedTrackpadPolicyKind(),
              let valueField = trackpadRuleEntryValueField,
              let chooseButton = trackpadRuleEntryChooseButton,
              let hint = trackpadRuleEntryHint else { return }

        chooseButton.isHidden = kind == .processName
        switch kind {
        case .executablePath:
            valueField.placeholderString = "/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder"
            hint.stringValue = "Use Choose App… to fill the exact executable path. Finder.app is a bundle, not an executable path."
        case .wrapperBundleIdentifier:
            valueField.placeholderString = "com.example.wrapper"
            hint.stringValue = "Choose an app to fill its exact bundle identifier."
        case .wrapperPath:
            valueField.placeholderString = "/Applications/Wrapper.app"
            hint.stringValue = "Use Choose App… to fill the exact wrapper application path."
        case .processName:
            valueField.placeholderString = "java"
            hint.stringValue = "Enter a process name such as java. This fallback is used only when macOS provides no stable app identity."
        case .bundleIdentifier:
            valueField.placeholderString = "com.example.app"
            hint.stringValue = "Bundle-ID rules are normally managed with Edit Apps…."
        }
    }

    @objc private func chooseAdvancedTrackpadPolicyApp(_ sender: NSButton) {
        guard let kind = selectedAdvancedTrackpadPolicyKind(), kind != .processName else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowsOtherFileTypes = false
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.applicationBundle]
        } else {
            panel.allowedFileTypes = ["app"]
        }
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        let applySelection: (NSApplication.ModalResponse) -> Void = { [weak self, weak panel] response in
            guard response == .OK,
                  let self,
                  let panel,
                  let url = panel.url,
                  let bundle = Bundle(url: url),
                  let kind = self.selectedAdvancedTrackpadPolicyKind(),
                  let valueField = self.trackpadRuleEntryValueField else { return }

            let value: String?
            switch kind {
            case .executablePath:
                value = bundle.executableURL?.path
            case .wrapperBundleIdentifier:
                value = bundle.bundleIdentifier
            case .wrapperPath:
                value = url.path
            case .processName:
                value = nil
            case .bundleIdentifier:
                value = bundle.bundleIdentifier
            }
            if let value {
                valueField.stringValue = value
                self.trackpadRuleEntryError?.isHidden = true
                self.resizeAdvancedTrackpadPolicyRuleEntry()
            } else {
                self.showAdvancedTrackpadPolicyRuleError("The selected app does not expose the identity needed for this selector.")
            }
        }

        if let window = trackpadRuleEntryWindow {
            panel.beginSheetModal(for: window, completionHandler: applySelection)
        } else if panel.runModal() == .OK {
            applySelection(.OK)
        }
    }

    private func showAdvancedTrackpadPolicyRuleError(_ message: String) {
        trackpadRuleEntryError?.stringValue = message
        trackpadRuleEntryError?.isHidden = false
        resizeAdvancedTrackpadPolicyRuleEntry()
    }

    private func selectorKey(for rule: ApplicationPolicyRule) -> String {
        "\(rule.matchKind.rawValue):\(rule.value)"
    }

    @objc private func confirmAdvancedTrackpadPolicyRule(_ sender: NSButton) {
        guard let kind = selectedAdvancedTrackpadPolicyKind(),
              let effectPopup = trackpadRuleEntryEffectPopup,
              let valueField = trackpadRuleEntryValueField else { return }
        let effect: ApplicationPolicyEffect = effectPopup.indexOfSelectedItem == 0 ? .allow : .deny
        guard let rule = ApplicationPolicyRule(matchKind: kind, value: valueField.stringValue, effect: effect) else {
            showAdvancedTrackpadPolicyRuleError("Enter a valid exact value. Paths must be absolute; wildcards are not supported.")
            return
        }

        let editingSelectorKey = trackpadRuleEntryEditingSelectorKey
        var rules = trackpadPolicyRulesDataSource.rules
        let newSelectorKey = selectorKey(for: rule)
        guard !rules.contains(where: { existingRule in
            selectorKey(for: existingRule) == newSelectorKey
                && selectorKey(for: existingRule) != editingSelectorKey
        }) else {
            showAdvancedTrackpadPolicyRuleError("That selector already exists in another rule.")
            return
        }
        if let editingSelectorKey {
            guard let editingIndex = rules.firstIndex(where: { selectorKey(for: $0) == editingSelectorKey }) else {
                showAdvancedTrackpadPolicyRuleError("That rule is no longer available. Close this form and try again.")
                return
            }
            rules[editingIndex] = rule
        } else {
            rules.append(rule)
        }
        guard saveAdvancedPolicyRules(rules) else {
            showAdvancedTrackpadPolicyRuleError("The policy could not be saved. It may already contain the maximum number of rules.")
            return
        }
        let refreshedRules = currentAdvancedPolicyRules()
        trackpadPolicyRulesDataSource.rules = refreshedRules
        trackpadPolicyTableView?.reloadData()
        if let selectedRow = refreshedRules.firstIndex(where: { selectorKey(for: $0) == newSelectorKey }) {
            trackpadPolicyTableView?.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
        }
        updateAdvancedTrackpadPolicyEditButton()
        cancelAdvancedTrackpadPolicyRule(sender)
    }

    @objc private func cancelAdvancedTrackpadPolicyRule(_ sender: NSButton) {
        guard let editor = trackpadRuleEntryWindow else { return }
        if let parent = editor.sheetParent {
            parent.endSheet(editor)
        } else {
            editor.close()
            clearAdvancedTrackpadPolicyRuleForm()
        }
    }

    @objc private func removeAdvancedTrackpadPolicyRule(_ sender: NSButton) {
        guard let tableView = trackpadPolicyTableView else { return }
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }
        var rules = trackpadPolicyRulesDataSource.rules
        for index in selectedRows.sorted(by: >) {
            rules.remove(at: index)
        }
        guard saveAdvancedPolicyRules(rules) else { return }
        trackpadPolicyRulesDataSource.rules = currentAdvancedPolicyRules()
        tableView.reloadData()
        updateAdvancedTrackpadPolicyEditButton()
    }

    @objc private func closeAdvancedTrackpadPolicyEditor(_ sender: NSButton) {
        guard let editor = trackpadPolicyEditorWindow, let parent = editor.sheetParent else { return }
        parent.endSheet(editor)
    }
    
    /// Keep the general toggles together at the top, followed by the two
    /// axis-specific settings sections. This is done before any collapsible
    /// sections are initialized, so the existing stack animation machinery
    /// continues to own the views normally.
    private func arrangeSections() {
        guard masterStack.arrangedSubviews.contains(smoothnessSection),
              masterStack.arrangedSubviews.contains(generalDivider) else { return }

        masterStack.removeArrangedSubview(smoothnessSection)
        let dividerIndex = masterStack.arrangedSubviews.firstIndex(of: generalDivider) ?? 0
        masterStack.insertArrangedSubview(smoothnessSection, at: dividerIndex + 1)

        guard speedDivider == nil,
              let smoothnessIndex = masterStack.arrangedSubviews.firstIndex(of: smoothnessSection) else { return }

        let divider = NSView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        divider.addSubview(separator)
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 17),
            separator.leadingAnchor.constraint(equalTo: divider.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: divider.trailingAnchor),
            separator.topAnchor.constraint(equalTo: divider.topAnchor, constant: 8),
            separator.bottomAnchor.constraint(equalTo: divider.bottomAnchor, constant: -8),
        ])

        masterStack.insertArrangedSubview(divider, at: smoothnessIndex + 1)
        divider.widthAnchor.constraint(equalTo: masterStack.widthAnchor).isActive = true
        speedDivider = divider
    }

    /// Did appear
    
    override func viewDidAppear() {

        /// Remove focus
        ///     Sometimes, one of the modifierCapture fields is randomly selected. This hopefully prevents that.
        ///     Need to do asynAfter 0.0 seconds for it to work (I think - not well tested) that makes it do it on the next runLoop cycle I think.

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0, execute: {
            MainAppState.shared.window?.makeFirstResponder(nil)
        })
        
        /// The menu-bar kill switch is a persistent user choice. Opening the
        /// settings window must not silently re-enable scrolling.
    }
    
    /// Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        arrangeSections()

        /// There was some reason we don't use viewDidLoad here, and instead we use awakeFromNib. I think it had to do with preventing animations from playing when the app starts right into this tab or sth. But maybe it's just unnecessary.
        /// Edit: The replacing between the macOSHint and the preciseSection broke when we used awakeFromNib. Not totally sure why. Let's hope viewDidLoad works after all.
        
        /// Smooth
        
        verticalSmooth.bindingTarget <~ smoothPicker.reactive.selectedIdentifiers.map({ $0!.rawValue })
        smoothPicker.reactive.selectedIdentifier <~ verticalSmooth.producer.map({ NSUserInterfaceItemIdentifier($0) })

        horizontalSmooth.bindingTarget <~ horizontalSmoothPicker.reactive.selectedIdentifiers.map({ $0!.rawValue })
        horizontalSmoothPicker.reactive.selectedIdentifier <~ horizontalSmooth.producer.map({ NSUserInterfaceItemIdentifier($0) })

        trackpadSection.reactive.isCollapsed <~ SignalProducer.combineLatest(verticalSmooth.producer, horizontalSmooth.producer)
            .map({ vertical, horizontal in vertical != "high" && horizontal != "high" })
        
        let MF_TEST = 0
        if MF_TEST == 0 { /// Remove the experimental "low" option in release builds
            smoothPicker.menu?.item(withIdentifier: NSUserInterfaceItemIdentifier("low"))?.isHidden = true
        }
        
        /// Trackpad
        trackpad.bindingTarget <~ trackpadToggle.reactive.boolValues
        trackpadToggle.reactive.boolValue <~ trackpad.producer

        configureTrackpadScopeUI()
        
        /// Reverse direction
        reverseDirectionVertical.bindingTarget <~ reverseDirectionVerticalToggle.reactive.boolValues
        reverseDirectionVerticalToggle.reactive.boolValue <~ reverseDirectionVertical.producer
        reverseDirectionHorizontal.bindingTarget <~ reverseDirectionHorizontalToggle.reactive.boolValues
        reverseDirectionHorizontalToggle.reactive.boolValue <~ reverseDirectionHorizontal.producer
        
        /// Scroll speed
        verticalSpeed.bindingTarget <~ speedPicker.reactive.selectedIdentifiers.map({ identifier in
            identifier!.rawValue
        })
        speedPicker.reactive.selectedIdentifier <~ verticalSpeed.producer.map({ NSUserInterfaceItemIdentifier($0) })

        horizontalSpeed.bindingTarget <~ horizontalSpeedPicker.reactive.selectedIdentifiers.map({ identifier in
            identifier!.rawValue
        })
        horizontalSpeedPicker.reactive.selectedIdentifier <~ horizontalSpeed.producer.map({ NSUserInterfaceItemIdentifier($0) })

        /// Trackpad Simulation app scope
        trackpadScope.bindingTarget <~ trackpadScopePicker.reactive.selectedIdentifiers.map({ identifier in
            identifier!.rawValue
        })
        trackpadScopePicker.reactive.selectedIdentifier <~ trackpadScope.producer.map({ NSUserInterfaceItemIdentifier($0) })
        trackpadScope.producer.startWithValues { [weak self] _ in
            guard let self else { return }
            if self.updateApplicationPolicyInConfig() {
                commitConfig()
            }
            self.updateTrackpadAppsUI()
        }
        updateTrackpadAppsUI()
        
        /// Precise
        /// Notes:
        /// - Why do we generate the preciseHint text in code instead of setting it in IB?
        /// - TODO: Determine line-width programmatically. (We're telling translators to set the line break to their own taste, to make the layout look good, but now that we expect localizers to use .xcloc files instead of running the app that might be difficult.)
        ///     -> Do the same thing for all UI strings with non-semantic linebreaks. (non-semantic means they linebreak exists to make the layout look good not to separate text logically.)
        precise.bindingTarget <~ preciseToggle.reactive.boolValues
        preciseToggle.reactive.boolValue <~ precise.producer
        let preciseHintRaw = MFLocalizedString("precise-scrolling-hint", comment: "The mention of keyboard modifiers is meant to draw attention to the keyboard modifers section of the UI which appears right below. (Search for: 'Scrolling > Keyboard Modifiers')")
        preciseHint.attributedStringValue = MarkdownParser.attributedString(withCoolMarkdown: preciseHintRaw, fillOutBase: false)!.fillingOutBaseAsHint()
        
        /// Hardcode tab width
        ///     Do this before installing the macOS hint so it can accurately calculate the size of stuff [Sep 2025]
        applyHardcodedTabWidth("scrolling", self, widthControllingTextFields: [preciseHint]) /// The `macOSHint` below is not 'widthDetermining' so we don't need to pass it in here.
    
        /// Set up macOSHint
        do {
    
            /// Generate macOS hint string
            /// Notes:
            ///   - Under Ventura, you can open the mouse prefpane with the URL `x-apple.systempreferences:com.apple.Mouse-Settings.extension`, but it only works when a mouse is attached and otherwise it will give weird errors, so we're not using it now. We might want to use it if  we test whether a mouse is attached beforehand, or if future Ventura Betas give less janky errors
            ///     - A nice solution was if we had a reactive `activeDevice` class which we could attach to and update this stuff whenever it changes. See `MessagePortUtility_App.getActiveDeviceInfo()`
            ///   - Pre-Ventura you can open the prefPane with `file:///System/Library/PreferencePanes/Mouse.prefPane` but clicking that link inside the macOSHint just reveals the `.prefPane` file in Finder under Big Sur instead of opening it.
            
            var mouseSettingsURL: NSString
            if #available(macOS 13.0, *) {
                
                mouseSettingsURL = "x-apple.systempreferences:com.apple.Mouse-Settings.extension"
                mouseSettingsURL = "" /// Disable for now (see above)
            } else {
                mouseSettingsURL = "file:///System/Library/PreferencePanes/Mouse.prefPane"
                mouseSettingsURL = "" /// Disable for now (see above)
            }
            let macOSHintRaw = String(format: MFLocalizedString("macos-scrolling-hint", comment: "%1$@ will be the name of the System Settings app.\n\nConsider putting the destination in the System Settings on its own line just like English to make the text easier to scan."), UIStrings.systemSettingsName(), mouseSettingsURL)
        
            /// Install the macOSHint.
            ///     We manually make the macOSHint width equal the preciseSection width, because if the width changes the window resizes from the left edge which looks crappy.
            ///     This is a really hacky solution. Move this logic into CollapsableStackView (maybe rename to AnimatingStackView or sth).
            ///         Make a method `register(switchableViews:forArrangedSubview:)` which calculates a size that fits all those views, and then you switch between them with `switchTo(view:)`..
            
            let macOSHint = CoolNSTextField(hintWithAttributedString: MarkdownParser.attributedString(withCoolMarkdown: macOSHintRaw, fillOutBase: false)!)
            
            do {
                macOSHint.translatesAutoresizingMaskIntoConstraints = false
                macOSHint.setContentHuggingPriority(.required, for: .horizontal)
                macOSHint.setContentHuggingPriority(.required, for: .vertical)
                macOSHint.cell?.wraps = true
                
                let macOSHintIndent = NSView()
                do {
                    macOSHintIndent.translatesAutoresizingMaskIntoConstraints = false
                }
                
                do {
                    macOSHintIndent.addSubview(macOSHint)
                    
                    macOSHint.leadingAnchor .constraint(equalTo: macOSHintIndent/*.layoutMarginsGuide*/.leadingAnchor).isActive = true
                    macOSHint.trailingAnchor.constraint(equalTo: macOSHintIndent.trailingAnchor).isActive = true
                    macOSHint.topAnchor     .constraint(equalTo: macOSHintIndent.topAnchor).isActive = true
                    macOSHint.bottomAnchor  .constraint(equalTo: macOSHintIndent.bottomAnchor).isActive = true
                }
                
                /// Create explicit width constraints, that match the natural width of the preciseSection
                ///     Reasons:
                ///     - macOSHintIndent needs the width constraint so the window stays the same width when it is swapped in (See notes above under `Install the macOSHint`) [Sep 2025]
                ///     - preciseSection needs the width constraint to not become temporarily too wide during animation. This is probably a bug in our replaceAnimations. This only became necessary after `applyHardcodedTabWidth()` [Sep 2025]
                ///     Brittle hacks around measuring size: [Sep 2025]
                ///         - What we wanna do here is measure the 'natural' size of the `preciseSection` and then make the view we swap it out for (`macOSHintIndent`) the same width using a layout constraint.
                ///         - The problem is that I cannot figure out how to accurately measure the 'natural' size of the preciseSection here.
                ///             - I think it might be impossible in viewDidLoad()? See https://stackoverflow.com/a/28263756/10601702. [Sep 2025]
                ///         - We happened to sorta randomly find 2 ways to accurately measure the `preciseSection` in certain circumstances:
                ///             - 1. When none of the textFields in the preciseSection were wrapping, we could measure its size using `.fittingSize` (Cause that size doesn't depend on the rest of the layout, it's just an intrinsic property.)
                ///             - 2. After making the textFields wrapping and using `applyHardcodedTabWidth()`, somehow `layoutSubtreeIfNeeded()` works. But it breaks if we don't set an explicit width constraint (We wanted to do that in `applyHardcodedTabWidth()` for Chinese but disabling that, since it breaks this).
                do {
                    let preciseSectionWidth: CGFloat
                    do {
                        self.view.needsLayout = true        /// Layout `self.view`, since that's where `applyHardcodedTabWidth()` applies its width constraint. [Sep 2025]
                        self.view.layoutSubtreeIfNeeded()
                        preciseSectionWidth = preciseSection.frame.width
                    }
                    preciseSection .widthAnchor.constraint(equalToConstant: preciseSectionWidth).addingIdentifier("preciseSectionWidth").isActive = true
                    macOSHintIndent.widthAnchor.constraint(equalToConstant: preciseSectionWidth).addingIdentifier("macOSHintIndentWidth").isActive = true
                }
            
                do {
                    let preciseSectionRetained: NSStackView? = self.preciseSection /// [Sep 2025] Why do we need this?
                    var macOSHintIsDisplaying = false
                    var isInitialized = false
                    
                    SignalProducer.combineLatest(verticalSpeed.producer, horizontalSpeed.producer).startWithValues { verticalSpeed, horizontalSpeed in
                        let usesSystemSpeed = verticalSpeed == "system" || horizontalSpeed == "system"
                        if usesSystemSpeed && !macOSHintIsDisplaying {
                            self.preciseSection.animatedReplace(with: macOSHintIndent, doAnimate: isInitialized)
                            macOSHintIsDisplaying = true
                        } else if !usesSystemSpeed && macOSHintIsDisplaying {
                            assert(isInitialized)
                            macOSHintIndent.animatedReplace(with: preciseSectionRetained!, doAnimate: isInitialized)
                            macOSHintIsDisplaying = false
                        }
                        isInitialized = true
                    }
                }
            }
        }
        
        /// Scrollwheel capture notifications
        /// Notes:
        /// - You can find discussion of the design-thoughts behind this inside `getCapturedButtonsAndExcludeButtonsThatAreOnlyCapturedByModifier:`
        /// - How to ship this:
        ///     - We're introducing new localizable strings, so we should ship this in a major update with a Beta version
        ///     - Once we shipped it, we should probably update the Captured Buttons Guide: https://redirect.macmousefix.com/?target=mmf-captured-buttons-guide - or create a new guide.
        
        let modProducer = SignalProducer.combineLatest(horizontalMod.producer, zoomMod.producer, swiftMod.producer, preciseMod.producer) /// We could reuse this down in the Keyboard modifier section, but currently, we're not
        let axisSettingProducer = SignalProducer.combineLatest(
            SignalProducer.combineLatest(verticalSmooth.producer, horizontalSmooth.producer),
            SignalProducer.combineLatest(verticalSpeed.producer, horizontalSpeed.producer)
        )
        let captureProducer = SignalProducer.combineLatest(axisSettingProducer, reverseDirectionVertical.producer, reverseDirectionHorizontal.producer, modProducer).combinePrevious()
            
        captureProducer.startWithValues { (previous, current) in
            
            DDLogDebug("ScrollTab - Capture-relevant settings changed")
            
            if NSApp.mainWindow != nil {
                
                let (axisSettings0, reverseV0, reverseH0, mods0) = previous
                let (axisSettings1, reverseV1, reverseH1, mods1) = current
                let ((smooth0, horizontalSmooth0), (speed0, horizontalSpeed0)) = axisSettings0
                let ((smooth1, horizontalSmooth1), (speed1, horizontalSpeed1)) = axisSettings1
                
                let (horizontal0, zoom0, swift0, precise0) = mods0
                let (horizontal1, zoom1, swift1, precise1) = mods1
                
                let wasCaptured = smooth0 != "off" || horizontalSmooth0 != "off" || reverseV0 || reverseH0 || speed0 != "system" || horizontalSpeed0 != "system" || horizontal0 != 0 || zoom0 != 0 || swift0 != 0 || precise0 != 0 /// Including the modifiers here is a little 'semantically incorrect' but we still do it. See `getCapturedButtonsAndExcludeButtonsThatAreOnlyCapturedByModifier:` [Sep 2025]
                let isCaptured  = smooth1 != "off" || horizontalSmooth1 != "off" || reverseV1 || reverseH1 || speed1 != "system" || horizontalSpeed1 != "system" || horizontal1 != 0 || zoom1 != 0 || swift1 != 0 || precise1 != 0

                DDLogDebug("ScrollTab - smooth: \(smooth0)/\(horizontalSmooth0)->\(smooth1)/\(horizontalSmooth1) reverseV: \(reverseV0)->\(reverseV1) reverseH: \(reverseH0)->\(reverseH1) speed: \(speed0)/\(horizontalSpeed0)->\(speed1)/\(horizontalSpeed1) horizontal: \(horizontal0)->\(horizontal1) zoom: \(zoom0)->\(zoom1) swift: \(swift0)->\(swift1) precise: \(precise0)->\(precise1)")
                
                if wasCaptured && !isCaptured {
                    CaptureToasts.showScrollWheelCaptureToast(false)
                }
                if !wasCaptured && isCaptured {
                    CaptureToasts.showScrollWheelCaptureToast(true)
                }
            }
        }
        
        /// Keyboard modifiers
        
        horizontalModField <~ horizontalMod.producer.map({ NSEvent.ModifierFlags(rawValue: $0) })
        horizontalMod <~ horizontalModField.signal.map({ $0.rawValue })
        zoomModField <~ zoomMod.producer.map({ NSEvent.ModifierFlags(rawValue: $0) })
        zoomMod <~ zoomModField.signal.map({ $0.rawValue })
        swiftModField <~ swiftMod.producer.map({ NSEvent.ModifierFlags(rawValue: $0) })
        swiftMod <~ swiftModField.signal.map({ $0.rawValue })
        preciseModField <~ preciseMod.producer.map({ NSEvent.ModifierFlags(rawValue: $0) })
        preciseMod <~ preciseModField.signal.map({ $0.rawValue })
        
        /// Keep these in sync with the `default_config`
        typealias Mods = NSEvent.ModifierFlags
        let defaultH: Mods = [.shift]
        let defaultZ: Mods = [.command]
        let defaultS: Mods = [.control]
        let defaultP: Mods = [.option]
        
        restoreDefaultModsButton.reactive.states.observeValues { state in
            self.horizontalMod.set(defaultH.rawValue)
            self.zoomMod.set(defaultZ.rawValue)
            self.swiftMod.set(defaultS.rawValue)
            self.preciseMod.set(defaultP.rawValue)
        }
        
        /// v Using Signal.combineLatest here might be easier.
        ///     Edit: I could do it using combinePrevious() on the modProducer we defined above, but I think it would be much more complicated and less elegant
        
        let allFlags = SignalProducer<(String, UInt), Never>.merge(horizontalMod.producer.map{ ("h", $0) }, zoomMod.producer.map{ ("z", $0) }, swiftMod.producer.map{ ("s", $0) }, preciseMod.producer.map{ ("p", $0) })
        allFlags.startWithValues { (src, flags) in
            
//            DispatchQueue.main.async { /// Need to dispatch async to prevent weird crashes inside ReactiveSwift. Edit: When / why did we comment this out? Seems to not be needed anymore
                
                /// Delete the modifiers which the user just set - delete them for all the other scroll modifications
                ///     So you can't set two different modifications to the same modifier
            
                if self.horizontalMod.get() == flags && src != "h" {
                    self.horizontalMod.set(0)
                }
                if self.zoomMod.get() == flags && src != "z" {
                    self.zoomMod.set(0)
                }
                if self.swiftMod.get() == flags && src != "s" {
                    self.swiftMod.set(0)
                }
                if self.preciseMod.get() == flags && src != "p" {
                    self.preciseMod.set(0)
                }
                
                /// Make restoreDefaults button appear/disappear
            
                var restoreDefaultsIsEnabled = true
                
                if self.horizontalMod.get() == defaultH.rawValue
                    && self.zoomMod.get() == defaultZ.rawValue
                    && self.swiftMod.get() == defaultS.rawValue
                    && self.preciseMod.get() == defaultP.rawValue {
                    
                    restoreDefaultsIsEnabled = false
                }
                
                Animate.with(CABasicAnimation(name: .default, duration: 0.1)) {
                    self.restoreDefaultModsButton.reactiveAnimator().alphaValue.set(restoreDefaultsIsEnabled ? 1.0 : 0.0)
                }
//            }
        }
    }
}
