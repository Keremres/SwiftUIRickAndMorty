//
//  SwiftUIRickAndMortyApp.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import SwiftUI

@main
struct SwiftUIRickAndMortyApp: App {
    var body: some Scene {
        WindowGroup {
            CharacterListView(
                viewModel: CharacterListViewModel(
                    networkManager: NetworkManager(),
                    cacheManager: CacheManager(),
                    imageDownloadManager: ImageDownloaderManager(),
                    coreDataManager: CoreDataManager()))
        }
    }
}
