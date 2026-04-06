//
//  ImageCacheProblemTests.swift
//  ImageCacheProblemTests
//
//  Created by leon.jo on 4/6/26.
//

import Foundation
import Testing
@testable import ImageCacheProblem

struct ImageCacheProblemTests {

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
}

private struct StubImageFeedRepository: ImageFeedRepository {
    let items: [ImageItem]

    func fetchImageItems() async throws -> [ImageItem] {
        items
    }
}
