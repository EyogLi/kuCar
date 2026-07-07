import SwiftUI
import CoreImage

@MainActor
@Observable
final class ExportViewModel {
    var editedCar: SegmentedCar
    var configuration: ExportConfiguration = .default
    var isExporting = false
    var exportedFileURL: URL?
    var error: String?

    private let shareManager: ShareManager

    init(editedCar: SegmentedCar, shareManager: ShareManager) {
        self.editedCar = editedCar
        self.shareManager = shareManager
    }

    // MARK: - Export

    func exportImage() async {
        guard let previewImage = renderFinalImage() else {
            error = "无法生成最终图像"
            return
        }

        isExporting = true
        error = nil

        do {
            exportedFileURL = try await shareManager.exportImage(previewImage, configuration: configuration)
        } catch {
            self.error = error.localizedDescription
        }

        isExporting = false
    }

    func shareSheet() -> UIActivityViewController? {
        guard let url = exportedFileURL else { return nil }
        return shareManager.shareSheet(for: url)
    }

    // MARK: - Private

    private func renderFinalImage() -> CGImage? {
        // In MVP, the previewImage from the editor is the final result.
        // In later phases, this method builds a full composite from segmentedCar state.
        editedCar.originalImage
    }
}
