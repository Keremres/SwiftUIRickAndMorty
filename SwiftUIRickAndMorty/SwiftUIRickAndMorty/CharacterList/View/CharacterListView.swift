//
//  CharacterListView.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import SwiftUI

struct CharacterListView: View {
    @StateObject private var viewModel: CharacterListViewModel
    
    init(viewModel: CharacterListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Rick and Morty")
                .searchable(text: $viewModel.searchText, prompt: "Search characters")
        }
        .showAlert(alert: $viewModel.cacheAlert) {
            alertButton
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewState {
        case .idle:
            Color.clear.onAppear { viewModel.fetchRickAndMorty()
            }
            
        case .loading:
            if viewModel.filteredCharacters.isEmpty {
                ProgressView()
            }
            
        case .error(let error):
            Text(error)
                .foregroundStyle(Color.red)
            
        case .noData:
            Text("No characters found")
            
        case .showData:
            characterListView
        }
    }
    
    private var characterListView: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.filteredCharacters) { character in
                    CharacterCell(character: character, viewModel: viewModel)
                        .onAppear {
                            if character.id == viewModel.filteredCharacters.last?.id {
                                viewModel.loadMorePages()
                            }
                        }
                        .onChange(of: viewModel.characterList.count) { _, _ in
                            if character.id == viewModel.filteredCharacters.last?.id {
                                viewModel.loadMorePages()
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private var alertButton: some View {
        Button("Cancel", role: .cancel) {}
    }
}

#Preview {
    CharacterListView(viewModel: CharacterListViewModel(networkManager: NetworkManager(),
                                                        cacheManager: CacheManager(),
                                                        imageDownloadManager: ImageDownloaderManager(),
                                                        coreDataManager: CoreDataManager()))
}
