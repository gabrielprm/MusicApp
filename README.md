# MusicApp 🎵

A high-performance iOS music application built with **Swift 6** and **SwiftUI**, engineered to demonstrate advanced signal processing, strict concurrency, and clean architecture.

Beyond standard playback, this project implements a **real-time FFT audio visualizer** from scratch, bridging low-level audio buffers to high-level UI animations with 60fps performance.

## 🚀 Engineering Highlights (High-Performance Focus)

This project goes beyond standard iOS patterns to solve complex engineering challenges:

- **Real-Time Signal Processing (FFT):** Implements a custom **Fast Fourier Transform** engine using Apple's `Accelerate` framework (`vDSP`). It processes raw PCM audio buffers in real-time to render a frequency-accurate 60fps visualizer, handling windowing, magnitude calculation, and decibel normalization manually.
- **Custom Audio Engine Architecture:** Replaces the standard `AVPlayer` streaming model with a robust **Download-and-Process** architecture using `AVAudioEngine` and `AVAudioNodeTap`. This allows for low-latency access to raw audio data that is impossible with standard streaming APIs.
- **Strict Concurrency & Thread Safety:** Demonstrates mastery of Swift 6 Concurrency. Safely bridges high-frequency background audio callbacks (running on real-time threads) to the UI's Main Actor using `Combine` pipelines and isolated data storage, ensuring zero main-thread blocking or race conditions.
- **Semantic Vector Search:** Uses on-device Machine Learning (`NLEmbedding`) to generate vector embeddings for songs, enabling "Search by Meaning" (e.g., finding "Sad girl winter" songs) via Cosine Similarity calculations.

## 🌟 Key Features

### 🎧 Immersive Player & Visualizer
- **60fps Audio Visualizer:** Dynamic frequency bars that react to the music in real-time.
- **Offline-First Playback:** Smart caching strategy for preview assets to ensure instant playback and analysis.
- **Interactive Controls:** Custom scrubbing slider and blurred dynamic backgrounds.

### 🔍 Advanced Search
- **Dual Search Modes**:
  - **Standard**: Keyword-based search via iTunes API.
  - **Semantic**: Vector-based search for "vibe-based" discovery.
- **Smart Discovery**: "Find Similar Songs" feature that uses vector mathematics to find nearest neighbors in the embedding space.

## 🛠 Tech Stack

- **Language**: Swift 6 (Strict Concurrency enabled)
- **UI Framework**: SwiftUI
- **Signal Processing**: `Accelerate` (vDSP), `AVAudioEngine`, `AVAudioNodeTap`.
- **Concurrency**: Actors, `TaskGroup`, `Combine`, `@MainActor`.
- **AI/ML**: NaturalLanguage (`NLEmbedding`).
- **Architecture**: MVVM with Protocol-Oriented Services.

## 🏗 Architecture

The project follows a clean **MVVM** pattern, enforcing strict separation between the View logic and the complex Audio/AI processing.

### Core Layers
- **Audio Analysis Layer**: `AudioAnalyzer` is an isolated service that handles raw buffer pointer manipulation and FFT math, keeping ViewModels clean.
- **ViewModels**: `PlayerViewModel` acts as the coordinator, managing the state machine between the `AVAudioEngine` and the SwiftUI View.
- **Services**:
  - `APIService`: `async/await` networking layer.
  - `SemanticSearchService`: Vector embedding generation.
- **Repositories**: Abstracts data sources for testability.

## 📁 Project Structure

```text
MusicApp/
├── App/
│   └── MusicAppApp.swift           # App Entry Point
├── Views/
│   ├── Player/                     # Visualizer & Controls
│   ├── SongList/                   # Home & Search
│   └── Components/                 # AudioVisualizerView.swift
├── Service/
│   ├── AudioAnalyzer.swift         # [High Complexity] FFT & Signal Processing
│   ├── SemanticSearchService.swift # [High Complexity] Vector Embeddings
│   └── APIService.swift            # Networking
├── ViewModels/
│   ├── PlayerViewModel.swift       # Audio Engine Management
│   └── SongListViewModel.swift
└── Models/
    └── ITunesAPIResponse.swift
