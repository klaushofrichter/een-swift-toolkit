import SwiftUI
import EENApiToolkit

struct MainTabView: View {
    let toolkit: EENToolkit
    @EnvironmentObject var authState: AuthState
    @State private var selectedCameraId: String?
    @State private var selectedCameraName: String?
    @State private var cameras: [(id: String, name: String)] = []

    var body: some View {
        TabView {
            NavigationStack {
                EventTypesView(toolkit: toolkit, cameraId: $selectedCameraId)
                    .safeAreaInset(edge: .top) {
                        cameraPicker
                    }
                    .navigationTitle("Event Types")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { signOutButton }
            }
            .tabItem {
                Label("Types", systemImage: "list.bullet")
            }
            .accessibilityIdentifier("TypesTab")

            NavigationStack {
                EventHistoryView(toolkit: toolkit, cameraId: $selectedCameraId)
                    .safeAreaInset(edge: .top) {
                        cameraPicker
                    }
                    .navigationTitle("Event History")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { signOutButton }
            }
            .tabItem {
                Label("History", systemImage: "clock")
            }
            .accessibilityIdentifier("HistoryTab")

            NavigationStack {
                LiveEventsView(toolkit: toolkit, cameraId: $selectedCameraId, cameraName: $selectedCameraName)
                    .safeAreaInset(edge: .top) {
                        cameraPicker
                    }
                    .navigationTitle("Live Events")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { signOutButton }
            }
            .tabItem {
                Label("Live", systemImage: "bolt")
            }
            .accessibilityIdentifier("LiveTab")
        }
        .tint(.orange)
    }

    private var cameraPicker: some View {
        CameraPickerView(
            toolkit: toolkit,
            selectedCameraId: $selectedCameraId,
            selectedCameraName: $selectedCameraName,
            cameras: $cameras
        )
        .padding(.horizontal)
        .padding(.bottom, 4)
        .background(Color(.systemBackground))
    }

    private var signOutButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Sign Out") {
                Task {
                    try? await toolkit.auth.revokeToken()
                }
            }
            .accessibilityIdentifier("SignOutButton")
        }
    }
}
