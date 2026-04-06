//
//  RemoteImageRepository.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation
import UIKit

protocol RemoteImageRepository {
    func fetchImage(from url: URL) async throws -> UIImage
}
