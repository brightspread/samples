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
    func loadRemoteImageUseCase_returnsRepositoryData() async throws {
        let expectedData = Data([0x00, 0x01, 0x02])
        let useCase = LoadRemoteImageUseCase(
            repository: StubRemoteImageRepository(
                result: .success(expectedData)
            )
        )

        let data = try await useCase.execute(url: try #require(URL(string: "https://example.com/image.jpg")))

        #expect(data == expectedData)
    }

    @MainActor
    @Test
    func imageRowViewModel_loadImageIfNeeded_setsLoadedPhase() async throws {
        let image = makeImage()
        let viewModel = ImageRowViewModel(
            item: ImageItem(
                title: "Title",
                subtitle: "Subtitle",
                imageURL: try #require(URL(string: "https://example.com/image.jpg"))
            ),
            loadRemoteImageUseCase: LoadRemoteImageUseCase(
                repository: StubRemoteImageRepository(
                    result: .success(try #require(image.pngData()))
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

    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}

private struct StubRemoteImageRepository: RemoteImageRepository {
    let result: Result<Data, Error>

    func fetchImageData(from url: URL) async throws -> Data {
        try result.get()
    }
}

private actor DelayedRemoteImageRepository: RemoteImageRepository {
    func fetchImageData(from url: URL) async throws -> Data {
        try await Task.sleep(for: .milliseconds(200))
        return Data()
    }
}
