//
//  AppContainer.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

struct AppContainer {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeImageListViewModel() -> ImageListViewModel {
        let feedRepository = SampleImageFeedRepository()
        let remoteDataSource = URLSessionRemoteImageDataSource(session: session)
        let imageRepository = DefaultRemoteImageRepository(remoteDataSource: remoteDataSource)

        return ImageListViewModel(
            fetchImageListUseCase: FetchImageListUseCase(repository: feedRepository),
            imageRowViewModelFactory: { item in
                ImageRowViewModel(
                    item: item,
                    loadRemoteImageUseCase: LoadRemoteImageUseCase(repository: imageRepository)
                )
            }
        )
    }
}
