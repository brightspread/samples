//
//  AppContainer.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import Foundation

struct AppContainer {
    private let session: URLSession
    private let imageCacheStorage: ImageCacheStorage

    init(
        session: URLSession = .shared,
        imageCacheStorage: ImageCacheStorage = ImageMemoryCacheStorage()
    ) {
        self.session = session
        self.imageCacheStorage = imageCacheStorage
    }

    func makeImageListViewModel() -> ImageListViewModel {
        let feedRepository = SampleImageFeedRepository(session: session)
        let remoteDataSource = URLSessionRemoteImageDataSource(session: session)
        let imageRepository = DefaultRemoteImageRepository(
            remoteDataSource: remoteDataSource,
            cacheStorage: imageCacheStorage
        )

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
