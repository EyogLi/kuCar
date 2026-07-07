import SwiftUI

struct WheelEditorView: View {
    @EnvironmentObject private var container: AppContainer

    let segmentedCar: SegmentedCar
    @Binding var navigationPath: NavigationPath

    @State private var viewModel: WheelEditorViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                editorContent(vm)
            } else {
                ProgressView("正在加载...")
                    .task {
                        viewModel = container.makeWheelEditorViewModel(segmentedCar: segmentedCar)
                    }
            }
        }
        .navigationTitle("换轮毂")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Editor Content

    private func editorContent(_ vm: WheelEditorViewModel) -> some View {
        VStack(spacing: 0) {
            // Image Preview
            imagePreview(vm)

            Divider()

            // Wheel controls
            wheelControls(vm)
        }
    }

    // MARK: - Image Preview

    private func imagePreview(_ vm: WheelEditorViewModel) -> some View {
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
                        .overlay(alignment: .bottomLeading) {
                            // Position indicator
                            wheelPositionIndicators(vm)
                        }
                } else {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .overlay {
                            Image(systemName: "circle.hexagongrid.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                        }
                }
            }
            .padding(8)
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.4)
    }

    private func wheelPositionIndicators(_ vm: WheelEditorViewModel) -> some View {
        HStack {
            ForEach(vm.availablePositions, id: \.self) { position in
                Button {
                    vm.selectedPosition = position
                } label: {
                    Text(position.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            vm.selectedPosition == position
                                ? .blue
                                : .ultraThinMaterial
                        )
                        .foregroundColor(
                            vm.selectedPosition == position ? .white : .primary
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(8)
    }

    // MARK: - Wheel Controls

    private func wheelControls(_ vm: WheelEditorViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Position selector
                positionSelector(vm)

                // Wheel library grid
                wheelLibrary(vm)

                // Fitment adjustments (Phase 3 full feature)
                // For MVP, show basic size selection
                fitmentSelector(vm)

                // Actions
                HStack(spacing: 12) {
                    Button {
                        Task { await vm.applyWheel() }
                    } label: {
                        Label("应用到此轮位", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.selectedWheelStyle == nil || vm.isProcessing)

                    Button {
                        Task { await vm.applyAllWheels() }
                    } label: {
                        Label("应用全部", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .disabled(vm.selectedWheelStyle == nil || vm.isProcessing)
                }

                // Next button
                Button {
                    navigationPath.append(AppScreen.export(segmentedCar))
                } label: {
                    Label("预览并导出", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
    }

    // MARK: - Position Selector

    private func positionSelector(_ vm: WheelEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择轮位")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker("轮位", selection: Binding(
                get: { vm.selectedPosition },
                set: { vm.selectedPosition = $0 }
            )) {
                ForEach(vm.availablePositions, id: \.self) { position in
                    Text(position.displayName).tag(position)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Wheel Library

    private func wheelLibrary(_ vm: WheelEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("轮毂样式")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(vm.availableWheels) { wheel in
                    Button {
                        vm.selectWheel(wheel)
                    } label: {
                        VStack(spacing: 6) {
                            // Wheel icon placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    vm.selectedWheelStyle?.id == wheel.id
                                        ? Color.blue.opacity(0.15)
                                        : Color(.systemGray6)
                                )
                                .frame(height: 70)
                                .overlay {
                                    Image(systemName: "circle.hexagongrid.fill")
                                        .font(.title2)
                                        .foregroundColor(
                                            vm.selectedWheelStyle?.id == wheel.id
                                                ? .blue
                                                : .secondary
                                        )
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            vm.selectedWheelStyle?.id == wheel.id
                                                ? .blue
                                                : .clear,
                                            lineWidth: 2
                                        )
                                )

                            Text(wheel.name)
                                .font(.system(size: 10))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(wheel.category.displayName)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Fitment Selector

    private func fitmentSelector(_ vm: WheelEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("尺寸")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker("直径", selection: Binding(
                get: { vm.fitment.diameter },
                set: { vm.fitment.diameter = $0 }
            )) {
                ForEach([17, 18, 19, 20, 21, 22] as [Float], id: \.self) { size in
                    Text("\(Int(size))\" ").tag(size)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    NavigationStack {
        WheelEditorView(
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
