//
//  SampleImageFeedRepository.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

struct SampleImageFeedRepository: ImageFeedRepository {
    func fetchImageItems() async throws -> [ImageItem] {
        [
            ImageItem(
                title: "Forest Waterfall",
                subtitle: "Remote image loaded with Swift Concurrency",
                imageURL: URL(string: "https://picsum.photos/id/10/240/240")!
            ),
            ImageItem(
                title: "Calm Lake",
                subtitle: "Presentation layer owns request lifecycle",
                imageURL: URL(string: "https://picsum.photos/id/20/240/240")!
            ),
            ImageItem(
                title: "Mountain Road",
                subtitle: "Domain layer exposes intent through use cases",
                imageURL: URL(string: "https://picsum.photos/id/30/240/240")!
            ),
            ImageItem(
                title: "Foggy Forest",
                subtitle: "Data layer hides URLSession details",
                imageURL: URL(string: "https://picsum.photos/id/40/240/240")!
            ),
            ImageItem(
                title: "Desert Horizon",
                subtitle: "Each row can cancel its own loading task",
                imageURL: URL(string: "https://picsum.photos/id/50/240/240")!
            ),
        ]
    }
}
