import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Vision

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = ShareViewModel(extensionContext: extensionContext)
        let hosting = UIHostingController(rootView: ShareRootView(viewModel: viewModel))

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }
}

@MainActor
final class ShareViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case processing
        case completed
        case failed(String)
    }

    @Published var state: State = .idle

    private weak var extensionContext: NSExtensionContext?

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
    }

    func start() {
        guard state == .idle else { return }
        state = .processing

        Task {
            do {
                let text = try await extractTextFromAttachments()
                SharedCVStore.saveText(text)
                state = .completed
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func openApp() {
        guard let url = URL(string: "jobtrek://share") else { return }
        extensionContext?.open(url, completionHandler: { [weak self] _ in
            Task { @MainActor in
                self?.close()
            }
        })
    }

    func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func extractTextFromAttachments() async throws -> String {
        let providers = extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []

        let imageProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }

        guard !imageProviders.isEmpty else {
            throw ShareError.noImages
        }

        guard imageProviders.count <= 2 else {
            throw ShareError.tooManyImages
        }

        var results: [String] = []
        for provider in imageProviders {
            let image = try await provider.loadImage()
            let text = try await OCRProcessor.recognizeText(in: image)
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                results.append(trimmed)
            }
        }

        let combined = results.joined(separator: "\n")
        if combined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ShareError.noText
        }

        return combined
    }
}

struct ShareRootView: View {
    @ObservedObject var viewModel: ShareViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text(ShareStrings.title)
                .font(.headline)

            Text(ShareStrings.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            switch viewModel.state {
            case .idle, .processing:
                ProgressView()
                Text(ShareStrings.processing)
            case .completed:
                Text(ShareStrings.done)
                HStack {
                    Button(ShareStrings.openApp) {
                        viewModel.openApp()
                    }
                    Button(ShareStrings.close) {
                        viewModel.close()
                    }
                }
            case .failed(let message):
                Text(message)
                    .foregroundStyle(.red)
                Button(ShareStrings.close) {
                    viewModel.close()
                }
            }
        }
        .padding(24)
        .onAppear {
            viewModel.start()
        }
    }
}

enum ShareError: LocalizedError {
    case noImages
    case tooManyImages
    case noText

    var errorDescription: String? {
        switch self {
        case .noImages:
            return ShareStrings.error
        case .tooManyImages:
            return ShareStrings.limit
        case .noText:
            return ShareStrings.error
        }
    }
}

enum OCRProcessor {
    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            return ""
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}

private extension NSItemProvider {
    func loadImage() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            loadObject(ofClass: UIImage.self) { object, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let image = object as? UIImage else {
                    continuation.resume(throwing: ShareError.noImages)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
}
