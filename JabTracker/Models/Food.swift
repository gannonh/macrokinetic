//
//  Food.swift
//  JabTracker
//
//  Food database item - represents a food from USDA, Open Food Facts, or user-created.
//

import Foundation
import SwiftData

/// Food database item - represents a food from USDA, Open Food Facts, or user-created
@Model
final class Food {
    // MARK: - Identity

    var id: UUID = UUID()
    var fdcId: Int = 0  // USDA Food Data Central ID (0 for non-USDA)

    // MARK: - Basic Information

    var name: String = ""  // Required - food name
    var brand: String?  // Optional - brand name
    var source: String = "local"  // FoodSource rawValue for CloudKit
    var barcode: String?  // Optional - UPC/EAN barcode

    // MARK: - Nutrition (per 100g)

    var caloriesPer100g: Double = 0.0
    var proteinPer100g: Double = 0.0
    var carbsPer100g: Double = 0.0
    var fatPer100g: Double = 0.0
    var fiberPer100g: Double = 0.0
    var sugarPer100g: Double = 0.0
    var sodiumPer100g: Double = 0.0  // mg

    // MARK: - Serving Information

    var servingSize: Double = 100.0
    var servingUnit: String = "g"
    var servingDescription: String?  // e.g., "1 cup", "1 slice"

    // MARK: - Timestamps

    var createdAt: Date = Date()
    var lastAccessedAt: Date = Date()

    // MARK: - Computed Properties

    var foodSource: FoodSource {
        get { FoodSource(rawValue: source) ?? .local }
        set { source = newValue.rawValue }
    }

    // MARK: - Initialization

    init(
        name: String = "",
        brand: String? = nil,
        fdcId: Int = 0,
        source: FoodSource = .local,
        barcode: String? = nil,
        caloriesPer100g: Double = 0.0,
        proteinPer100g: Double = 0.0,
        carbsPer100g: Double = 0.0,
        fatPer100g: Double = 0.0,
        fiberPer100g: Double = 0.0,
        sugarPer100g: Double = 0.0,
        sodiumPer100g: Double = 0.0,
        servingSize: Double = 100.0,
        servingUnit: String = "g",
        servingDescription: String? = nil
    ) {
        self.name = name
        self.brand = brand
        self.fdcId = fdcId
        self.source = source.rawValue
        self.barcode = barcode
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.sugarPer100g = sugarPer100g
        self.sodiumPer100g = sodiumPer100g
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.servingDescription = servingDescription
        self.createdAt = Date()
        self.lastAccessedAt = Date()
    }
}
