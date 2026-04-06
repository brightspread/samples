//
//  ImageMemoryCacheStorage.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import UIKit

protocol ImageCacheStorage: AnyObject {
    func image(for key: String) -> UIImage?
    func insert(_ image: UIImage, for key: String)
}

final class ImageMemoryCacheStorage: ImageCacheStorage {
    private final class Node {
        let key: String
        var image: UIImage
        var previous: Node?
        var next: Node?

        init(key: String, image: UIImage) {
            self.key = key
            self.image = image
        }
    }

    private let capacity: Int
    private var storage: [String: Node] = [:]
    private var head: Node?
    private var tail: Node?

    init(capacity: Int = 100) {
        self.capacity = max(capacity, 1)
    }

    func image(for key: String) -> UIImage? {
        guard let node = storage[key] else {
            return nil
        }

        moveToHead(node)
        return node.image
    }

    func insert(_ image: UIImage, for key: String) {
        if let node = storage[key] {
            node.image = image
            moveToHead(node)
            return
        }

        let node = Node(key: key, image: image)
        storage[key] = node
        insertAtHead(node)
        removeLeastRecentlyUsedImageIfNeeded()
    }

    private func insertAtHead(_ node: Node) {
        node.previous = nil
        node.next = head
        head?.previous = node
        head = node

        if tail == nil {
            tail = node
        }
    }

    private func moveToHead(_ node: Node) {
        guard head !== node else {
            return
        }

        detach(node)
        insertAtHead(node)
    }

    private func detach(_ node: Node) {
        let previous = node.previous
        let next = node.next

        previous?.next = next
        next?.previous = previous

        if tail === node {
            tail = previous
        }

        if head === node {
            head = next
        }

        node.previous = nil
        node.next = nil
    }

    private func removeLeastRecentlyUsedImageIfNeeded() {
        guard storage.count > capacity, let leastRecentlyUsedNode = tail else {
            return
        }

        detach(leastRecentlyUsedNode)
        storage[leastRecentlyUsedNode.key] = nil
    }
}
