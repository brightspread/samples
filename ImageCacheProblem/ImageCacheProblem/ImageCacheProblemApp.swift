//
//  ImageCacheProblemApp.swift
//  ImageCacheProblem
//
//  Created by Leo on 4/6/26.
//

import SwiftUI

@main
struct ImageCacheProblemApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: container.makeImageListViewModel())
        }
    }
}
