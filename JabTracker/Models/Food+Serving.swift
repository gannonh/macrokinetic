//
//  Food+Serving.swift
//  JabTracker
//
//  Per-serving macro calculations for Food model.
//

import Foundation

extension Food {
    /// Calories per default serving
    var caloriesPerServing: Double {
        (caloriesPer100g / 100.0) * servingSize
    }

    /// Protein per default serving
    var proteinPerServing: Double {
        (proteinPer100g / 100.0) * servingSize
    }

    /// Carbs per default serving
    var carbsPerServing: Double {
        (carbsPer100g / 100.0) * servingSize
    }

    /// Fat per default serving
    var fatPerServing: Double {
        (fatPer100g / 100.0) * servingSize
    }
}
