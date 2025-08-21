import SwiftUI

struct SongRowView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: song.artworkUrl100) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
            } placeholder: {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(12)
                    .frame(width: 50, height: 50)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(6)
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
}
