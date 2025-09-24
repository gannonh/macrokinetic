//
//  TestUtilities+ElementTypes.swift
//  JabTrackerUITests
//
//  Extension for XCUIElement.ElementType conversion functionality
//

import XCTest

extension TestUtilities {
    /// Convert XCUIElement.ElementType raw value to readable string
    /// - Parameter elementType: The XCUIElement.ElementType to convert
    /// - Returns: Human-readable string representation of the element type
    static func elementTypeName(from elementType: XCUIElement.ElementType) -> String {
        // Split into categories to reduce cyclomatic complexity
        if let containerType = containerElementTypeName(from: elementType) {
            return containerType
        }
        if let controlType = controlElementTypeName(from: elementType) {
            return controlType
        }
        if let textType = textElementTypeName(from: elementType) {
            return textType
        }
        if let navigationType = navigationElementTypeName(from: elementType) {
            return navigationType
        }
        if let specialType = specialElementTypeName(from: elementType) {
            return specialType
        }
        return "Unknown(\(elementType.rawValue))"
    }

    /// Container and layout element types
    private static func containerElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .application: return "Application"
        case .group: return "Group"
        case .window: return "Window"
        case .sheet: return "Sheet"
        case .drawer: return "Drawer"
        case .popover: return "Popover"
        case .scrollView: return "ScrollView"
        case .scrollBar: return "ScrollBar"
        default: return self.tableElementTypeName(from: elementType)
        }
    }

    /// Table and collection element types
    private static func tableElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .table: return "Table"
        case .tableRow: return "TableRow"
        case .tableColumn: return "TableColumn"
        case .outline: return "Outline"
        case .outlineRow: return "OutlineRow"
        case .browser: return "Browser"
        case .collectionView: return "CollectionView"
        case .grid: return "Grid"
        case .cell: return "Cell"
        default: return self.layoutElementTypeName(from: elementType)
        }
    }

    /// Layout element types
    private static func layoutElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .splitGroup: return "SplitGroup"
        case .splitter: return "Splitter"
        case .layoutArea: return "LayoutArea"
        case .layoutItem: return "LayoutItem"
        default: return nil
        }
    }

    /// Control element types
    private static func controlElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        if let buttonType = buttonElementTypeName(from: elementType) {
            return buttonType
        }
        if let inputType = inputControlElementTypeName(from: elementType) {
            return inputType
        }
        return self.indicatorElementTypeName(from: elementType)
    }

    /// Button element types
    private static func buttonElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .button: return "Button"
        case .radioButton: return "RadioButton"
        case .radioGroup: return "RadioGroup"
        case .checkBox: return "CheckBox"
        case .disclosureTriangle: return "DisclosureTriangle"
        case .popUpButton: return "PopUpButton"
        case .menuButton: return "MenuButton"
        case .toolbarButton: return "ToolbarButton"
        default: return self.arrowElementTypeName(from: elementType)
        }
    }

    /// Arrow element types
    private static func arrowElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .incrementArrow: return "IncrementArrow"
        case .decrementArrow: return "DecrementArrow"
        default: return nil
        }
    }

    /// Input control element types
    private static func inputControlElementTypeName(from elementType: XCUIElement.ElementType)
        -> String?
    {
        switch elementType {
        case .slider: return "Slider"
        case .segmentedControl: return "SegmentedControl"
        case .switch: return "Switch"
        case .toggle: return "Toggle"
        case .colorWell: return "ColorWell"
        case .handle: return "Handle"
        case .stepper: return "Stepper"
        case .comboBox: return "ComboBox"
        default: return self.pickerElementTypeName(from: elementType)
        }
    }

    /// Picker element types
    private static func pickerElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .picker: return "Picker"
        case .pickerWheel: return "PickerWheel"
        case .datePicker: return "DatePicker"
        default: return nil
        }
    }

    /// Indicator element types
    private static func indicatorElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .pageIndicator: return "PageIndicator"
        case .progressIndicator: return "ProgressIndicator"
        case .activityIndicator: return "ActivityIndicator"
        case .ratingIndicator: return "RatingIndicator"
        case .valueIndicator: return "ValueIndicator"
        case .levelIndicator: return "LevelIndicator"
        default: return nil
        }
    }

    /// Text and input element types
    private static func textElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .staticText: return "StaticText"
        case .textField: return "TextField"
        case .secureTextField: return "SecureTextField"
        case .textView: return "TextView"
        case .searchField: return "SearchField"
        case .link: return "Link"
        default: return nil
        }
    }

    /// Navigation and menu element types
    private static func navigationElementTypeName(from elementType: XCUIElement.ElementType)
        -> String?
    {
        if let barType = navigationBarElementTypeName(from: elementType) {
            return barType
        }
        return self.menuElementTypeName(from: elementType)
    }

    /// Navigation bar element types
    private static func navigationBarElementTypeName(from elementType: XCUIElement.ElementType)
        -> String?
    {
        switch elementType {
        case .navigationBar: return "NavigationBar"
        case .tabBar: return "TabBar"
        case .tabGroup: return "TabGroup"
        case .toolbar: return "Toolbar"
        case .statusBar: return "StatusBar"
        case .tab: return "Tab"
        case .touchBar: return "TouchBar"
        case .statusItem: return "StatusItem"
        default: return nil
        }
    }

    /// Menu element types
    private static func menuElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .menu: return "Menu"
        case .menuItem: return "MenuItem"
        case .menuBar: return "MenuBar"
        case .menuBarItem: return "MenuBarItem"
        default: return nil
        }
    }

    /// Special and miscellaneous element types
    private static func specialElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        if let dialogType = dialogElementTypeName(from: elementType) {
            return dialogType
        }
        if let mediaType = mediaElementTypeName(from: elementType) {
            return mediaType
        }
        return self.accessoryElementTypeName(from: elementType)
    }

    /// Dialog element types
    private static func dialogElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .alert: return "Alert"
        case .dialog: return "Dialog"
        case .keyboard: return "Keyboard"
        case .key: return "Key"
        default: return nil
        }
    }

    /// Media element types
    private static func mediaElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .image: return "Image"
        case .icon: return "Icon"
        case .map: return "Map"
        case .webView: return "WebView"
        case .timeline: return "Timeline"
        default: return nil
        }
    }

    /// Accessory element types
    private static func accessoryElementTypeName(from elementType: XCUIElement.ElementType) -> String? {
        switch elementType {
        case .relevanceIndicator: return "RelevanceIndicator"
        case .helpTag: return "HelpTag"
        case .matte: return "Matte"
        case .dockItem: return "DockItem"
        case .ruler: return "Ruler"
        case .rulerMarker: return "RulerMarker"
        default: return nil
        }
    }
}
