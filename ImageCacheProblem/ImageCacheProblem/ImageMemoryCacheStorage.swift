//
//  ImageMemoryCacheStorage.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation
import UIKit

protocol ImageCacheStorage: AnyObject {
    func image(for url: URL) async -> UIImage?
    func insert(_ image: UIImage, for url: URL) async
    func removeImage(for url: URL) async
    func removeAll() async
}

actor ImageMemoryCacheStorage: ImageCacheStorage {
    nonisolated(unsafe) private let cache: NSCache<NSURL, UIImage>
    private var accessOrder: [URL] = []

    private let maxCacheCount: Int

    init(maxCacheCount: Int = 100) {
        self.maxCacheCount = max(maxCacheCount, 1)
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = self.maxCacheCount
        self.cache = cache
    }

    func image(for url: URL) async -> UIImage? {
        guard let image = cache.object(forKey: url as NSURL) else {
            return nil
        }

        markAsRecentlyUsed(url)
        return image
    }

    func insert(_ image: UIImage, for url: URL) async {
        cache.setObject(image, forKey: url as NSURL)
        markAsRecentlyUsed(url)
        evictIfNeeded()
    }

    func removeImage(for url: URL) async {
        cache.removeObject(forKey: url as NSURL)
        accessOrder.removeAll { $0 == url }
    }

    func removeAll() async {
        cache.removeAllObjects()
        accessOrder.removeAll()
    }

    private func markAsRecentlyUsed(_ url: URL) {
        accessOrder.removeAll { $0 == url }
        accessOrder.append(url)
    }

    private func evictIfNeeded() {
        while accessOrder.count > maxCacheCount {
            let leastRecentlyUsedURL = accessOrder.removeFirst()
            cache.removeObject(forKey: leastRecentlyUsedURL as NSURL)
        }
    }
}
