import SwiftUI

struct AlbumSongsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.albumSongs.first?.collectionName ?? "Album")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 24)
                .padding(.bottom, 10)

            List {
                ForEach(viewModel.albumSongs) { song in
                    SongRowView(song: song)
                        .onTapGesture {
                            dismiss()
                            viewModel.selectSong(song)
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
    }
}
