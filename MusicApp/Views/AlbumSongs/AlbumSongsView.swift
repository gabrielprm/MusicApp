import SwiftUI

struct AlbumSongsView: View {
    @ObservedObject var viewModel: AlbumSongsViewModel
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.albumSongs.first?.collectionName ?? "Album")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 24)
                .padding(.bottom, 24)

            List {
                ForEach(viewModel.albumSongs) { song in
                    SongRowView(song: song)
                        .onTapGesture {
                            dismiss()
                            playerViewModel.selectSong(song)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.black)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .presentationBackground(Color.black)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            Task {
                await viewModel.fetchAlbumSongs()
            }
        }
    }
}
