import SwiftUI
import EENSwiftToolkit

struct ContentView: View {
    @EnvironmentObject var authState: AuthState
    let toolkit: EENToolkit

    var body: some View {
        if authState.isAuthenticated {
            MainTabView(toolkit: toolkit)
        } else {
            LoginView(toolkit: toolkit)
        }
    }
}
