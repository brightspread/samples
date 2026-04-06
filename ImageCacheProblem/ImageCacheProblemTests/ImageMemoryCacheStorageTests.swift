//
//  ImageMemoryCacheStorageTests.swift
//  ImageCacheProblemTests
//
//  Created by leon.jo on 4/6/26.
//

import Foundation
import Testing
import UIKit
@testable import ImageCacheProblem

struct ImageMemoryCacheStorageTests {

    @Test
    func image_forMissingURL_returnsNil() async {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)

        let image = await storage.image(for: URL(fileURLWithPath: "/missing"))

        #expect(image == nil)
    }

    @Test
    func insert_storesImageForURL() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)
        let url = try #require(URL(string: "https://example.com/a.png"))
        let expectedImage = makeImage(color: .red)

        await storage.insert(expectedImage, for: url)

        let cachedImage = await storage.image(for: url)

        #expect(cachedImage?.pngData() == expectedImage.pngData())
    }

    @Test
    func insert_whenCapacityExceeded_removesLeastRecentlyUsedImage() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)
        let firstURL = try #require(URL(string: "https://example.com/1.png"))
        let secondURL = try #require(URL(string: "https://example.com/2.png"))
        let thirdURL = try #require(URL(string: "https://example.com/3.png"))

        await storage.insert(makeImage(color: .red), for: firstURL)
        await storage.insert(makeImage(color: .green), for: secondURL)
        await storage.insert(makeImage(color: .blue), for: thirdURL)

        #expect(await storage.image(for: firstURL) == nil)
        #expect(await storage.image(for: secondURL) != nil)
        #expect(await storage.image(for: thirdURL) != nil)
    }

    @Test
    func image_whenAccessed_updatesRecentUsageOrder() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)
        let firstURL = try #require(URL(string: "https://example.com/1.png"))
        let secondURL = try #require(URL(string: "https://example.com/2.png"))
        let thirdURL = try #require(URL(string: "https://example.com/3.png"))

        await storage.insert(makeImage(color: .red), for: firstURL)
        await storage.insert(makeImage(color: .green), for: secondURL)
        _ = await storage.image(for: firstURL)
        await storage.insert(makeImage(color: .blue), for: thirdURL)

        #expect(await storage.image(for: firstURL) != nil)
        #expect(await storage.image(for: secondURL) == nil)
        #expect(await storage.image(for: thirdURL) != nil)
    }

    @Test
    func loadRemoteImageUseCase_returnsRepositoryImage() async throws {
        let expectedImage = makeImage(color: .red)
        let useCase = LoadRemoteImageUseCase(
            repository: StubRemoteImageRepository(
                result: .success(expectedImage)
            )
        )

        let image = try await useCase.execute(url: try #require(URL(string: "https://example.com/image.jpg")))

        #expect(image.pngData() == expectedImage.pngData())
    }

    @MainActor
    @Test
    func imageRowViewModel_loadImageIfNeeded_setsLoadedPhase() async throws {
        let image = makeImage(color: .red)
        let viewModel = ImageRowViewModel(
            item: ImageItem(
                title: "Title",
                subtitle: "Subtitle",
                imageURL: try #require(URL(string: "https://example.com/image.jpg"))
            ),
            loadRemoteImageUseCase: LoadRemoteImageUseCase(
                repository: StubRemoteImageRepository(
                    result: .success(image)
                )
            )
        )

        await viewModel.loadImageIfNeeded()
        await Task.yield()

        guard case let .loaded(loadedImage) = viewModel.phase else {
            Issue.record("Expected loaded phase")
            return
        }

        #expect(loadedImage.pngData() == image.pngData())
    }

    @MainActor
    @Test
    func imageRowViewModel_whenCancelled_returnsToIdle() async throws {
        let repository = DelayedRemoteImageRepository()
        let viewModel = ImageRowViewModel(
            item: ImageItem(
                title: "Title",
                subtitle: "Subtitle",
                imageURL: try #require(URL(string: "https://example.com/image.jpg"))
            ),
            loadRemoteImageUseCase: LoadRemoteImageUseCase(repository: repository)
        )

        await viewModel.loadImageIfNeeded()
        viewModel.cancelLoading()
        await Task.yield()
        await Task.yield()

        #expect(viewModel.phase == .idle)
    }

    private func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}

private struct StubRemoteImageRepository: RemoteImageRepository {
    let result: Result<UIImage, Error>

    func fetchImage(from url: URL) async throws -> UIImage {
        try result.get()
    }
}

private actor DelayedRemoteImageRepository: RemoteImageRepository {
    func fetchImage(from url: URL) async throws -> UIImage {
        try await Task.sleep(for: .milliseconds(200))
        return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
