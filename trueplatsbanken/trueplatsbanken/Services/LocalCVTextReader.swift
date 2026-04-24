import Foundation
import PDFKit
import UniformTypeIdentifiers
import UIKit
import Vision

protocol LocalCVTextReading {
    func extractText(from photoData: [Data]) async throws -> String
    func extractText(from urls: [URL]) async throws -> String
}

enum LocalCVTextReaderError: Error {
    case noInput
    case noReadableText
}

final class LocalCVTextReader: LocalCVTextReading {
    func extractText(from photoData: [Data]) async throws -> String {
        guard !photoData.isEmpty else {
            throw LocalCVTextReaderError.noInput
        }

        var results: [String] = []
        for data in photoData {
            if let text = try await OCRTextReader.recognizeText(from: data),
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                results.append(text)
            }
        }

        let combined = results.joined(separator: "\n")
        if combined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw LocalCVTextReaderError.noReadableText
        }

        return combined
    }

    func extractText(from urls: [URL]) async throws -> String {
        guard !urls.isEmpty else {
            throw LocalCVTextReaderError.noInput
        }

        var results: [String] = []
        for url in urls {
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer {
                if needsAccess { url.stopAccessingSecurityScopedResource() }
            }

            if url.conforms(to: .pdf) {
                if let text = PDFTextExtractor.extractText(from: url),
                   !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    results.append(text)
                    continue
                }

                let ocrText = try await PDFTextExtractor.ocrText(from: url)
                if !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    results.append(ocrText)
                }
                continue
            }

            if url.conforms(to: .image) {
                let data = try Data(contentsOf: url)
                if let text = try await OCRTextReader.recognizeText(from: data),
                   !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    results.append(text)
                }
            }
        }

        let combined = results.joined(separator: "\n")
        if combined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw LocalCVTextReaderError.noReadableText
        }

        return combined
    }
}

private enum OCRTextReader {
    static func recognizeText(from data: Data) async throws -> String? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return nil
        }
        return try await recognizeText(in: cgImage)
    }

    static func recognizeText(in cgImage: CGImage) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}

private enum PDFTextExtractor {
    static func extractText(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        return document.string
    }

    static func ocrText(from url: URL) async throws -> String {
        guard let document = PDFDocument(url: url) else { return "" }

        var results: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let thumbnail = page.thumbnail(of: CGSize(width: 1200, height: 1600), for: .mediaBox)
            guard let cgImage = thumbnail.cgImage else { continue }
            let text = try await OCRTextReader.recognizeText(in: cgImage)
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                results.append(text)
            }
        }

        return results.joined(separator: "\n")
    }
}

private extension URL {
    func conforms(to type: UTType) -> Bool {
        if let contentType = try? resourceValues(forKeys: [.contentTypeKey]).contentType {
            return contentType.conforms(to: type)
        }
        guard let utType = UTType(filenameExtension: pathExtension.lowercased()) else { return false }
        return utType.conforms(to: type)
    }
}
