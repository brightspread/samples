//
//  ImageListViewModel.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Combine
import Foundation

@MainActor
final class ImageListViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded([ImageRowViewModel])
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    private let fetchImageListUseCase: FetchImageListUseCase
    private let imageRowViewModelFactory: @MainActor (ImageItem) -> ImageRowViewModel
    private var hasLoaded = false

    init(
        fetchImageListUseCase: FetchImageListUseCase,
        imageRowViewModelFactory: @escaping @MainActor (ImageItem) -> ImageRowViewModel
    ) {
        self.fetchImageListUseCase = fetchImageListUseCase
        self.imageRowViewModelFactory = imageRowViewModelFactory
    }

    func load() async {
        guard hasLoaded == false else { return }

        hasLoaded = true
        state = .loading

        do {
            let items = try await fetchImageListUseCase.execute()
            let rows = items.map(imageRowViewModelFactory)
            state = .loaded(rows)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
