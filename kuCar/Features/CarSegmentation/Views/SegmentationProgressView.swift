import SwiftUI

struct SegmentationProgressView: View {
    @EnvironmentObject private var container: AppContainer

    let photoSource: PhotoSource
    @Binding var navigationPath: NavigationPath

    @State private var viewModel: SegmentationViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isProcessing {
                    processingView(vm)
                } else if let error = vm.error {
                    errorView(vm, error: error)
                } else if let car = vm.segmentedCar {
                    resultView(vm, car: car)
                }
            } else {
                ProgressView("正在准备...")
                    .task {
                        await startSegmentation()
                    }
            }
        }
        .navigationTitle("AI识别中")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel?.isProcessing ?? false)
    }

    // MARK: - Processing View

    private func processingView(_ vm: SegmentationViewModel) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated car icon
            Image(systemName: "car.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.opacity(0.5))
                .symbolEffect(.pulse, options: .repeating)

            Text("AI正在识别车身...")
                .font(.headline)

            ProgressView(value: Double(vm.progress))
                .progressViewStyle(.linear)
                .frame(width: 250)
                .tint(.blue)

            Text("正在分析车身面板区域\n全程在设备端处理，不联网")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(_ vm: SegmentationViewModel, error: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("识别失败")
                .font(.title2.bold())

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button("重试") {
                    Task { await startSegmentation() }
                }
                .buttonStyle(.borderedProminent)

                Button("返回") {
                    navigationPath.removeLast()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
    }

    // MARK: - Result View

    private func resultView(_ vm: SegmentationViewModel, car: SegmentedCar) -> some View {
        VStack(spacing: 0) {
            // Preview
            ScrollView {
                VStack(spacing: 16) {
                    Text("识别完成")
                        .font(.headline)
                        .padding(.top)

                    // Show masked preview
                    if let preview = car.originalImage {
                        Image(decorative: preview, scale: 1.0)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    Text("车身面板已自动识别\n你可以开始改色和更换轮毂了")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            // Bottom actions
            VStack(spacing: 12) {
                // Go to Color Editor
                Button {
                    navigationPath.append(AppScreen.colorEditor(car))
                } label: {
                    Label("开始改色", systemImage: "paintpalette.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Go to Wheel Editor
                Button {
                    navigationPath.append(AppScreen.wheelEditor(car))
                } label: {
                    Label("更换轮毂", systemImage: "circle.hexagongrid.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Actions

    private func startSegmentation() async {
        let vm = container.makeSegmentationViewModel()
        viewModel = vm

        switch photoSource {
        case .camera, .photoLibrary:
            // Data should be passed through from CameraImportViewModel
            // For now, this is wired through the environment
            break
        case .builtInCar(let carID):
            // Load built-in car image and segment it
            // In Phase 1, use reference image from catalog
            break
        }
    }
}
