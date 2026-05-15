import Foundation
import StoreKit

protocol StoreKitProductCataloging {
    func matchRunProduct() async throws -> Product
}

enum StoreKitProductCatalogError: LocalizedError {
    case productNotFound(String)

    var errorDescription: String? {
        switch self {
        case .productNotFound(let productID):
            return "StoreKit product not found: \(productID)"
        }
    }
}

@MainActor
final class StoreKitProductCatalog: StoreKitProductCataloging {
    private var cachedMatchRunProduct: Product?

    func matchRunProduct() async throws -> Product {
        if let cachedMatchRunProduct {
            return cachedMatchRunProduct
        }

        let products = try await Product.products(for: [MatchPurchaseConfig.productID])
        let returnedProductIDs = products.map { $0.id }.joined(separator: ",")
        print("[payments] StoreKit lookup requested=\(MatchPurchaseConfig.productID) returned=\(returnedProductIDs)")
        guard let product = products.first(where: { $0.id == MatchPurchaseConfig.productID }) else {
            throw StoreKitProductCatalogError.productNotFound(MatchPurchaseConfig.productID)
        }

        cachedMatchRunProduct = product
        return product
    }
}
