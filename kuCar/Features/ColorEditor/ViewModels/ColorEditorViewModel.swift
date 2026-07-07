import SwiftUI
import CoreImage
import Observation

@MainActor
@Observable
final class ColorEditorViewModel {
    var segmentedCar: SegmentedCar
    var selectedPanels: Set<CarPanel> = [.hood, .roof, .trunk, .frontLeftDoor, .frontRightDoor, .rearLeftDoor, .rearRightDoor, .leftFender, .rightFender, .frontBumper, .rearBumper]
    var selectedColor: ColorPreset = .presets[0]
    var selectedFinish: WrapFinish = .gloss
    var intensity: Float = 0.85
    var isProcessing = false
    var previewImage: CGImage?
    var error: String?
    var isSaved = false

    // Undo support
    private var colorHistory: [(panels: Set<CarPanel>, color: ColorPreset, finish: WrapFinish)] = []
    var canUndo: Bool { !colorHistory.isEmpty }

    private let colorizationService: ColorizationServiceProtocol
    private let projectRepository: ProjectRepository

    private var originalCIImage: CIImage?

    init(
        segmentedCar: SegmentedCar,
        colorizationService: ColorizationServiceProtocol,
        projectRepository: ProjectRepository
    ) {
        self.segmentedCar = segmentedCar
        self.colorizationService = colorizationService
        self.projectRepository = projectRepository

        if let cgImage = segmentedCar.originalImage {
            self.originalCIImage = CIImage(cgImage: cgImage)
            self.previewImage = cgImage
        }
    }

    // MARK: - Color Presets

    static var availableColors: [ColorPreset] = ColorPreset.presets

    var availableFinishes: [WrapFinish] {
        [.gloss, .matte, .satin]
    }

    // MARK: - Actions

    func selectAllPanels() {
        selectedPanels = Set(CarPanel.allCases)
    }

    func deselectAllPanels() {
        selectedPanels = []
    }

    func applyColor() async {
        guard !selectedPanels.isEmpty, let originalImage = originalCIImage else { return }

        isProcessing = true
        error = nil

        // Save to undo history
        colorHistory.append((selectedPanels, selectedColor, selectedFinish))

        do {
            // Build combined mask for selected panels
            let combinedMask = buildCombinedMask(for: selectedPanels)

            // Apply colorization
            let renderResult = try await colorizationService.applyColor(
                to: combinedMask,
                originalImage: originalImage,
                color: selectedColor,
                finish: selectedFinish,
                intensity: intensity
            )

            // Generate preview
            let preview = try await colorizationService.generatePreview(
                from: renderResult,
                originalSize: originalImage.extent.size
            )
            previewImage = preview

            // Update segmented car state
            for panel in selectedPanels {
                segmentedCar.appliedColors[panel] = PanelColorApplication(
                    colorPreset: selectedColor,
                    finish: selectedFinish,
                    intensity: intensity
                )
            }

            // Auto-save project
            await saveProject()
        } catch {
            self.error = error.localizedDescription
        }

        isProcessing = false
    }

    func undo() async {
        guard canUndo else { return }
        colorHistory.removeLast()

        // Reset to no colors (in Phase 2, we'd restore previous state)
        segmentedCar.appliedColors = [:]
        previewImage = segmentedCar.originalImage
    }

    func resetAll() {
        segmentedCar.appliedColors = [:]
        colorHistory = []
        previewImage = segmentedCar.originalImage
    }

    // MARK: - Save

    func saveProject() async {
        do {
            // Encode SegmentedCar to JSON
            let encoder = JSONEncoder()
            let data = try encoder.encode(segmentedCar)

            // Create or update UserProject
            let project = UserProject(
                name: "改色方案 \(Date().formatted(date: .abbreviated, time: .shortened))",
                segmentedCarData: data
            )

            // Generate thumbnail from preview
            if let preview = previewImage {
                let uiImage = UIImage(cgImage: preview)
                project.thumbnailData = uiImage.jpegData(compressionQuality: 0.5)
            }

            try await projectRepository.saveProject(project)
            isSaved = true
        } catch {
            self.error = "保存失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func buildCombinedMask(for panels: Set<CarPanel>) -> CIImage {
        let masks = panels.compactMap { segmentedCar.segmentationResult.panelMask(for: $0) }
        guard !masks.isEmpty else {
            return segmentedCar.segmentationResult.fullBodyMask ?? CIImage()
        }

        // Combine masks using maximum compositing (logical OR)
        var combinedMask = masks[0]
        for mask in masks.dropFirst() {
            guard let addFilter = CIFilter(name: "CIAdditionCompositing") else { continue }
            addFilter.setValue(combinedMask, forKey: kCIInputImageKey)
            addFilter.setValue(mask, forKey: kCIInputBackgroundImageKey)
            if let result = addFilter.outputImage {
                combinedMask = result
            }
        }

        // Clamp to 0...1
        return combinedMask
            .applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: 0,
                kCIInputContrastKey: 1
            ])
    }
}

