//
//  ImageListView.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import SwiftUI

struct ImageListView: View {
    @ObservedObject var viewModel: ImageListViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("이미지 목록을 불러오는 중")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .loaded(rows):
                    List(rows) { rowViewModel in
                        ImageRowView(viewModel: rowViewModel)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                case let .failed(message):
                    ContentUnavailableView(
                        "목록을 불러오지 못했습니다",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
            .navigationTitle("Clean Image Feed")
            .task {
                await viewModel.load()
            }
        }
    }
}

#Preview {
    ImageListView(viewModel: AppContainer().makeImageListViewModel())
}
