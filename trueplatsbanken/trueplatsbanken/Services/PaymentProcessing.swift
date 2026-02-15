import Foundation

protocol PaymentProcessing {
    func charge(amount: Int, currency: String) async throws
}

struct StubPaymentProcessor: PaymentProcessing {
    func charge(amount: Int, currency: String) async throws {
        try await Task.sleep(nanoseconds: 350_000_000)
    }
}
