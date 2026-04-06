//
//  DefaultRemoteImageRepository.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation
import UIKit

struct DefaultRemoteImageRepository: RemoteImageRepository {
    private let remoteDataSource: RemoteImageDataSource
    private let cacheStorage: ImageCacheStorage

    init(
        remoteDataSource: RemoteImageDataSource,
        cacheStorage: ImageCacheStorage
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheStorage = cacheStorage
    }

    func fetchImage(from url: URL) async throws -> UIImage {
        if let cachedImage = await cacheStorage.image(for: url) {
            return cachedImage
        }

        let data = try await remoteDataSource.fetchImageData(from: url)

        guard let image = UIImage(data: data) else {
            throw DefaultRemoteImageRepositoryError.invalidImageData
        }

        await cacheStorage.insert(image, for: url)
        return image
    }
}

enum DefaultRemoteImageRepositoryError: LocalizedError {
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The downloaded data could not be decoded into an image."
        }
    }
}
