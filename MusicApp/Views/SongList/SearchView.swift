import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SongListViewModel()
    @State private var searchTerm = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationStack {
                Group {
                    if viewModel.songs.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                        emptyStateView
                    } else {
                        resultsListView
                    }
                }
                .navigationTitle("Songs")
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
            .searchable(
                text: $searchTerm,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search"
            )
            .onSubmit(of: .search) {
                Task {
                    await viewModel.search(for: searchTerm)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private var resultsListView: some View {
        List {
            ForEach(viewModel.songs) { song in
                NavigationLink(destination: PlayerView(viewModel: PlayerViewModel(song: song))) {
                    SongRowView(song: song)
                        .listRowBackground(Color.black)
                }
                .onAppear {
                    if song.id == viewModel.songs.last?.id {
                        Task {
                            await viewModel.loadMoreSongs()
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .overlay {
            if viewModel.isLoading && viewModel.songs.isEmpty {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(errorMessage, systemImage: "exclamationmark.triangle")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Find Your Favorite Music")
                .font(.title2)
                .fontWeight(.bold)
            Text("Search for any song or artist to begin.")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(.black)
    }
}
