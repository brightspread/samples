//
//  ImageRowViewModel.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Combine
import Foundation
import UIKit

@MainActor
final class ImageRowViewModel: ObservableObject, Identifiable {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded(UIImage)
        case failed(String)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading):
                return true
            case let (.failed(lhsMessage), .failed(rhsMessage)):
                return lhsMessage == rhsMessage
            case let (.loaded(lhsImage), .loaded(rhsImage)):
                return lhsImage.pngData() == rhsImage.pngData()
            default:
                return false
            }
        }
    }

    let id: UUID
    let title: String
    let subtitle: String
    let imageURL: URL

    @Published private(set) var phase: Phase = .idle

    private let loadRemoteImageUseCase: LoadRemoteImageUseCase
    private var loadTask: Task<Void, Never>?
    private var latestRequestID: UUID?

    init(item: ImageItem, loadRemoteImageUseCase: LoadRemoteImageUseCase) {
        id = item.id
        title = item.title
        subtitle = item.subtitle
        imageURL = item.imageURL
        self.loadRemoteImageUseCase = loadRemoteImageUseCase
    }

    func loadImageIfNeeded() async {
        guard case .idle = phase else { return }
        loadImage()
    }

    func retry() {
        loadImage()
    }

    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        latestRequestID = nil
        phase = .idle
    }

    private func loadImage() {
        cancelLoading()

        let requestID = UUID()
        latestRequestID = requestID
        phase = .loading

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let image = try await self.loadRemoteImageUseCase.execute(url: self.imageURL)
                try Task.checkCancellation()

                guard self.latestRequestID == requestID else { return }

                self.phase = .loaded(image)
            } catch is CancellationError {
                guard self.latestRequestID == requestID else { return }
                self.phase = .idle
            } catch {
                guard self.latestRequestID == requestID else { return }
                self.phase = .failed(error.localizedDescription)
            }
        }
    }
}
