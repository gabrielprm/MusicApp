# MusicApp 🎵

A modern, fully-featured iOS music application built with SwiftUI and Swift 6, demonstrating advanced features like semantic vector search, custom audio playback, and clean MVVM architecture.

## 🌟 Key Features

### 🔍 Advanced Search
- **Dual Search Modes**:
  - **Standard Search**: Keyword-based search using the iTunes API.
  - **Semantic Search**: Find songs by meaning (e.g., "Sad girl winter") using on-device Vector Embeddings (`NLEmbedding`).
- **Real-time Experience**: Debounced search input for smooth user interaction.
- **State Management**: Robust handling of loading, error, empty, and content states.

### 🎧 Immersive Player
- **Audio Playback**: Custom implementation using `AVFoundation` and `AVPlayer` to play song previews.
- **Modern UI**: Full-screen player with a dynamic, blurred album art background.
- **Interactive Controls**: Custom slider for scrubbing, play/pause, and skip controls.
- **Smart Discovery**: "Find Similar Songs" feature that uses vector similarity to suggest related tracks based on the currently playing song's metadata (Artist + Genre).

### 📱 UI/UX
- **Album Integration**: View full tracklists for albums.
- **Components**: Custom-built `CachedAsyncImage` for efficient image loading and caching.
- **Accessibility**: Comprehensive accessibility labels and hints for VoiceOver support.
- **Sheet Management**: Improved navigation flow with proper sheet chaining and presentation logic.

## 🏗 Architecture

The project follows a clean **MVVM (Model-View-ViewModel)** architecture with a focus on separation of concerns and testability.

### Core Layers
- **Views**: Pure SwiftUI views driven by state. Use `@State`, `@Binding`, and `@EnvironmentObject`.
- **ViewModels**: Manage business logic and UI state. specific ViewModels (`PlayerViewModel`, `SongListViewModel`) communicate with services.
- **Services**:
  - `APIService`: Generic, protocol-oriented network layer with `async/await`.
  - `SemanticSearchService`: Handles vector embedding generation and cosine similarity calculations.
- **Repositories**: `SongRepository` abstracts data fetching strategies.
- **Models**: Decodable structs representing iTunes API responses.

## 🛠 Tech Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Concurrency**: Swift Async/Await, Actors, `@Sendable`, `Task`.
- **Audio**: AVFoundation (`AVPlayer`, `AVPlayerItem`).
- **AI/ML**: NaturalLanguage Framework (`NLEmbedding`).
- **Networking**: `URLSession` with structured concurrency.

## 📁 Project Structure

```
MusicApp/
├── App/
│   ├── MusicAppApp.swift       # App Entry Point
│   └── Info.plist
├── Views/
│   ├── SongList/               # Search & Home Screen
│   ├── Player/                 # Music Player & Controls
│   ├── AlbumSongs/             # Album Detail View
│   ├── SimilarSongs/           # Vector-based recommendations
│   └── MoreOptions/            # Context menus
├── ViewModels/
│   ├── SongListViewModel.swift
│   ├── PlayerViewModel.swift
│   └── AlbumSongsViewModel.swift
├── Service/
│   ├── APIService.swift        # Networking
│   └── SemanticSearchService.swift # Vector Search Logic
├── Models/
│   └── ITunesAPIResponse.swift # Data Models
├── Components/                 # Reusable UI (Images, Sliders)
└── Helpers/                    # Extensions & Constants
```

## 🚀 Getting Started

### Prerequisites
- Xcode 18.0+ (Swift 6 support recommended)
- iOS 18.5+ Target

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/MusicApp.git
   ```
2. Open `MusicApp.xcodeproj` in Xcode.
3. Select a simulator or physical device.
4. Press `Cmd + R` to run.

## 🧪 Testing

The project includes unit tests for key logic:
- `SongListViewModelTests`
- `PlayerViewModelTests`
- `AlbumSongsViewModelTests`

Run tests using `Cmd + U`.

## 📜 License

This project is for educational purposes. All music data is provided by the iTunes Search API.

---
