//
//  ImageFeedRepository.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

protocol ImageFeedRepository {
    func fetchImageItems() async throws -> [ImageItem]
}
