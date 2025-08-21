import SwiftUI

struct MoreOptionsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text(viewModel.currentSong?.trackName ?? "Unknown Title")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(viewModel.currentSong?.artistName ?? "Unknown Artist")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                Task {
                    dismiss()
                    
                    if let albumId = viewModel.currentSong?.collectionId {
                        await viewModel.fetchAlbumSongs(for: albumId)
                    }
                }
            }) {
                HStack(spacing: 16) {
                    Image(systemName: "square.stack")
                        .font(.title2)
                    Text("Open Album")
                        .fontWeight(.medium)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(EdgeInsets(top: 32, leading: 20, bottom: 40, trailing: 20))
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }
}
