import UIKit
import AVFoundation
import Photos

/// Manages camera and photo library permissions.
@MainActor
final class PermissionsManager: ObservableObject {

    @Published var cameraPermissionGranted = false
    @Published var photoLibraryPermissionGranted = false

    /// Request camera access permission.
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            cameraPermissionGranted = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermissionGranted = granted
            return granted
        case .denied, .restricted:
            cameraPermissionGranted = false
            return false
        @unknown default:
            return false
        }
    }

    /// Request photo library access permission.
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            photoLibraryPermissionGranted = true
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            photoLibraryPermissionGranted = (newStatus == .authorized || newStatus == .limited)
            return photoLibraryPermissionGranted
        case .denied, .restricted:
            photoLibraryPermissionGranted = false
            return false
        @unknown default:
            return false
        }
    }

    /// Open the app's Settings page if permission was denied.
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
