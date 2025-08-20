import SwiftUI
import Combine
import Foundation

public protocol PlayerViewModelProtocol {
    func playPause()
    func skipBackward()
    func skipForward()
    func seek(to seconds: Double)
    func didTapBack()
    func didTapMenu()
}

final class PlayerViewModel: ObservableObject, PlayerViewModelProtocol {
    @Published var title: String = "Something"
    @Published var artist: String = "Artist"
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 200
    @Published var artwork: Image? = nil
    
    private var timer: AnyCancellable?
    
    func playPause() {
        isPlaying.toggle()
        if isPlaying {
            startTicking()
        } else {
            stopTicking()
        }
    }
    
    func skipBackward() {
        seek(to: max(0, currentTime - 10))
    }
    
    func skipForward() {
        seek(to: min(duration, currentTime + 10))
    }
    
    func seek(to seconds: Double) {
        currentTime = min(max(0, seconds), duration)
    }
    
    func didTapBack() {
        print("Back tapped")
    }
    
    func didTapMenu() {
        print("Menu tapped")
    }
    
    private func startTicking() {
        timer?.cancel()
        timer = Timer.publish(every: 1/30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isPlaying else { return }
                self.currentTime = min(self.duration, self.currentTime + 1/30)
                if self.currentTime >= self.duration {
                    self.isPlaying = false
                    self.stopTicking()
                }
            }
    }
    
    private func stopTicking() {
        timer?.cancel()
        timer = nil
    }
}
