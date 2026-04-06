//
//  LoadRemoteImageUseCase.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

struct LoadRemoteImageUseCase {
    private let repository: RemoteImageRepository

    init(repository: RemoteImageRepository) {
        self.repository = repository
    }

    func execute(url: URL) async throws -> Data {
        try await repository.fetchImageData(from: url)
    }
}
