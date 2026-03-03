import SwiftUI
import EENApiToolkit

struct ContentView: View {
    @EnvironmentObject var authState: AuthState
    let toolkit: EENToolkit

    var body: some View {
        if authState.isAuthenticated {
            TabView {
                HomeView(toolkit: toolkit)
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                    .accessibilityIdentifier("ProfileTab")

                UsersListView(toolkit: toolkit)
                    .tabItem {
                        Label("Users", systemImage: "person.3")
                    }
                    .accessibilityIdentifier("UsersTab")
            }
        } else {
            LoginView(toolkit: toolkit)
        }
    }
}
