import SwiftUI

public struct PlayerView: View {
    @StateObject private var viewModel: PlayerViewModel = PlayerViewModel()
    @State private var isSeeking = false
    @State private var seekValue: Double = 0
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                navigationBar
                
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
            seekValue = viewModel.currentTime
        }
    }
    
    var navigationBar: some View {
        HStack {
            Button(action: viewModel.didTapBack) {
                Image(systemName: "chevron.backward")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentShape(Rectangle())
            }
            Spacer()
            Button(action: viewModel.didTapMenu) {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    var artWork: some View {
        Group {
             if let art = viewModel.artwork {
                 art
                     .resizable()
                     .scaledToFill()
             } else {
                 ZStack {
                     RoundedRectangle(cornerRadius: 24, style: .continuous)
                         .fill(Color.white.opacity(0.08))
                     Image(systemName: "music.note")
                         .font(.system(size: 88, weight: .regular))
                         .foregroundStyle(Color.white.opacity(0.9))
                 }
             }
         }
         .frame(width: 200, height: 200)
         .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
         .padding(.bottom, 36)
    }
    
    var songMetadata: some View {
        VStack(spacing: 6) {
            Text(viewModel.title.isEmpty ? "Unknown Title" : viewModel.title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.artist.isEmpty ? "Unknown Artist" : viewModel.artist)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    var songSlider: some View {
        VStack(spacing: 10) {
            // --- REPLACED Slider WITH CustomSlider ---
            CustomSlider(
                value: $seekValue,
                range: 0...(max(0.001, viewModel.duration)),
                onEditingChanged: { editing in
                    isSeeking = editing
                    if !editing {
                        viewModel.seek(to: seekValue)
                    }
                },
                trackHeight: 2, // Customize your line height
                thumbSize: 24   // Customize your ball size
            )
            .padding(.horizontal, 20)
             
            HStack {
                // The text now uses seekValue directly while seeking
                Text(Self.formatTime(isSeeking ? seekValue : viewModel.currentTime))
                    .foregroundStyle(.white.opacity(0.9))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                Spacer()
                let remaining = viewModel.duration - (isSeeking ? seekValue : viewModel.currentTime)
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

