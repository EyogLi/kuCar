import SwiftUI

struct ExportOptionsView: View {
    @EnvironmentObject private var container: AppContainer

    let editedCar: SegmentedCar
    @Binding var navigationPath: NavigationPath

    @State private var viewModel: ExportViewModel?
    @State private var showShareSheet = false

    var body: some View {
        Group {
            if let vm = viewModel {
                exportContent(vm)
            } else {
                ProgressView("正在准备...")
                    .task {
                        viewModel = container.makeExportViewModel(editedCar: editedCar)
                    }
            }
        }
        .navigationTitle("导出")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let sheet = viewModel?.shareSheet() {
                ShareSheetWrapper(activityViewController: sheet)
            }
        }
    }

    // MARK: - Export Content

    private func exportContent(_ vm: ExportViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview of final result
                if let preview = editedCar.originalImage {
                    Image(decorative: preview, scale: 1.0)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if vm.isExporting {
                                ProgressView("导出中...")
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                }

                // Export options
                VStack(alignment: .leading, spacing: 16) {
                    Text("导出设置")
                        .font(.headline)

                    // Resolution
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分辨率")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("分辨率", selection: Binding(
                            get: { vm.configuration.resolution },
                            set: { vm.configuration.resolution = $0 }
                        )) {
                            ForEach(ExportResolution.allCases, id: \.self) { res in
                                Text(res.rawValue).tag(res)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Format
                    VStack(alignment: .leading, spacing: 8) {
                        Text("格式")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("格式", selection: Binding(
                            get: { vm.configuration.format },
                            set: { vm.configuration.format = $0 }
                        )) {
                            ForEach(ExportFormat.allCases, id: \.self) { fmt in
                                Text(fmt.rawValue).tag(fmt)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Watermark toggle
                    Toggle("添加 AI 水印", isOn: Binding(
                        get: { vm.configuration.includeWatermark },
                        set: { vm.configuration.includeWatermark = $0 }
                    ))
                        .font(.subheadline)

                    // Metadata toggle
                    Toggle("包含元数据标签", isOn: Binding(
                        get: { vm.configuration.includeMetadata },
                        set: { vm.configuration.includeMetadata = $0 }
                    ))
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                // Export button
                Button {
                    Task {
                        await vm.exportImage()
                        showShareSheet = true
                    }
                } label: {
                    if vm.isExporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("导出并分享", systemImage: "square.and.arrow.up")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(vm.isExporting)

                // Back to home
                Button {
                    navigationPath.removeLast(navigationPath.count)
                } label: {
                    Text("返回首页")
                }
                .buttonStyle(.bordered)

                if let error = vm.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Share Sheet Wrapper

struct ShareSheetWrapper: UIViewControllerRepresentable {
    let activityViewController: UIActivityViewController

    func makeUIViewController(context: Context) -> UIActivityViewController {
        activityViewController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ExportOptionsView(
            editedCar: SegmentedCar(
                originalImageData: Data(),
                segmentationResult: SegmentationResult(
                    fullBodyMaskData: Data(),
                    panelMasksData: [:],
                    wheelDetections: [],
                    originalImageSize: .zero
                )
            ),
            navigationPath: .constant(NavigationPath())
        )
        .environmentObject(AppContainer())
    }
}
