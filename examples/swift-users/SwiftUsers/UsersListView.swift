import SwiftUI
import EENApiToolkit

struct UsersListView: View {
    let toolkit: EENToolkit
    @State private var users: [User] = []
    @State private var nextPageToken: String?
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && users.isEmpty {
                    ProgressView("Loading users...")
                } else if let errorMessage, users.isEmpty {
                    errorView(errorMessage)
                } else {
                    userList
                }
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task { await refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        Task {
                            try? await toolkit.auth.revokeToken()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .task { await loadUsers() }
        }
    }

    private var userList: some View {
        List {
            Section {
                ForEach(users) { user in
                    userRow(user)
                }
            } footer: {
                Text("\(users.count) user\(users.count == 1 ? "" : "s")")
            }

            if nextPageToken != nil {
                Section {
                    Button {
                        Task { await loadMore() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoadingMore {
                                ProgressView()
                            } else {
                                Text("Load More")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoadingMore)
                    .accessibilityIdentifier("LoadMoreButton")
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    private func userRow(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(user.firstName) \(user.lastName)")
                .font(.headline)

            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                if let active = user.isActive {
                    Label(active ? "Active" : "Inactive",
                          systemImage: active ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.caption)
                        .foregroundColor(active ? .green : .red)
                }

                if let lastLogin = user.lastLogin {
                    Label(formatDate(lastLogin), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadUsers() }
            }
        }
        .padding()
    }

    private func loadUsers() async {
        isLoading = true
        errorMessage = nil
        do {
            let params = ListUsersParams(pageSize: 20)
            let result = try await toolkit.users.list(params: params)
            users = result.results
            nextPageToken = result.nextPageToken
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadMore() async {
        guard let token = nextPageToken else { return }
        isLoadingMore = true
        do {
            var params = ListUsersParams(pageSize: 20)
            params.pageToken = token
            let result = try await toolkit.users.list(params: params)
            users.append(contentsOf: result.results)
            nextPageToken = result.nextPageToken
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }

    private func refresh() async {
        users = []
        nextPageToken = nil
        await loadUsers()
    }

    private func formatDate(_ isoString: String) -> String {
        // Show just the date portion for compactness
        if let idx = isoString.firstIndex(of: "T") {
            return String(isoString[..<idx])
        }
        return isoString
    }
}
