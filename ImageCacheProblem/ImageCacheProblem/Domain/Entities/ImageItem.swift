//
//  ImageItem.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

struct ImageItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
    let imageURL: URL

    init(id: UUID = UUID(), title: String, subtitle: String, imageURL: URL) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
    }
}
