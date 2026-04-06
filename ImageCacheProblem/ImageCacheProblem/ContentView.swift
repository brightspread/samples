//
//  ContentView.swift
//  ImageCacheProblem
//
//  Created by Leo on 4/6/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ImageListViewModel

    init(viewModel: ImageListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ImageListView(viewModel: viewModel)
    }
}

#Preview {
    ContentView(viewModel: AppContainer().makeImageListViewModel())
}
