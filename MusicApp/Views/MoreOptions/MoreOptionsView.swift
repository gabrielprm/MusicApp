import SwiftUI

struct MoreOptionsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    
    private var songTitle: String {
        viewModel.currentSong?.trackName ?? "Unknown Title"
    }
    
    private var artistName: String {
        viewModel.currentSong?.artistName ?? "Unknown Artist"
    }

    var body: some View {
        VStack(spacing: 24) {
            headerView
            optionsList
        }
        .padding(EdgeInsets(top: 32, leading: 20, bottom: 40, trailing: 20))
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
    }
    
    private var headerView: some View {
        VStack(spacing: 4) {
            Text(songTitle)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
            Text(artistName)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Options for \(songTitle) by \(artistName)")
    }
    
    private var optionsList: some View {
        VStack(spacing: 16) {
            OptionButton(
                icon: Image.Icons.icPlaylist,
                title: "Open Album"
            ) {
                viewModel.presentAlbumSheet()
            }
            
            OptionButton(
                icon: Image(systemName: "brain"),
                title: "Find Similar Songs"
            ) {
                viewModel.presentSimilarSongs()
            }
            
            OptionButton(
                icon: Image(systemName: "waveform"),
                title: "Audio Visualizer"
            ) {
                viewModel.presentVisualizer()
            }
            
            ShareLink(item: "\(songTitle) by \(artistName)") {
                HStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 24, height: 24)
                    Text("Share Song")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }
            
            if let previewUrl = viewModel.currentSong?.previewUrl {
                OptionButton(
                    icon: Image(systemName: "safari"),
                    title: "Open in iTunes"
                ) {
                    openInItunes(previewUrl: previewUrl)
                }
            }
        }
    }
    
    private func openInItunes(previewUrl: URL) {
        let urlString = previewUrl.absoluteString
            .replacingOccurrences(of: "audio-ssl.itunes.apple.com", with: "itunes.apple.com")
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Option Button Component

private struct OptionButton: View {
    let icon: Image
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                icon
                    .frame(width: 24, height: 24)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .accessibilityLabel(title)
    }
}
