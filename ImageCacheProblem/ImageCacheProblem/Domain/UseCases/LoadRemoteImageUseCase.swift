//
//  LoadRemoteImageUseCase.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation
import UIKit

struct LoadRemoteImageUseCase {
    private let repository: RemoteImageRepository

    init(repository: RemoteImageRepository) {
        self.repository = repository
    }

    func execute(url: URL) async throws -> UIImage {
        try await repository.fetchImage(from: url)
    }
}
