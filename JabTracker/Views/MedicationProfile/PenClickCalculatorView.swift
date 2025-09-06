import SwiftUI

struct PenClickCalculatorView: View {
    let profile: MedicationProfile
    
    var body: some View {
        VStack {
            Text("Pen Click Calculator")
                .font(.largeTitle)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Pen Click Calculator")
    }
}