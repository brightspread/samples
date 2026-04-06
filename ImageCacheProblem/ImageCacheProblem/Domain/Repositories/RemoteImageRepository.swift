//
//  RemoteImageRepository.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

protocol RemoteImageRepository {
    func fetchImageData(from url: URL) async throws -> Data
}
