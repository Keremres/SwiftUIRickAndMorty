//
//  CharacterListViewModel.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation
import Combine

enum ViewState: Equatable {
    case idle
    case loading
    case noData
    case showData
    case error(String)
}

final class CharacterListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var viewState: ViewState = .idle
    @Published var searchText: String = ""
    @Published var characterList: [CharacterResult] = []
    @Published var filteredCharacters: [CharacterResult] = []
    @Published var cacheAlert: BasicErrorAlert? = nil
    
    // MARK: - Dependencies
    private let networkManager: NetworkService
    private let cacheManager: CacheService
    private let imageDownloadManager: ImageDownloadService
    private let coreDataManager: CoreDataService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentFetchTask: Task<Void, Never>?
    private var currentImageDownloadTask: Task<Data?, Never>?
    private var perPage = 10
    private var currentPage = 1
    private var totalPageCount = 0
    
    // MARK: - Initialization
    init(
        networkManager: NetworkService,
        cacheManager: CacheService,
        imageDownloadManager: ImageDownloadService,
        coreDataManager: CoreDataService
    ) {
        self.networkManager = networkManager
        self.cacheManager = cacheManager
        self.imageDownloadManager = imageDownloadManager
        self.coreDataManager = coreDataManager
        setupSearchSubscriber()
    }
    
    private func setupSearchSubscriber() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterCharacters(with: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func filterCharacters(with searchText: String) {
        if searchText.isEmpty {
            filteredCharacters = characterList
        } else {
            filteredCharacters = characterList.filter { character in
                character.name?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func cancelCurrentTask() {
        currentFetchTask?.cancel()
        currentFetchTask = nil
    }
    
    private func cancelImageTask() {
        currentImageDownloadTask?.cancel()
        currentImageDownloadTask = nil
    }
    
    deinit {
        cancelCurrentTask()
        cancelImageTask()
    }
}

// MARK: - Network Request Methods
extension CharacterListViewModel {
    func fetchRickAndMorty() {
        cancelCurrentTask()
        
        currentFetchTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            if self.characterList.isEmpty {
                self.viewState = .loading
            }
            
            do {
                try Task.checkCancellation()
                
                let characterResponse: Character = try await networkManager.fetch(
                    with: CharacterEndpoint.getCharacters(page: currentPage)
                )
                
                try Task.checkCancellation()
                
                self.totalPageCount = characterResponse.info.pages
                self.handleNewCharacters(newCharacters: characterResponse.results)
                
                self.viewState = characterList.isEmpty ? .noData : .showData
            } catch {
                if let networkError = error as? NetworkError {
                    self.viewState = .error(networkError.errorDescription)
                }
            }
        }
    }
    
    private func handleNewCharacters(newCharacters: [CharacterResult]) {
        if characterList.isEmpty {
            characterList = newCharacters
        } else {
            newCharacters.forEach { character in
                if !characterList.contains(where: { $0.id == character.id }) {
                    characterList.append(character)
                }
            }
        }
        filterCharacters(with: searchText)
    }
    
    func loadMorePages() {
        guard viewState != .loading,
              currentPage < totalPageCount else {
            return
        }
        
        currentPage += 1
        fetchRickAndMorty()
    }
}

// MARK: - Image Cache Methods
extension CharacterListViewModel {
    func handleImageLoading(for urlString: String) async -> Data? {
        currentImageDownloadTask = Task { @MainActor [weak self] in
            guard let self = self else { return nil }
            
            do {
                try Task.checkCancellation()
                // Cache kontrolü
                if let cachedImage = try? retrieveImageFromCache(urlString) {
                    return cachedImage
                }
                try Task.checkCancellation()
                // CoreData kontrolü
                if let coreDataImage = try fetchImage(for: urlString){
                    try self.cacheImage(coreDataImage, for: urlString)
                    return coreDataImage
                }
                
                try Task.checkCancellation()
                if let downloadedData = try await imageDownloadManager.downloadImage(urlString) {
                    try self.cacheImage(downloadedData, for: urlString)
                    try self.saveImage(downloadedData, for: urlString)
                    try Task.checkCancellation()
                    return downloadedData
                }
            } catch {
                switch error {
                case let error as BasicErrorAlert:
                    self.cacheAlert = error
                default :
                    print("Image download error: \(error.localizedDescription)")
                }
            }
            return nil
        }
        
        return await currentImageDownloadTask?.value
    }
    
    private func cacheImage(_ imageData: Data, for urlString: String) throws {
        try cacheManager.setImageCache(url: urlString.asNSString, data: imageData)
    }
    
    private func retrieveImageFromCache(_ urlString: String) throws -> Data? {
        return try cacheManager.retrieveImageFromCache(with: urlString.asNSString)
    }
}

//MARK: - CoreData
extension CharacterListViewModel {
    private func saveImage(_ imageData: Data, for urlString: String) throws {
        let imageEntity = ImageEntity(context: coreDataManager.context)
        imageEntity.imageData = imageData
        imageEntity.imageUrl = urlString
        try coreDataManager.save()
    }
    
    private func fetchImage(for urlString: String) throws -> Data? {
        let imageEntity = try coreDataManager.fetch(ImageEntity.self, searchLocation: "imageUrl", searchText: urlString)?.first
        return imageEntity?.imageData
    }
    
    private func deleteImage(imageEntity: ImageEntity) throws {
        try coreDataManager.delete(imageEntity: imageEntity)
    }
}
