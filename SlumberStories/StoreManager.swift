import Foundation
import StoreKit
import Combine

class StoreManager: ObservableObject {
    
    // ✅ Can be accessed anywhere, nonisolated
    static let productId = "com.armaniwolf.slumberstories.premium.monthly"
    
    private let storiesCountKey = "dreamyWolf_freeStoriesCount"
    private let freeStoriesAllowed = 3
    
    @Published var storiesUsed: Int = 0
    @Published var isPremiumUnlocked: Bool = false
    @Published var subscriptionProduct: Product? = nil
    
    private var updateListenerTask: Task<Void, Never>?
    
    init() {
        storiesUsed = UserDefaults.standard.integer(forKey: storiesCountKey)
        updateListenerTask = listenForTransactions()
        Task {
            await checkPremiumStatus()
            await fetchProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func shouldShowPaywall() -> Bool {
        if isPremiumUnlocked { return false }
        return storiesUsed >= freeStoriesAllowed
    }
    
    func incrementStoriesUsed() {
        if !isPremiumUnlocked {
            storiesUsed += 1
            UserDefaults.standard.set(storiesUsed, forKey: storiesCountKey)
        }
    }
    
    func fetchProducts() async {
        do {
            let products = try await Product.products(for: [StoreManager.productId])
            await MainActor.run {
                self.subscriptionProduct = products.first
            }
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func purchasePremium() async -> Bool {
        guard let product = subscriptionProduct else { return false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try StoreManager.checkVerified(verification)
                await MainActor.run { self.isPremiumUnlocked = true }
                await transaction.finish()
                return true
            case .userCancelled: return false
            case .pending: return false
            @unknown default: return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }
    
    func checkPremiumStatus() async {
        var foundActive = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? StoreManager.checkVerified(result),
               transaction.productID == StoreManager.productId {
                foundActive = true
                break
            }
        }
        await MainActor.run { self.isPremiumUnlocked = foundActive }
    }
    
    // ✅ Now static and nonisolated
    nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreKitError.userCancelled
        case .verified(let value): return value
        }
    }
    
    func listenForTransactions() -> Task<Void, Never> {
        let productId = StoreManager.productId
        return Task { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                do {
                    let transaction = try StoreManager.checkVerified(result)
                    if transaction.productID == productId {
                        await MainActor.run { self.isPremiumUnlocked = true }
                        await transaction.finish()
                    }
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
}
