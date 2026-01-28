import SwiftUI

struct AlbumSongsView: View {
    @ObservedObject var viewModel: AlbumSongsViewModel
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.albumName)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 24)
                .padding(.bottom, 24)

            content
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
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Spacer()
            
        case .loaded(let songs) where songs.isEmpty:
            Spacer()
            Text("No songs found")
                .foregroundStyle(.gray)
            Spacer()
            
        case .loaded:
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
            
        case .error(let message):
            Spacer()
            VStack(spacing: 16) {
                Text(message)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                
                Button("Retry") {
                    Task {
                        await viewModel.retry()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            Spacer()
        }
    }
}
