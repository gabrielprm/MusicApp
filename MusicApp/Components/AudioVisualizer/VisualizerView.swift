//
//  VisualizerView.swift
//  MusicApp
//
//  Created on January 28, 2026.
//

import SwiftUI

struct VisualizerView: View {
    
    @EnvironmentObject private var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                header
                
                Spacer()
                            
                visualizerSection
                
                Spacer()
                
                songInfo
                
                progressSection
                
                controlsSection
                
                stylePicker
            }
            .padding()
        }
        .onDisappear {
            viewModel.stopVisualizerMode()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.8),
                Color.blue.opacity(0.6),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("Audio Visualizer")
                .font(.headline)
                .foregroundStyle(.white)
            
            Spacer()
            
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(.clear)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Visualizer Section
    
    private var visualizerSection: some View {
        AudioVisualizerView(
            magnitudes: viewModel.magnitudes,
            style: viewModel.visualizerStyle,
            gradient: LinearGradient(
                colors: [.purple, .pink, .orange, .yellow],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .frame(height: 250)
        .padding(.horizontal)
    }
    
    // MARK: - Song Info
    
    private var songInfo: some View {
        VStack(spacing: 8) {
            if let song = viewModel.currentSong {
                Text(song.trackName ?? "Unknown")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(song.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white)
                        .frame(width: progressWidth(in: geometry.size.width), height: 4)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let progress = value.location.x / geometry.size.width
                            let seekTime = Double(progress) * viewModel.duration
                            viewModel.visualizerSeek(to: seekTime)
                        }
                )
            }
            .frame(height: 4)
            
            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
                
                Text(formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        HStack(spacing: 50) {
            Button {
                viewModel.visualizerSeek(to: max(0, viewModel.currentTime - 10))
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            
            Button {
                viewModel.visualizerPlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 70, height: 70)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(.black)
                    }
                }
            }
            .disabled(viewModel.isLoading)
                        
            Button {
                viewModel.visualizerSeek(to: min(viewModel.duration, viewModel.currentTime + 10))
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 30)
    }
    
    // MARK: - Style Picker
    
    private var stylePicker: some View {
        HStack(spacing: 20) {
            ForEach(VisualizerStyle.allCases) { style in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.visualizerStyle = style
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: style.icon)
                            .font(.title3)
                        
                        Text(style.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(viewModel.visualizerStyle == style ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.visualizerStyle == style ? .white.opacity(0.2) : .clear)
                    )
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Helpers
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard viewModel.duration > 0 else { return 0 }
        let progress = viewModel.currentTime / viewModel.duration
        return CGFloat(progress) * totalWidth
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VisualizerView()
        .environmentObject(PlayerViewModel(song: Song(
            wrapperType: "track",
            kind: "song",
            trackId: 1,
            trackName: "Test Song",
            previewUrl: URL(string: "https://example.com/preview.m4a"),
            trackTimeMillis: 180000,
            trackPrice: 0.99,
            artistName: "Test Artist",
            collectionId: 1,
            collectionName: "Test Album",
            artworkUrl100: URL(string: "https://example.com/artwork.jpg")!,
            primaryGenreName: "Pop",
            currency: "USD"
        )))
}
