import SwiftUI

struct ProjectBrowserView: View {
    @EnvironmentObject private var container: AppContainer
    @Binding var navigationPath: NavigationPath

    @State private var viewModel: ProjectBrowserViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                projectList(vm)
            } else {
                ProgressView("正在加载...")
                    .task {
                        let vm = container.makeProjectBrowserViewModel()
                        viewModel = vm
                        await vm.loadProjects()
                    }
            }
        }
        .navigationTitle("我的方案")
        .refreshable {
            await viewModel?.loadProjects()
        }
    }

    private func projectList(_ vm: ProjectBrowserViewModel) -> some View {
        Group {
            if vm.isLoading {
                ProgressView("加载中...")
            } else if vm.projects.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(vm.projects) { project in
                        NavigationLink(value: AppScreen.projectDetail(project)) {
                            ProjectRow(project: project)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await vm.deleteProject(project) }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }

                            Button {
                                Task { await vm.duplicateProject(project) }
                            } label: {
                                Label("复制", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }

            if let error = vm.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("还没有方案")
                .font(.headline)

            Text("开始改色你的第一辆车吧！")
                .font(.subheadline)
                .foregroundColor(.secondary)

            NavigationLink(value: AppScreen.cameraImport) {
                Label("开始新方案", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: UserProject

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let data = project.thumbnailData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "car.fill")
                                .foregroundColor(.secondary)
                        }
                }
            }
            .frame(width: 60, height: 45)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("修改于 \(project.modifiedDate.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Project Detail View

struct ProjectDetailView: View {
    @EnvironmentObject private var container: AppContainer

    let project: UserProject
    @Binding var navigationPath: NavigationPath

    @State private var segmentedCar: SegmentedCar?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Thumbnail
                if let data = project.thumbnailData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                }

                // Project info
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name)
                        .font(.title2.bold())

                    Text("创建于 \(project.createdDate.formatted(date: .long, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Actions
                VStack(spacing: 12) {
                    if let car = segmentedCar {
                        Button {
                            navigationPath.append(AppScreen.colorEditor(car))
                        } label: {
                            Label("继续编辑颜色", systemImage: "paintpalette.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            navigationPath.append(AppScreen.wheelEditor(car))
                        } label: {
                            Label("更换轮毂", systemImage: "circle.hexagongrid.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("方案详情")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Decode SegmentedCar from project data
            let decoder = JSONDecoder()
            if let car = try? decoder.decode(SegmentedCar.self, from: project.segmentedCarData) {
                segmentedCar = car
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectBrowserView(navigationPath: .constant(NavigationPath()))
            .environmentObject(AppContainer())
    }
}
