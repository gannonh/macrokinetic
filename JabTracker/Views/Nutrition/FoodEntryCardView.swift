//
//  FoodEntryCardView.swift
//  JabTracker
//
//  Card view for displaying a food entry with emoji, macros, and calories.
//

import SwiftUI

/// Card view displaying a food entry with emoji, macro info, and calories
struct FoodEntryCardView: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 12) {
            // Food emoji
            Text(FoodEmoji.emoji(for: entry.foodName, brand: entry.foodBrand))
                .font(.system(size: 40))
                .frame(width: 50, height: 50)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)

            // Food info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(macroText)
                        .foregroundColor(.cyan)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(servingText)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }

            Spacer()

            // Calories with flame
            HStack(spacing: 2) {
                Text("\(Int(entry.calories))")
                    .font(.headline)
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .cardStyle()
    }

    // MARK: - Computed Properties

    private var macroText: String {
        "\(Int(entry.protein))P  \(Int(entry.fat))F  \(Int(entry.carbs))C"
    }

    private var servingText: String {
        if let description = entry.servingDescription, !description.isEmpty {
            return "\(description) (\(Int(entry.servingGrams))g)"
        }
        return "\(Int(entry.servingGrams))g"
    }
}

// MARK: - Food Emoji Mapping

enum FoodEmoji {
    // Keyword to emoji mappings (checked in order for priority)
    private static let emojiMappings: [(keywords: [String], emoji: String)] = [
        // Fast food (high priority)
        (["burger", "whopper", "big mac"], "🍔"),
        (["pizza"], "🍕"),
        (["taco"], "🌮"),
        (["burrito", "wrap"], "🌯"),
        (["hot dog", "hotdog"], "🌭"),
        (["fries", "french fries"], "🍟"),
        (["sandwich", "sub"], "🥪"),
        // Proteins
        (["chicken"], "🍗"),
        (["steak", "beef"], "🥩"),
        (["fish", "salmon", "tuna"], "🐟"),
        (["shrimp", "prawn"], "🦐"),
        (["egg"], "🥚"),
        (["bacon"], "🥓"),
        // Grains
        (["rice"], "🍚"),
        (["pasta", "spaghetti", "noodle"], "🍝"),
        (["bread", "toast"], "🍞"),
        (["cereal", "oatmeal", "oat"], "🥣"),
        (["pancake", "waffle"], "🥞"),
        // Fruits
        (["apple"], "🍎"),
        (["banana"], "🍌"),
        (["orange"], "🍊"),
        (["grape"], "🍇"),
        (["strawberry", "berry"], "🍓"),
        (["watermelon", "melon"], "🍉"),
        (["peach"], "🍑"),
        (["pineapple"], "🍍"),
        (["mango"], "🥭"),
        (["avocado"], "🥑"),
        // Vegetables
        (["salad", "lettuce"], "🥗"),
        (["carrot"], "🥕"),
        (["broccoli"], "🥦"),
        (["corn"], "🌽"),
        (["potato", "chip", "crisp"], "🥔"),
        (["tomato"], "🍅"),
        (["cucumber"], "🥒"),
        (["pepper"], "🫑"),
        // Dairy
        (["milk", "yogurt", "yoghurt"], "🥛"),
        (["cheese"], "🧀"),
        (["butter"], "🧈"),
        (["ice cream"], "🍦"),
        // Drinks
        (["coffee"], "☕"),
        (["tea"], "🍵"),
        (["juice"], "🧃"),
        (["soda", "cola", "coke", "pepsi", "smoothie", "shake"], "🥤"),
        (["beer"], "🍺"),
        (["wine"], "🍷"),
        // Snacks/desserts
        (["cookie", "biscuit"], "🍪"),
        (["cake"], "🍰"),
        (["donut", "doughnut"], "🍩"),
        (["chocolate", "candy"], "🍫"),
        (["popcorn"], "🍿"),
        (["pretzel"], "🥨"),
        (["nut", "almond", "peanut"], "🥜"),
        // Asian foods
        (["sushi"], "🍣"),
        (["ramen"], "🍜"),
        (["dumpling"], "🥟"),
        (["curry"], "🍛"),
        // Other
        (["soup"], "🥣"),
    ]

    /// Get an appropriate emoji for a food item based on its name and brand
    static func emoji(for name: String, brand: String? = nil) -> String {
        let searchText = "\(name) \(brand ?? "")".lowercased()

        for (keywords, emoji) in emojiMappings
        where keywords.contains(where: { searchText.contains($0) }) {
            return emoji
        }

        return "🍽️"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        FoodEntryCardView(
            entry: FoodEntry(
                foodName: "Burger King Whopper No Cheese",
                foodBrand: "Burger King",
                mealSection: .lunch,
                servingGrams: 291,
                servingDescription: "1 item",
                caloriesPer100g: 233,
                proteinPer100g: 10.7,
                carbsPer100g: 18.6,
                fatPer100g: 12.7
            )
        )

        FoodEntryCardView(
            entry: FoodEntry(
                foodName: "Basmati Rice, Cooked In Salted Water",
                mealSection: .dinner,
                servingGrams: 140,
                caloriesPer100g: 115,
                proteinPer100g: 2.1,
                carbsPer100g: 26.4,
                fatPer100g: 0.1
            )
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
