import SwiftUI

struct ReconstitutionCalculatorView: View {
    let profile: MedicationProfile
    
    var body: some View {
        VStack {
            Text("Reconstitution Calculator")
                .font(.largeTitle)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Reconstitution Calculator")
    }
}