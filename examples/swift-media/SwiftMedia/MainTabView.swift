import SwiftUI
import EENApiToolkit

struct MainTabView: View {
    let toolkit: EENToolkit
    @EnvironmentObject var authState: AuthState
    @State private var selectedCameraId: String?
    @State private var selectedCameraName: String?
    @State private var cameras: [(id: String, name: String)] = []
    @State private var selectedDate = Date().addingTimeInterval(-3600)

    var body: some View {
        TabView {
            NavigationStack {
                LiveImageView(toolkit: toolkit, cameraId: $selectedCameraId)
                    .safeAreaInset(edge: .top) {
                        cameraPicker
                    }
                    .navigationTitle("Live Image")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { signOutButton }
            }
            .tabItem {
                Label("Live", systemImage: "video")
            }
            .accessibilityIdentifier("LiveTab")

            NavigationStack {
                RecordedImageView(toolkit: toolkit, cameraId: $selectedCameraId, selectedDate: $selectedDate)
                    .safeAreaInset(edge: .top) {
                        cameraPicker
                    }
                    .navigationTitle("Recorded Image")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { signOutButton }
            }
            .tabItem {
                Label("Recorded", systemImage: "photo")
            }
            .accessibilityIdentifier("RecordedTab")

            NavigationStack {
                RecordedVideoView(toolkit: toolkit, cameraId: $selectedCameraId, selectedDate: $selectedDate)
                    .safeAreaInset(edge: .top) {
                        cameraPicker
                    }
                    .navigationTitle("Recorded Video")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { signOutButton }
            }
            .tabItem {
                Label("Video", systemImage: "play.rectangle")
            }
            .accessibilityIdentifier("VideoTab")
        }
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
