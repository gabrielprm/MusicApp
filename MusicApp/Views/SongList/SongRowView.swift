import SwiftUI

struct SongRowView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 16) {
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
                @unknown default:
                    songEmptyImageView
                }
            }

            VStack(alignment: .leading) {
                Text(song.trackName ?? "Unknown Title")
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    var songEmptyImageView: some View {
        Image.Icons.icMusicNote
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(12)
            .frame(width: 44, height: 44)
            .background(Color.secondary.opacity(0.2))
            .foregroundColor(.secondary)
            .cornerRadius(8)
    }
}
