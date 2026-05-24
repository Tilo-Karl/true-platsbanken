import Foundation
import StoreKit

struct VerifiedPurchase {
    let productID: String
    let transactionID: UInt64
    let purchasedAt: Date
}

protocol PaymentProcessing {
    func charge(amountCents: Int, currency: String) async throws -> VerifiedPurchase
}

@MainActor
protocol PaymentTransactionObserving {
    func observeTransactions(_ handler: @escaping @MainActor (VerifiedPurchase) async -> Void)
}

struct StubPaymentProcessor: PaymentProcessing {
    func charge(amountCents: Int, currency: String) async throws -> VerifiedPurchase {
        try await Task.sleep(nanoseconds: 350_000_000)
        return VerifiedPurchase(
            productID: MatchPurchaseConfig.productID,
            transactionID: 0,
            purchasedAt: Date()
        )
    }
}

enum PaymentProcessingError: LocalizedError {
    case userCancelled
    case pending
    case unverified(String)
    case unexpectedPurchaseResult

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Payment was cancelled by the user."
        case .pending:
            return "Payment is pending external approval."
        case .unverified(let message):
            return "Payment verification failed: \(message)"
        case .unexpectedPurchaseResult:
            return "Payment returned an unexpected result."
        }
    }
}

@MainActor
final class StoreKitPaymentProcessor: PaymentProcessing, PaymentTransactionObserving {
    private let productCatalog: StoreKitProductCataloging
    private var transactionUpdatesTask: Task<Void, Never>?

    init(productCatalog: StoreKitProductCataloging) {
        self.productCatalog = productCatalog
    }

    func charge(amountCents: Int, currency: String) async throws -> VerifiedPurchase {
        let product = try await productCatalog.matchRunProduct()
        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            let transaction = try verifiedTransaction(from: verificationResult)
            await transaction.finish()
            print("[payments] purchase success product=\(product.id) tx=\(transaction.id)")
            return VerifiedPurchase(
                productID: transaction.productID,
                transactionID: transaction.id,
                purchasedAt: transaction.purchaseDate
            )
        case .pending:
            print("[payments] purchase pending product=\(product.id)")
            throw PaymentProcessingError.pending
        case .userCancelled:
            print("[payments] purchase cancelled product=\(product.id)")
            throw PaymentProcessingError.userCancelled
        @unknown default:
            throw PaymentProcessingError.unexpectedPurchaseResult
        }
    }

    func observeTransactions(_ handler: @escaping @MainActor (VerifiedPurchase) async -> Void) {
        guard transactionUpdatesTask == nil else { return }

        transactionUpdatesTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self.verifiedTransaction(from: result)
                    }
                    let purchase = VerifiedPurchase(
                        productID: transaction.productID,
                        transactionID: transaction.id,
                        purchasedAt: transaction.purchaseDate
                    )
                    await handler(purchase)
                    await transaction.finish()
                    print("[payments] transaction update handled product=\(transaction.productID) tx=\(transaction.id)")
                } catch {
                    print("[payments] transaction update ignored: \(error.localizedDescription)")
                }
            }
        }
    }

    private func verifiedTransaction(
        from result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let error):
            throw PaymentProcessingError.unverified(error.localizedDescription)
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }
}
