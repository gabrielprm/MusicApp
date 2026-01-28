import SwiftUI

public struct PlayerView: View {
    @StateObject var viewModel: PlayerViewModel
    @State private var isSeeking = false
    
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Blurred album cover background
                backgroundView(size: geometry.size)
                
                // Dark overlay for better readability
                Color.black.opacity(0.4)
                
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    
                    // Central space for future features
                    centralContentArea
                    
                    Spacer()
                    
                    // Bottom controls section
                    bottomSection
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.currentTime) { _, new in
            if !isSeeking { viewModel.seekValue = new }
        }
        .onAppear {
            viewModel.selectSong(viewModel.song)
            viewModel.seekValue = viewModel.currentTime
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image.Icons.icArrowLeft
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showMoreOptions.toggle() }) {
                    Image.Icons.icMore
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .sheet(isPresented: $viewModel.showMoreOptions, onDismiss: {
            viewModel.onMoreOptionsDismissed()
        }) {
            MoreOptionsView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $viewModel.showAlbumSheet) {
            if let albumId = viewModel.currentSong?.collectionId {
                AlbumSongsView(viewModel: AlbumSongsViewModel(albumId: albumId))
                    .environmentObject(viewModel)
                    .preferredColorScheme(.dark)
            }
        }
        .sheet(isPresented: $viewModel.showSimilarSongs) {
            SimilarSongsView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Background
    
    private func backgroundView(size: CGSize) -> some View {
        CachedAsyncImage(url: viewModel.currentSong?.artworkUrlLarge) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .blur(radius: 50)
                    .scaleEffect(1.2)
            case .failure, .empty:
                Color.black
                    .frame(width: size.width, height: size.height)
            @unknown default:
                Color.black
                    .frame(width: size.width, height: size.height)
            }
        }
        .clipped()
    }
    
    // MARK: - Central Content Area (for future features)
    
    private var centralContentArea: some View {
        VStack(spacing: 20) {
            artWork
        }
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 0) {
            songMetadata
            songSlider
            songControls
        }
        .padding(.bottom, 34) // Safe area for home indicator
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .padding(.top, -100)
        )
    }
    
    // MARK: - Artwork
    
    var artWork: some View {
        CachedAsyncImage(url: viewModel.currentSong?.artworkUrlLarge) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                songEmptyImageView
            case .empty:
                ProgressView()
                    .frame(width: 280, height: 280)
            @unknown default:
                songEmptyImageView
            }
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
    
    var songEmptyImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.Theme.DarkAlphaInvert)
            Image.Icons.icMusicNote
                .resizable()
                .frame(width: 116, height: 116)
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
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    var songSlider: some View {
        VStack(spacing: 10) {
            CustomSlider(
                value: $viewModel.seekValue,
                range: 0...(max(0.001, viewModel.currentSong?.trackDuration ?? 0.001)),
                onEditingChanged: { editing in
                    isSeeking = editing
                    if !editing {
                        viewModel.seek(to: viewModel.seekValue)
                    }
                },
                trackHeight: 2,
                thumbSize: 24
            )
            .padding(.horizontal, 20)
             
            timeIndicators
        }
        .padding(.bottom, 18)
    }
    
    var timeIndicators: some View {
        HStack {
            Text(Self.formatTime(isSeeking ? viewModel.seekValue : viewModel.currentTime))
                .foregroundStyle(.white.opacity(0.9))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
            Spacer()
            let remaining = (viewModel.currentSong?.trackDuration ?? 0.0) - (isSeeking ? viewModel.seekValue : viewModel.currentTime)
            Text("-" + Self.formatTime(max(0, remaining)))
                .foregroundStyle(.white.opacity(0.9))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
        }
        .padding(.horizontal, 20)
    }
    
    var songControls: some View {
        HStack(spacing: 36) {
            Button(action: viewModel.skipBackward) {
                Image.Icons.icBackward
                    .resizable()
                    .frame(width: 48, height: 48)
            }
            .disabled(viewModel.isLoading)
            
            Button(action: viewModel.playPause) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.black)
                            .offset(x: viewModel.isPlaying ? 0 : 2)
                    }
                }
                .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
            }
            .disabled(viewModel.isLoading)
            
            Button(action: viewModel.skipForward) {
                Image.Icons.icForward
                    .resizable()
                    .frame(width: 48, height: 48)
            }
            .disabled(viewModel.isLoading)
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

