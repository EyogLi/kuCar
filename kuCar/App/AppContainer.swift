import SwiftUI
import SwiftData

/// Manual dependency injection container.
/// All services are created lazily and shared across the app.
@MainActor
final class AppContainer: ObservableObject {

    // MARK: - SwiftData

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    // MARK: - Services (lazy singletons)

    lazy var segmentationService: SegmentationServiceProtocol = CarSegmentationService()
    lazy var wheelDetectionService: WheelDetectionServiceProtocol = WheelDetectionService()
    lazy var colorizationService: ColorizationServiceProtocol = ColorizationService()
    lazy var wheelOverlayService: WheelOverlayServiceProtocol = WheelOverlayService()
    lazy var projectRepository: ProjectRepository = ProjectRepository(modelContext: modelContext)
    lazy var carCatalogRepository: CarCatalogRepository = CarCatalogRepository()
    lazy var imageCacheManager: ImageCacheManager = ImageCacheManager()
    lazy var photoLibraryManager: PhotoLibraryManager = PhotoLibraryManager()
    lazy var shareManager: ShareManager = ShareManager()
    lazy var permissionsManager: PermissionsManager = PermissionsManager()

    // MARK: - Init

    init() {
        do {
            let schema = Schema([UserProject.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error.localizedDescription)")
        }
    }

    // MARK: - ViewModel Factories

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(projectRepository: projectRepository, carCatalogRepository: carCatalogRepository)
    }

    func makeCameraImportViewModel() -> CameraImportViewModel {
        CameraImportViewModel(
            photoLibraryManager: photoLibraryManager,
            permissionsManager: permissionsManager
        )
    }

    func makeSegmentationViewModel() -> SegmentationViewModel {
        SegmentationViewModel(
            segmentationService: segmentationService,
            wheelDetectionService: wheelDetectionService,
            imageCacheManager: imageCacheManager
        )
    }

    func makeColorEditorViewModel(segmentedCar: SegmentedCar) -> ColorEditorViewModel {
        ColorEditorViewModel(
            segmentedCar: segmentedCar,
            colorizationService: colorizationService,
            projectRepository: projectRepository
        )
    }

    func makeWheelEditorViewModel(segmentedCar: SegmentedCar) -> WheelEditorViewModel {
        WheelEditorViewModel(
            segmentedCar: segmentedCar,
            wheelDetectionService: wheelDetectionService,
            wheelOverlayService: wheelOverlayService,
            projectRepository: projectRepository
        )
    }

    func makeExportViewModel(editedCar: SegmentedCar) -> ExportViewModel {
        ExportViewModel(editedCar: editedCar, shareManager: shareManager)
    }

    func makeProjectBrowserViewModel() -> ProjectBrowserViewModel {
        ProjectBrowserViewModel(projectRepository: projectRepository)
    }
}
