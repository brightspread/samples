//
//  ImageRowView.swift
//  ImageCacheProblem
//
//  Created by leon.jo on 4/6/26.
//

import SwiftUI

struct ImageRowView: View {
    @StateObject private var viewModel: ImageRowViewModel

    init(viewModel: ImageRowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack(spacing: 16) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.title)
                    .font(.headline)

                Text(viewModel.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.imageURL.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .task {
            await viewModel.loadImageIfNeeded()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))

            switch viewModel.phase {
            case .idle, .loading:
                ProgressView()
                    .tint(.secondary)
            case let .loaded(image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            case .failed:
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
