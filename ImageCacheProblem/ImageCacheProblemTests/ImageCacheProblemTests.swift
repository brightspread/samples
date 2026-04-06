//
//  ImageCacheProblemTests.swift
//  ImageCacheProblemTests
//
//  Created by leon.jo on 4/6/26.
//

import Foundation
import Testing
import UIKit
@testable import ImageCacheProblem

struct ImageCacheProblemTests {
    @Test
    func sampleImageFeedRepository_mapsPicsumResponseIntoImageItems() async throws {
        let endpoint = try #require(URL(string: "https://example.com/picsum"))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let repository = SampleImageFeedRepository(session: session, endpoint: endpoint, imageSize: 240)
        let responseData = """
        [
          {
            "id": "237",
            "author": "Alejandro Escamilla"
          },
          {
            "id": "100",
            "author": "John Appleseed"
          }
        ]
        """.data(using: .utf8)
        let httpResponse = try #require(
            HTTPURLResponse(
                url: endpoint,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )

        MockURLProtocol.requestHandler = { request in
            #expect(request.url == endpoint)
            return (httpResponse, try #require(responseData))
        }
        defer { MockURLProtocol.requestHandler = nil }

        let items = try await repository.fetchImageItems()

        #expect(items.count == 2)
        #expect(items[0].title == "Alejandro Escamilla")
        #expect(items[0].subtitle == "Picsum Photo #237")
        #expect(items[0].imageURL == URL(string: "https://picsum.photos/id/237/240/240.jpg"))
        #expect(items[1].title == "John Appleseed")
        #expect(items[1].imageURL == URL(string: "https://picsum.photos/id/100/240/240.jpg"))
    }

    @Test
    func fetchImageListUseCase_returnsRepositoryItems() async throws {
        let expectedItems = [
            ImageItem(
                title: "Sample",
                subtitle: "Subtitle",
                imageURL: try #require(URL(string: "https://example.com/image.jpg"))
            )
        ]
        let useCase = FetchImageListUseCase(repository: StubImageFeedRepository(items: expectedItems))

        let items = try await useCase.execute()

        #expect(items == expectedItems)
    }

    @Test
    func remoteImageRepository_whenCacheHit_returnsCachedImageWithoutFetchingRemoteData() async throws {
        let url = try #require(URL(string: "https://example.com/cached.jpg"))
        let cachedImage = makeImage(color: .red)
        let cacheStorage = SpyImageCacheStorage(imageByURL: [url: cachedImage])
        let remoteDataSource = SpyRemoteImageDataSource()
        let repository = DefaultRemoteImageRepository(
            remoteDataSource: remoteDataSource,
            cacheStorage: cacheStorage
        )

        let image = try await repository.fetchImage(from: url)

        #expect(image.pngData() == cachedImage.pngData())
        let fetchedURLs = await remoteDataSource.fetchedURLs
        #expect(fetchedURLs.isEmpty)
        let insertedURLs = await cacheStorage.insertedURLs
        #expect(insertedURLs.isEmpty)
    }

    @Test
    func remoteImageRepository_whenCacheMiss_fetchesRemoteDataAndStoresImage() async throws {
        let url = try #require(URL(string: "https://example.com/remote.jpg"))
        let remoteImage = makeImage(color: .blue)
        let cacheStorage = SpyImageCacheStorage()
        let remoteDataSource = SpyRemoteImageDataSource(data: try #require(remoteImage.pngData()))
        let repository = DefaultRemoteImageRepository(
            remoteDataSource: remoteDataSource,
            cacheStorage: cacheStorage
        )

        let image = try await repository.fetchImage(from: url)

        #expect(image.size == remoteImage.size)
        let fetchedURLs = await remoteDataSource.fetchedURLs
        #expect(fetchedURLs == [url])
        let insertedURLs = await cacheStorage.insertedURLs
        #expect(insertedURLs == [url])
        let insertedImage = await cacheStorage.image(for: url)
        #expect(insertedImage != nil)
        #expect(insertedImage?.size == remoteImage.size)
    }

    @Test
    func remoteImageRepository_whenRemoteDataIsInvalid_throwsErrorWithoutCaching() async throws {
        let url = try #require(URL(string: "https://example.com/invalid.jpg"))
        let cacheStorage = SpyImageCacheStorage()
        let remoteDataSource = SpyRemoteImageDataSource(data: Data([0x00, 0x01, 0x02]))
        let repository = DefaultRemoteImageRepository(
            remoteDataSource: remoteDataSource,
            cacheStorage: cacheStorage
        )

        await #expect(throws: DefaultRemoteImageRepositoryError.invalidImageData) {
            _ = try await repository.fetchImage(from: url)
        }

        let insertedURLs = await cacheStorage.insertedURLs
        #expect(insertedURLs.isEmpty)
    }

    private func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}

private struct StubImageFeedRepository: ImageFeedRepository {
    let items: [ImageItem]

    func fetchImageItems() async throws -> [ImageItem] {
        items
    }
}

private actor SpyImageCacheStorage: ImageCacheStorage {
    private var imageByURL: [URL: UIImage]
    private(set) var insertedURLs: [URL] = []

    init(imageByURL: [URL: UIImage] = [:]) {
        self.imageByURL = imageByURL
    }

    func image(for url: URL) async -> UIImage? {
        imageByURL[url]
    }

    func insert(_ image: UIImage, for url: URL) async {
        imageByURL[url] = image
        insertedURLs.append(url)
    }

    func removeImage(for url: URL) async {
        imageByURL[url] = nil
    }

    func removeAll() async {
        imageByURL.removeAll()
    }
}

private actor SpyRemoteImageDataSource: RemoteImageDataSource {
    private let data: Data
    private(set) var fetchedURLs: [URL] = []

    init(data: Data = Data()) {
        self.data = data
    }

    func fetchImageData(from url: URL) async throws -> Data {
        fetchedURLs.append(url)
        return data
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
