import SwiftUI

public struct PlayerView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @State private var isSeeking = false
    @State private var seekValue: Double = 0
    
    @Environment(\.dismiss) private var dismiss
    
    let song: Song
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                artWork
                Spacer()
                songMetadata
                songSlider
                songControls
            }
        }
        .onChange(of: viewModel.currentTime) { _, new in
            if !isSeeking { seekValue = new }
        }
        .onAppear {
            viewModel.selectSong(song)
            seekValue = viewModel.currentTime
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.backward")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showMoreOptions.toggle() }) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $viewModel.showMoreOptions) {
            MoreOptionsView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $viewModel.showAlbumSheet) {
            AlbumSongsView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
    
    var artWork: some View {
        Group {
            AsyncImage(url: viewModel.currentSong?.artworkUrlLarge) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    songEmptyImageView
                case .empty:
                    ProgressView()
                @unknown default:
                    songEmptyImageView
                }
            }
         }
         .frame(width: 200, height: 200)
         .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
         .padding(.bottom, 36)
    }
    
    var songEmptyImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
            Image(systemName: "music.note")
                .font(.system(size: 88, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.9))
        }
    }
    
    var songMetadata: some View {
        VStack(spacing: 6) {
            Text(viewModel.currentSong?.trackName ?? "Unknown Title")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(viewModel.currentSong?.artistName ?? "Unknown Artist")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    var songSlider: some View {
        VStack(spacing: 10) {
            CustomSlider(
                value: $seekValue,
                range: 0...(max(0.001, viewModel.currentSong?.trackDuration ?? 0.001)),
                onEditingChanged: { editing in
                    isSeeking = editing
                    if !editing {
                        viewModel.seek(to: seekValue)
                    }
                },
                trackHeight: 2,
                thumbSize: 24
            )
            .padding(.horizontal, 20)
             
            HStack {
                Text(Self.formatTime(isSeeking ? seekValue : viewModel.currentTime))
                    .foregroundStyle(.white.opacity(0.9))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                Spacer()
                let remaining = (viewModel.currentSong?.trackDuration ?? 0.0) - (isSeeking ? seekValue : viewModel.currentTime)
                Text("-" + Self.formatTime(max(0, remaining)))
                    .foregroundStyle(.white.opacity(0.9))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 18)
    }
    
    var songControls: some View {
        HStack(spacing: 36) {
            Button(action: viewModel.skipBackward) {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentShape(Rectangle())
            }
            Button(action: viewModel.playPause) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                        .offset(x: viewModel.isPlaying ? 0 : 2)
                }
                .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
            }
            Button(action: viewModel.skipForward) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentShape(Rectangle())
            }
        }
        .padding(.top, 6)
    }
}

private extension PlayerView {
    static func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "0:00" }
        let s = max(0, Int(seconds.rounded()))
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }
}

