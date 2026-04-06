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

@MainActor
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
    func insert_whenSameURLIsInserted_replacesExistingImage() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)
        let url = try #require(URL(string: "https://example.com/a.png"))
        let firstImage = makeImage(color: .red)
        let secondImage = makeImage(color: .blue)

        await storage.insert(firstImage, for: url)
        await storage.insert(secondImage, for: url)

        let cachedImage = await storage.image(for: url)

        #expect(cachedImage?.pngData() == secondImage.pngData())
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
    func insert_whenSameURLIsReinserted_doesNotIncreaseLogicalCacheCount() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)
        let firstURL = try #require(URL(string: "https://example.com/1.png"))
        let secondURL = try #require(URL(string: "https://example.com/2.png"))
        let thirdURL = try #require(URL(string: "https://example.com/3.png"))

        await storage.insert(makeImage(color: .red), for: firstURL)
        await storage.insert(makeImage(color: .green), for: secondURL)
        await storage.insert(makeImage(color: .blue), for: secondURL)
        await storage.insert(makeImage(color: .black), for: thirdURL)

        #expect(await storage.image(for: firstURL) == nil)
        #expect(await storage.image(for: secondURL) != nil)
        #expect(await storage.image(for: thirdURL) != nil)
    }

    @Test
    func removeImage_removesStoredImageForURL() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)
        let url = try #require(URL(string: "https://example.com/a.png"))

        await storage.insert(makeImage(color: .red), for: url)
        await storage.removeImage(for: url)

        #expect(await storage.image(for: url) == nil)
    }

    @Test
    func removeImage_whenURLDoesNotExist_keepsStorageStable() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)
        let storedURL = try #require(URL(string: "https://example.com/a.png"))
        let missingURL = try #require(URL(string: "https://example.com/missing.png"))
        let expectedImage = makeImage(color: .red)

        await storage.insert(expectedImage, for: storedURL)
        await storage.removeImage(for: missingURL)

        let cachedImage = await storage.image(for: storedURL)
        #expect(cachedImage?.pngData() == expectedImage.pngData())
    }

    @Test
    func removeAll_removesEveryStoredImage() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 3)
        let firstURL = try #require(URL(string: "https://example.com/1.png"))
        let secondURL = try #require(URL(string: "https://example.com/2.png"))

        await storage.insert(makeImage(color: .red), for: firstURL)
        await storage.insert(makeImage(color: .blue), for: secondURL)
        await storage.removeAll()

        #expect(await storage.image(for: firstURL) == nil)
        #expect(await storage.image(for: secondURL) == nil)
    }

    @Test
    func init_whenCapacityIsZero_usesMinimumCapacityOfOne() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 0)
        let firstURL = try #require(URL(string: "https://example.com/1.png"))
        let secondURL = try #require(URL(string: "https://example.com/2.png"))

        await storage.insert(makeImage(color: .red), for: firstURL)
        await storage.insert(makeImage(color: .blue), for: secondURL)

        #expect(await storage.image(for: firstURL) == nil)
        #expect(await storage.image(for: secondURL) != nil)
    }

    @Test
    func concurrentInsertions_keepStoredImageCountWithinCapacity() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 3)
        let urls = try (0..<10).map { index in
            try #require(URL(string: "https://example.com/\(index).png"))
        }

        await withTaskGroup(of: Void.self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    await storage.insert(self.makeImage(color: self.color(for: index)), for: url)
                }
            }
        }

        var storedCount = 0
        for url in urls {
            if await storage.image(for: url) != nil {
                storedCount += 1
            }
        }

        #expect(storedCount <= 3)
    }

    @Test
    func concurrentReadsAndWrites_forSameURL_keepCacheConsistent() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 2)
        let url = try #require(URL(string: "https://example.com/shared.png"))
        let insertedImages = [
            makeImage(color: .red),
            makeImage(color: .blue),
            makeImage(color: .green),
            makeImage(color: .black)
        ]

        await withTaskGroup(of: Void.self) { group in
            for image in insertedImages {
                group.addTask {
                    await storage.insert(image, for: url)
                }

                group.addTask {
                    _ = await storage.image(for: url)
                }
            }
        }

        let cachedImage = await storage.image(for: url)

        #expect(cachedImage != nil)
        #expect(
            insertedImages.contains { image in
                cachedImage?.pngData() == image.pngData()
            }
        )
    }

    @Test
    func concurrentInsertionsAndRemovals_doNotLeaveRemovedURLAccessible() async throws {
        let storage = ImageMemoryCacheStorage(maxCacheCount: 5)
        let keptURL = try #require(URL(string: "https://example.com/kept.png"))
        let removedURL = try #require(URL(string: "https://example.com/removed.png"))

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for _ in 0..<10 {
                    await storage.insert(self.makeImage(color: .red), for: keptURL)
                }
            }

            group.addTask {
                for _ in 0..<10 {
                    await storage.insert(self.makeImage(color: .blue), for: removedURL)
                    await storage.removeImage(for: removedURL)
                }
            }
        }

        #expect(await storage.image(for: keptURL) != nil)
        #expect(await storage.image(for: removedURL) == nil)
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

    private func color(for index: Int) -> UIColor {
        switch index % 6 {
        case 0: return .red
        case 1: return .blue
        case 2: return .green
        case 3: return .black
        case 4: return .orange
        default: return .purple
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
