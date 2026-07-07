import Foundation
import SwiftData

/// Repository for persisting and retrieving user projects via SwiftData.
@MainActor
final class ProjectRepository: ProjectStorageProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func saveProject(_ project: UserProject) async throws {
        modelContext.insert(project)
        project.modifiedDate = Date()
        try modelContext.save()
    }

    func loadProject(id: UUID) async throws -> UserProject? {
        let predicate = #Predicate<UserProject> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func deleteProject(_ project: UserProject) async throws {
        modelContext.delete(project)
        try modelContext.save()
    }

    func fetchAllProjects() async throws -> [UserProject] {
        let sort = SortDescriptor(\UserProject.modifiedDate, order: .reverse)
        let descriptor = FetchDescriptor(sortBy: [sort])
        return try modelContext.fetch(descriptor)
    }

    func duplicateProject(_ project: UserProject) async throws -> UserProject {
        let copy = UserProject(
            name: "\(project.name) (副本)",
            thumbnailData: project.thumbnailData,
            segmentedCarData: project.segmentedCarData,
            isBuiltInCar: project.isBuiltInCar,
            builtInCarID: project.builtInCarID
        )
        try await saveProject(copy)
        return copy
    }
}
