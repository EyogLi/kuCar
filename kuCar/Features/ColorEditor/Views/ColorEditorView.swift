import SwiftUI

struct ColorEditorView: View {
    @EnvironmentObject private var container: AppContainer

    let segmentedCar: SegmentedCar
    @Binding var navigationPath: NavigationPath

    @State private var viewModel: ColorEditorViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                editorContent(vm)
            } else {
                ProgressView("正在加载...")
                    .task {
                        viewModel = container.makeColorEditorViewModel(segmentedCar: segmentedCar)
                    }
            }
        }
        .navigationTitle("改色")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let vm = viewModel {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task { await vm.saveProject() }
                    }
                    .disabled(vm.isSaved)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if vm.canUndo {
                        Button("撤销") {
                            Task { await vm.undo() }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Editor Content

    private func editorContent(_ vm: ColorEditorViewModel) -> some View {
        VStack(spacing: 0) {
            // Image Preview Area
            imagePreviewArea(vm)

            Divider()

            // Editing Controls
            editingControls(vm)
        }
    }

    // MARK: - Image Preview

    private func imagePreviewArea(_ vm: ColorEditorViewModel) -> some View {
        GeometryReader { geometry in
            ZStack {
                if let preview = vm.previewImage {
                    Image(decorative: preview, scale: 1.0)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            if vm.isProcessing {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                } else {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .overlay {
                            Image(systemName: "car.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.45)
    }

    // MARK: - Editing Controls

    private func editingControls(_ vm: ColorEditorViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Panel selection
                panelSelector(vm)

                // Color palette
                colorPalette(vm)

                // Finish selector
                finishSelector(vm)

                // Intensity slider
                intensityControl(vm)

                // Apply button
                Button {
                    Task { await vm.applyColor() }
                } label: {
                    if vm.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("应用改色", systemImage: "checkmark")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(vm.selectedPanels.isEmpty ? .gray : .blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(vm.selectedPanels.isEmpty || vm.isProcessing)

                if let error = vm.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }

    // MARK: - Panel Selector

    private func panelSelector(_ vm: ColorEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择面板")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Button("全选") { vm.selectAllPanels() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("取消") { vm.deselectAllPanels() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CarPanel.allCases, id: \.self) { panel in
                        Button {
                            if vm.selectedPanels.contains(panel) {
                                vm.selectedPanels.remove(panel)
                            } else {
                                vm.selectedPanels.insert(panel)
                            }
                        } label: {
                            Text(panel.displayName)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    vm.selectedPanels.contains(panel)
                                        ? Color.blue
                                        : Color(.systemGray5)
                                )
                                .foregroundColor(
                                    vm.selectedPanels.contains(panel)
                                        ? .white
                                        : .primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Color Palette

    private func colorPalette(_ vm: ColorEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("颜色")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ColorEditorViewModel.availableColors) { color in
                        Button {
                            vm.selectedColor = color
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color.swiftUIColor)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                vm.selectedColor.id == color.id
                                                    ? .blue
                                                    : .clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                                Text(color.name)
                                    .font(.system(size: 10))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .frame(width: 48)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Finish Selector

    private func finishSelector(_ vm: ColorEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("材质")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker("材质", selection: Binding(
                get: { vm.selectedFinish },
                set: { vm.selectedFinish = $0 }
            )) {
                ForEach(vm.availableFinishes, id: \.self) { finish in
                    Text(finish.displayName)
                        .tag(finish)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Intensity Control

    private func intensityControl(_ vm: ColorEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("强度")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(vm.intensity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: Binding(
                get: { Double(vm.intensity) },
                set: { vm.intensity = Float($0) }
            ), in: 0.3...1.0, step: 0.05)
            .tint(.blue)
        }
    }
}

#Preview {
    NavigationStack {
        ColorEditorView(
            segmentedCar: SegmentedCar(
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
