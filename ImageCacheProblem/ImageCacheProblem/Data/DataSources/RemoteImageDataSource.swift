//
//  RemoteImageDataSource.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

protocol RemoteImageDataSource {
    func fetchImageData(from url: URL) async throws -> Data
}

struct URLSessionRemoteImageDataSource: RemoteImageDataSource {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func fetchImageData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteImageDataSourceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw RemoteImageDataSourceError.httpStatusCode(httpResponse.statusCode)
        }

        guard data.isEmpty == false else {
            throw RemoteImageDataSourceError.emptyData
        }

        return data
    }
}

enum RemoteImageDataSourceError: LocalizedError {
    case invalidResponse
    case httpStatusCode(Int)
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response received from server."
        case let .httpStatusCode(code):
            return "Server returned an unexpected status code: \(code)."
        case .emptyData:
            return "The server returned empty image data."
        }
    }
}
