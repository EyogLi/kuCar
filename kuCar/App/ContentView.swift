import SwiftUI

/// Root navigation router that manages the app's screen flow.
struct ContentView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView()
                .navigationDestination(for: AppScreen.self) { screen in
                    switch screen {
                    case .home:
                        HomeView()
                    case .cameraImport:
                        CameraImportView(navigationPath: $navigationPath)
                    case .segmentationReview(let photoSource):
                        SegmentationProgressView(
                            photoSource: photoSource,
                            navigationPath: $navigationPath
                        )
                    case .colorEditor(let segmentedCar):
                        ColorEditorView(
                            segmentedCar: segmentedCar,
                            navigationPath: $navigationPath
                        )
                    case .wheelEditor(let segmentedCar):
                        WheelEditorView(
                            segmentedCar: segmentedCar,
                            navigationPath: $navigationPath
                        )
                    case .export(let editedCar):
                        ExportOptionsView(
                            editedCar: editedCar,
                            navigationPath: $navigationPath
                        )
                    case .projectBrowser:
                        ProjectBrowserView(navigationPath: $navigationPath)
                    case .projectDetail(let project):
                        ProjectDetailView(project: project, navigationPath: $navigationPath)
                    }
                }
        }
    }
}

// MARK: - Navigation Routes

enum AppScreen: Hashable {
    case home
    case cameraImport
    case segmentationReview(PhotoSource)
    case colorEditor(SegmentedCar)
    case wheelEditor(SegmentedCar)
    case export(SegmentedCar)
    case projectBrowser
    case projectDetail(UserProject)
}

/// Represents where the photo came from.
enum PhotoSource: Hashable {
    case camera
    case photoLibrary
    case builtInCar(String) // car catalog ID
}
