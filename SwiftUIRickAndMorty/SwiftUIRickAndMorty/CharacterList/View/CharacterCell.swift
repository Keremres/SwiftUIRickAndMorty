//
//  CharacterCell.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import SwiftUI

struct CharacterCell: View {
    let character: CharacterResult
    @ObservedObject var viewModel: CharacterListViewModel
    @State private var cellImage: Data?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let image = cellImage?.asImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ProgressView()
                        .task {
                            await loadImage()
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name ?? "Unknown")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    StatusView(status: character.status ?? "Unknown")
                    Text("•")
                        .foregroundColor(.gray)
                    Text(character.gender ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private func loadImage() async {
        guard let imageUrlString = character.image else { return }
        if let loadedImage = await viewModel.handleImageLoading(for: imageUrlString) {
            cellImage = loadedImage
        }
    }
}


// MARK: - Status View
struct StatusView: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(status)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "alive":
            return .green
        case "dead":
            return .red
        default:
            return .gray
        }
    }
}



#Preview {
    CharacterCell(character: Character.mockData.results.first!,
                  viewModel: CharacterListViewModel(networkManager: NetworkManager(),
                                                    cacheManager: CacheManager(),
                                                    imageDownloadManager: ImageDownloaderManager(),
                                                    coreDataManager: CoreDataManager()))
}
