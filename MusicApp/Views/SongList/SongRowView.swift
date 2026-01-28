import SwiftUI

struct SongRowView: View {
    let song: Song
    
    private var songTitle: String {
        song.trackName ?? "Unknown Title"
    }
    
    private var artistName: String {
        song.artistName
    }

    var body: some View {
        HStack(spacing: 16) {
            artworkView
            songInfo
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(songTitle) by \(artistName)")
        .accessibilityHint("Double tap to play")
    }
    
    private var artworkView: some View {
        CachedAsyncImage(url: song.artworkUrl100) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
            case .failure:
                songEmptyImageView
            case .empty:
                ProgressView()
                    .frame(width: 44, height: 44)
            @unknown default:
                songEmptyImageView
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityHidden(true)
    }
    
    private var songInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(songTitle)
                .font(.headline)
                .fontWeight(.medium)
                .lineLimit(1)
            Text(artistName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
    
    private var songEmptyImageView: some View {
        Image.Icons.icMusicNote
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(12)
            .frame(width: 44, height: 44)
            .background(Color.secondary.opacity(0.2))
            .foregroundColor(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
