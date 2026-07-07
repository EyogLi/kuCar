import SwiftUI
import PhotosUI

@MainActor
@Observable
final class CameraImportViewModel {
    var selectedImage: UIImage?
    var selectedImageData: Data?
    var imageSource: PhotoSource?
    var isShowingCamera = false
    var isShowingPhotoPicker = false
    var isShowingSourcePicker = false
    var cameraPermissionGranted = false
    var photoPermissionGranted = false
    var error: String?

    private let photoLibraryManager: PhotoLibraryManager
    private let permissionsManager: PermissionsManager

    init(photoLibraryManager: PhotoLibraryManager, permissionsManager: PermissionsManager) {
        self.photoLibraryManager = photoLibraryManager
        self.permissionsManager = permissionsManager
    }

    // MARK: - Actions

    func showImageSourcePicker() {
        isShowingSourcePicker = true
    }

    func selectCamera() async {
        let granted = await permissionsManager.requestCameraPermission()
        cameraPermissionGranted = granted
        if granted {
            isShowingCamera = true
            imageSource = .camera
        } else {
            error = "请在设置中允许kuCar访问相机"
        }
    }

    func selectPhotoLibrary() async {
        let granted = await permissionsManager.requestPhotoLibraryPermission()
        photoPermissionGranted = granted
        if granted {
            isShowingPhotoPicker = true
            imageSource = .photoLibrary
        } else {
            error = "请在设置中允许kuCar访问相册"
        }
    }

    func openSettings() {
        permissionsManager.openAppSettings()
    }

    func handlePickedPhoto(_ result: PHPickerResult) async {
        await photoLibraryManager.processPickerResult(result)
        if let data = photoLibraryManager.selectedImageData, let image = photoLibraryManager.selectedImage {
            selectedImageData = data
            selectedImage = image
        } else {
            error = photoLibraryManager.error
        }
    }

    func handleCameraPhoto(_ image: UIImage) {
        selectedImage = image
        selectedImageData = photoLibraryManager.compressForProcessing(image)
        isShowingCamera = false
    }

    func reset() {
        selectedImage = nil
        selectedImageData = nil
        imageSource = nil
        error = nil
    }
}
