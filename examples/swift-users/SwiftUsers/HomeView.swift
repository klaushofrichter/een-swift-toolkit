import SwiftUI
import EENApiToolkit

struct HomeView: View {
    let toolkit: EENToolkit
    @EnvironmentObject var authState: AuthState
    @State private var user: User?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Sign Out") {
                            logout()
                        }
                        .foregroundColor(.red)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            Task { await loadUser() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .task { await loadUser() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading profile...")
        } else if let user {
            userProfile(user)
        } else if let errorMessage {
            errorView(errorMessage)
        } else {
            ProgressView()
        }
    }

    private func userProfile(_ user: User) -> some View {
        List {
            Section("Identity") {
                row("Name", value: "\(user.firstName) \(user.lastName)")
                row("Email", value: user.email)
                row("User ID", value: user.id)
            }

            if let accountId = user.accountId {
                Section("Account") {
                    row("Account ID", value: accountId)
                }
            }

            Section("Preferences") {
                if let tz = user.timeZone {
                    row("Time Zone", value: tz)
                }
                if let lang = user.language {
                    row("Language", value: lang)
                }
            }

            Section("Contact") {
                if let phone = user.phone {
                    row("Phone", value: phone)
                }
                if let mobile = user.mobilePhone {
                    row("Mobile", value: mobile)
                }
            }

            if let permissions = user.permissions, !permissions.isEmpty {
                Section("Permissions") {
                    ForEach(permissions, id: \.self) { perm in
                        Text(perm)
                            .font(.caption)
                            .monospaced()
                    }
                }
            }

            Section("Status") {
                if let active = user.isActive {
                    row("Active", value: active ? "Yes" : "No")
                }
                if let lastLogin = user.lastLogin {
                    row("Last Login", value: lastLogin)
                }
                if let created = user.createdAt {
                    row("Created", value: created)
                }
            }

            Section("Session") {
                if let email = authState.userEmail {
                    row("Session Email", value: email)
                }
                if let exp = authState.tokenExpiration {
                    row("Token Expires", value: exp.formatted())
                }
            }
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadUser() }
            }
        }
        .padding()
    }

    private func loadUser() async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await toolkit.users.getCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func logout() {
        Task {
            try? await toolkit.auth.revokeToken()
        }
    }
}
