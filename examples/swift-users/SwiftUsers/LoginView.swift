import SwiftUI
import EENSwiftToolkit

struct LoginView: View {
    let toolkit: EENToolkit
    @State private var isLoading = false
    @State private var showingOAuth = false
    @State private var authUrl: URL?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "video.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Eagle Eye Networks")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Swift Users Demo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                Button {
                    startLogin()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isLoading ? "Signing In..." : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || showingOAuth)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 2) {
                Text("v\(toolkitVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Proxy: \(AppConfig.proxyUrl)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingOAuth) {
            if let authUrl {
                NavigationStack {
                    OAuthWebView(
                        authUrl: authUrl,
                        redirectUri: AppConfig.redirectUri,
                        onCallback: { code, state in
                            showingOAuth = false
                            Task { await exchangeCode(code: code, state: state) }
                        },
                        onError: { message in
                            showingOAuth = false
                            errorMessage = message
                            isLoading = false
                        }
                    )
                    .navigationTitle("Sign In")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingOAuth = false
                                isLoading = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func startLogin() {
        isLoading = true
        errorMessage = nil
        Task {
            let url = await toolkit.auth.getAuthUrl()
            authUrl = url
            showingOAuth = true
        }
    }

    private func exchangeCode(code: String, state: String?) async {
        do {
            let _ = try await toolkit.auth.handleCallback(
                code: code,
                state: state
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
