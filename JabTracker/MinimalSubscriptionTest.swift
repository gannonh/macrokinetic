import StoreKit
import SwiftUI

@MainActor
class MinimalSubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadProducts() async {
        isLoading = true
        error = nil
        
        print("🛒 MinimalTest: Starting product load")
        
        do {
            let productIDs = ["com.gannonhall.JabTracker.test.monthly"]
            print("🛒 MinimalTest: Looking for product IDs: \(productIDs)")
            
            let products = try await Product.products(for: productIDs)
            print("🛒 MinimalTest: StoreKit returned \(products.count) products")
            
            for product in products {
                print("🛒 MinimalTest: Found product: \(product.id) - \(product.displayName)")
            }
            
            self.products = products
        } catch {
            print("🛒 MinimalTest: Error loading products: \(error)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
        print("🛒 MinimalTest: Load complete. Product count: \(products.count)")
    }
}

struct MinimalSubscriptionTestView: View {
    @StateObject private var manager = MinimalSubscriptionManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Minimal StoreKit Test")
                .font(.title)
            
            if manager.isLoading {
                ProgressView("Loading products...")
            }
            
            if let error = manager.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
            
            Text("Products loaded: \(manager.products.count)")
            
            ForEach(manager.products, id: \.id) { product in
                VStack {
                    Text(product.displayName)
                    Text(product.displayPrice)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Load Products") {
                Task {
                    await manager.loadProducts()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            Task {
                await manager.loadProducts()
            }
        }
    }
}