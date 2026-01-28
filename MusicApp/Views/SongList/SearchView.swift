import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SongListViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationStack {
                content
                    .navigationTitle("Songs")
                    .toolbarBackground(Color.black, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search"
            )
            .preferredColorScheme(.dark)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            emptyStateView
            
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .loaded, .loadingMore:
            if viewModel.songs.isEmpty {
                noResultsView
            } else {
                resultsListView
            }
            
        case .error(let message):
            errorView(message: message)
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
            
            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.black)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
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
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.bold)
            Text("Try a different search term.")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(.black)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.bold)
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .background(.black)
    }
}
