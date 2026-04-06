//
//  FetchImageListUseCase.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

struct FetchImageListUseCase {
    private let repository: ImageFeedRepository

    init(repository: ImageFeedRepository) {
        self.repository = repository
    }

    func execute() async throws -> [ImageItem] {
        try await repository.fetchImageItems()
    }
}
