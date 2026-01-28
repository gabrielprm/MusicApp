import SwiftUI

struct SimilarSongsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            content
        }
        .presentationBackground(Color.black)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Similar Songs")
                .font(.headline)
                .fontWeight(.bold)
            
            if let song = viewModel.currentSong {
                Text("Based on \"\(song.trackName ?? "Unknown")\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoadingSimilarSongs {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Finding similar songs...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        } else if viewModel.similarSongs.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                Text("No similar songs found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Try a different song")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            Spacer()
        } else {
            List {
                ForEach(viewModel.similarSongs) { song in
                    SongRowView(song: song)
                        .contentShape(Rectangle())
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
    }
}
