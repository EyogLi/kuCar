import SwiftUI
import Observation

@MainActor
@Observable
final class ProjectBrowserViewModel {
    var projects: [UserProject] = []
    var isLoading = false
    var error: String?

    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func loadProjects() async {
        isLoading = true
        error = nil
        do {
            projects = try await projectRepository.fetchAllProjects()
        } catch {
            self.error = "加载项目失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func deleteProject(_ project: UserProject) async {
        do {
            try await projectRepository.deleteProject(project)
            projects.removeAll { $0.id == project.id }
        } catch {
            self.error = "删除失败: \(error.localizedDescription)"
        }
    }

    func duplicateProject(_ project: UserProject) async {
        do {
            _ = try await projectRepository.duplicateProject(project)
            await loadProjects()
        } catch {
            self.error = "复制失败: \(error.localizedDescription)"
        }
    }
}
