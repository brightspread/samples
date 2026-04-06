//
//  DefaultRemoteImageRepository.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

struct DefaultRemoteImageRepository: RemoteImageRepository {
    private let remoteDataSource: RemoteImageDataSource

    init(remoteDataSource: RemoteImageDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchImageData(from url: URL) async throws -> Data {
        try await remoteDataSource.fetchImageData(from: url)
    }
}
