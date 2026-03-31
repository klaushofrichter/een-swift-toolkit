# Authentication Guide

EENSwiftToolkit uses an OAuth proxy that handles refresh tokens server-side. Your app never sees the refresh token — it receives an access token and a session ID.

## Architecture

```
┌─────────┐     ┌──────────────┐     ┌──────────┐
│  iOS App │────>│  OAuth Proxy │────>│  EEN API │
│          │<────│  (Workers)   │<────│          │
└─────────┘     └──────────────┘     └──────────┘
     │
     │  Access Token + Session ID
     │  (Keychain encrypted at rest)
```

## Configuration

```swift
let config = EENToolkitConfig(
    proxyUrl: "https://your-proxy.workers.dev",  // OAuth proxy URL
    clientId: "YOUR-CLIENT-ID",                  // EEN API client ID
    redirectUri: "yourapp://callback",           // Custom URL scheme
    storageStrategy: .keychain                   // .keychain or .memory
)

let toolkit = EENToolkit(config: config)
```

| Parameter | Description |
|---|---|
| `proxyUrl` | Your deployed OAuth proxy. Must be reachable from the device. |
| `clientId` | Eagle Eye Networks API client ID. |
| `redirectUri` | Custom URL scheme registered in your app's Info.plist. |
| `storageStrategy` | `.keychain` persists tokens across launches. `.memory` for testing. |

## Login with ASWebAuthenticationSession

The simplest way to authenticate — opens a system browser sheet:

```swift
@MainActor
func login() async throws {
    try await toolkit.webSession.authenticate()
    // toolkit.authState.isAuthenticated is now true
}
```

This handles the full OAuth flow: opening the EEN login page, capturing the redirect, and exchanging the authorization code for a token.

## Manual Login (Custom WebView)

If you need a custom login UI:

```swift
// 1. Get the authorization URL
let authUrl = await toolkit.auth.getAuthUrl()

// 2. Present authUrl in your web view
// 3. Intercept the redirect with ?code=...&state=...

// 4. Exchange the code for a token
let response = try await toolkit.auth.handleCallback(
    code: authCode,
    state: authState
)
// toolkit.authState is now authenticated
```

## Session Restoration

Restore a previous session on app launch (requires `.keychain` storage):

```swift
@main
struct MyApp: App {
    let toolkit: EENToolkit

    init() {
        toolkit = EENToolkit(config: config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(toolkit.authState)
                .task {
                    let restored = await toolkit.restoreSession()
                    if !restored {
                        // Show login screen
                    }
                }
        }
    }
}
```

## Logout

```swift
func logout() async {
    try? await toolkit.auth.revokeToken()
    // authState.isAuthenticated is now false
    // Token is removed from Keychain
    // Server session is invalidated
}
```

## Auth-Gated Navigation

Use `AuthState` as an `@EnvironmentObject` to drive your navigation:

```swift
struct ContentView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        if authState.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
```

### Available AuthState Properties

| Property | Type | Description |
|---|---|---|
| `isAuthenticated` | `Bool` | Computed: `token != nil` |
| `token` | `String?` | Current access token |
| `baseUrl` | `String?` | API base URL for this session |
| `sessionId` | `String?` | Session ID for proxy requests |
| `userEmail` | `String?` | Authenticated user's email |
| `tokenExpiration` | `Date?` | When the current token expires |
| `isRefreshing` | `Bool` | Whether a token refresh is in progress |

## Token Lifecycle

1. **Login** — `handleCallback()` stores the token and starts auto-refresh
2. **Auto-refresh** — Fires at 50% of TTL or 5 minutes before expiry (whichever is earlier)
3. **Manual refresh** — `refreshToken()` (concurrent calls are deduplicated)
4. **Restore** — `restoreSession()` loads from Keychain and validates
5. **Revoke** — `revokeToken()` clears local state and invalidates the server session

Token refresh is fully automatic — you do not need to manage it manually.

## Security Model

- Refresh token is stored server-side in the proxy (never exposed to the client)
- Client receives an access token + session ID
- Session ID authenticates refresh requests to the proxy
- Keychain storage encrypts tokens at rest
- Hostname validation prevents URL spoofing
