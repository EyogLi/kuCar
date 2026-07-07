import SwiftUI
import PhotosUI

struct CameraImportView: View {
    @EnvironmentObject private var container: AppContainer
    @Binding var navigationPath: NavigationPath

    @State private var viewModel: CameraImportViewModel?
    @State private var selectedPickerItem: PhotosPickerItem?

    var body: some View {
        Group {
            if let vm = viewModel, let image = vm.selectedImage {
                // Show preview of selected image before proceeding
                imagePreviewView(vm, image: image)
            } else {
                // Show source picker
                sourceSelectionView
            }
        }
        .navigationTitle("导入照片")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("选择图片来源", isPresented: .init(
            get: { viewModel?.isShowingSourcePicker ?? false },
            set: { _ in }
        )) {
            Button("拍照") {
                Task { await viewModel?.selectCamera() }
            }
            Button("从相册选择") {
                Task { await viewModel?.selectPhotoLibrary() }
            }
            Button("取消", role: .cancel) {}
        }
        .alert("权限提示", isPresented: .init(
            get: { viewModel?.error != nil },
            set: { _ in viewModel?.reset() }
        )) {
            Button("去设置") { viewModel?.openSettings() }
            Button("取消", role: .cancel) {}
        } message: {
            Text(viewModel?.error ?? "")
        }
        .fullScreenCover(isPresented: .init(
            get: { viewModel?.isShowingCamera ?? false },
            set: { _ in }
        )) {
            CameraCaptureView { image in
                viewModel?.handleCameraPhoto(image)
            }
            .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: .init(
                get: { viewModel?.isShowingPhotoPicker ?? false },
                set: { _ in }
            ),
            selection: $selectedPickerItem,
            matching: .images
        )
        .onChange(of: selectedPickerItem) { _, item in
            guard let item else { return }
            Task {
                await viewModel?.handlePickedPhoto(item)
                // Navigate to segmentation
                if let source = viewModel?.imageSource {
                    navigationPath.append(AppScreen.segmentationReview(source))
                }
            }
        }
        .task {
            let vm = container.makeCameraImportViewModel()
            viewModel = vm
        }
    }

    // MARK: - Source Selection View

    private var sourceSelectionView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "car.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("选择车辆照片")
                .font(.title2.bold())

            Text("拍摄一张照片或从相册中选择\n支持任意车型，AI将自动识别车身面板")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                Button {
                    Task { await viewModel?.selectCamera() }
                } label: {
                    Label("拍照", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    Task { await viewModel?.selectPhotoLibrary() }
                } label: {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Image Preview View

    private func imagePreviewView(_ vm: CameraImportViewModel, image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

            Text("确认使用此照片？")
                .font(.headline)

            HStack(spacing: 20) {
                Button(role: .destructive) {
                    vm.reset()
                } label: {
                    Label("重新选择", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    if let source = vm.imageSource {
                        navigationPath.append(AppScreen.segmentationReview(source))
                    }
                } label: {
                    Label("继续", systemImage: "arrow.right")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 16)
        }
        .padding()
    }
}

// MARK: - Camera Capture View

struct CameraCaptureView: UIViewControllerRepresentable {
    let onPhotoCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPhotoCaptured: onPhotoCaptured)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPhotoCaptured: (UIImage) -> Void

        init(onPhotoCaptured: @escaping (UIImage) -> Void) {
            self.onPhotoCaptured = onPhotoCaptured
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onPhotoCaptured(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        CameraImportView(navigationPath: .constant(NavigationPath()))
            .environmentObject(AppContainer())
    }
}
