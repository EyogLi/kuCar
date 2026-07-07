import SwiftUI
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var recentProjects: [UserProject] = []
    var popularCars: [CarCatalogEntry] = []
    var isLoading = false
    var error: String?

    private let projectRepository: ProjectRepository
    private let carCatalogRepository: CarCatalogRepository

    init(projectRepository: ProjectRepository, carCatalogRepository: CarCatalogRepository) {
        self.projectRepository = projectRepository
        self.carCatalogRepository = carCatalogRepository
    }

    func loadData() async {
        isLoading = true
        error = nil
        do {
            recentProjects = try await projectRepository.fetchAllProjects()
            popularCars = Array(carCatalogRepository.entries.prefix(6))
        } catch {
            self.error = "加载项目失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func deleteProject(_ project: UserProject) async {
        do {
            try await projectRepository.deleteProject(project)
            recentProjects.removeAll { $0.id == project.id }
        } catch {
            self.error = "删除失败: \(error.localizedDescription)"
        }
    }
}
