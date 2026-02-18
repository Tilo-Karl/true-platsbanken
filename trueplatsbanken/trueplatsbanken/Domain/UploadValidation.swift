import Foundation

enum UploadValidation {
    static let maxUploadBytes = 5 * 1024 * 1024

    static func validatePhotoData(_ dataItems: [Data]) -> String? {
        guard !dataItems.isEmpty else {
            return AppStrings.uploadEmptyError
        }
        for data in dataItems {
            if data.isEmpty {
                return AppStrings.uploadEmptyError
            }
            if data.count > maxUploadBytes {
                return AppStrings.uploadTooLargeError
            }
        }
        return nil
    }

    static func validateFileUrls(_ urls: [URL]) -> String? {
        guard !urls.isEmpty else {
            return AppStrings.uploadEmptyError
        }
        for url in urls {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            guard let size = values?.fileSize, size > 0 else {
                return AppStrings.uploadEmptyError
            }
            if size > maxUploadBytes {
                return AppStrings.uploadTooLargeError
            }
        }
        return nil
    }
}
