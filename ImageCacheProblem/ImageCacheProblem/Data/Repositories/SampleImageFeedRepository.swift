//
//  SampleImageFeedRepository.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

struct SampleImageFeedRepository: ImageFeedRepository {
    private let session: URLSession
    private let endpoint: URL
    private let imageSize: Int

    init(
        session: URLSession,
        endpoint: URL = URL(string: "https://picsum.photos/v2/list?page=1&limit=12")!,
        imageSize: Int = 240
    ) {
        self.session = session
        self.endpoint = endpoint
        self.imageSize = imageSize
    }

    func fetchImageItems() async throws -> [ImageItem] {
        let (data, response) = try await session.data(from: endpoint)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SampleImageFeedRepositoryError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw SampleImageFeedRepositoryError.httpStatusCode(httpResponse.statusCode)
        }

        let items = try JSONDecoder().decode([PicsumPhotoResponse].self, from: data)
        guard items.isEmpty == false else {
            throw SampleImageFeedRepositoryError.emptyFeed
        }

        return try items.map(makeImageItem)
    }

    private func makeImageItem(from response: PicsumPhotoResponse) throws -> ImageItem {
        guard
            let imageURL = URL(string: "https://picsum.photos/id/\(response.id)/\(imageSize)/\(imageSize).jpg")
        else {
            throw SampleImageFeedRepositoryError.invalidImageURL(response.id)
        }

        return ImageItem(
            title: response.author,
            subtitle: "Picsum Photo #\(response.id)",
            imageURL: imageURL
        )
    }
}

private struct PicsumPhotoResponse: Decodable {
    let id: String
    let author: String
}

enum SampleImageFeedRepositoryError: LocalizedError {
    case invalidResponse
    case httpStatusCode(Int)
    case emptyFeed
    case invalidImageURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Failed to validate the Picsum feed response."
        case let .httpStatusCode(code):
            return "Picsum feed request failed with status code \(code)."
        case .emptyFeed:
            return "Picsum feed returned an empty image list."
        case let .invalidImageURL(id):
            return "Failed to create an image URL for Picsum photo #\(id)."
        }
    }
}
