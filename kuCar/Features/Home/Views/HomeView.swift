import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var viewModel: HomeViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero section
                heroSection

                // Quick actions
                quickActionsSection

                // Recent projects
                if let vm = viewModel, !vm.recentProjects.isEmpty {
                    recentProjectsSection(vm)
                }

                // Built-in cars carousel
                if let vm = viewModel, !vm.popularCars.isEmpty {
                    builtInCarsSection(vm)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("kuCar")
        .navigationBarTitleDisplayMode(.large)
        .task {
            let vm = container.makeHomeViewModel()
            viewModel = vm
            await vm.loadData()
        }
        .refreshable {
            await viewModel?.loadData()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 20)

            Text("模拟改色 & 换轮毂")
                .font(.title2.bold())

            Text("为你的爱车或任何车型，实时预览改色膜和轮毂效果")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            NavigationLink(value: AppScreen.cameraImport) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("开始新方案")
                            .font(.headline)
                        Text("拍摄或选择车辆照片")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            }
            .buttonStyle(.plain)

            NavigationLink(value: AppScreen.projectBrowser) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("我的方案")
                            .font(.headline)
                        Text("浏览和管理已保存的方案")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    // MARK: - Recent Projects

    private func recentProjectsSection(_ vm: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近方案")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.recentProjects) { project in
                        NavigationLink(value: AppScreen.projectDetail(project)) {
                            RecentProjectCard(project: project)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await vm.deleteProject(project) }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Built-in Cars

    private func builtInCarsSection(_ vm: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门车型")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.popularCars) { car in
                        NavigationLink(value: AppScreen.segmentationReview(.builtInCar(car.id))) {
                            BuiltInCarCard(car: car)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Recent Project Card

struct RecentProjectCard: View {
    let project: UserProject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                }
            }
            .frame(width: 140, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(project.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)

            Text(project.modifiedDate, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
    }
}

// MARK: - Built-in Car Card

struct BuiltInCarCard: View {
    let car: CarCatalogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Car image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.15), .purple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 110)
                .overlay {
                    VStack(spacing: 4) {
                        Image(systemName: "car.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text(car.displayName)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(car.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(car.bodyStyle.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 160)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppContainer())
    }
}
