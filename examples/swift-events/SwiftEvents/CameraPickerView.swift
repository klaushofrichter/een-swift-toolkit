import SwiftUI
import EENSwiftToolkit

struct CameraPickerView: View {
    let toolkit: EENToolkit
    @Binding var selectedCameraId: String?
    @Binding var selectedCameraName: String?
    @Binding var cameras: [(id: String, name: String)]

    @State private var isLoading = false
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Image(systemName: "video")
                    .foregroundColor(.orange)
                if let name = selectedCameraName {
                    Text(name)
                        .lineLimit(1)
                } else {
                    Text("Select Camera")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .accessibilityIdentifier("CameraPickerButton")
        .sheet(isPresented: $showPicker) {
            cameraListSheet
        }
        .task {
            await loadCameras()
        }
    }

    private var cameraListSheet: some View {
        NavigationStack {
            Group {
                if isLoading && cameras.isEmpty {
                    ProgressView("Loading cameras...")
                } else {
                    List(cameras, id: \.id) { camera in
                        Button {
                            selectedCameraId = camera.id
                            selectedCameraName = camera.name
                            showPicker = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(camera.name)
                                        .foregroundColor(.primary)
                                    Text(camera.id)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .monospaced()
                                }
                                Spacer()
                                if camera.id == selectedCameraId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cameras")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showPicker = false }
                }
            }
        }
    }

    private func loadCameras() async {
        guard cameras.isEmpty else { return }
        isLoading = true
        do {
            var allCameras: [(id: String, name: String)] = []
            var pageToken: String? = nil
            repeat {
                let params = ListCamerasParams(pageSize: 100, pageToken: pageToken)
                let response = try await toolkit.cameras.list(params: params)
                allCameras.append(contentsOf: response.results.map { ($0.id, $0.name) })
                pageToken = response.nextPageToken
            } while pageToken != nil
            cameras = allCameras

            if selectedCameraId == nil, let first = cameras.first {
                selectedCameraId = first.id
                selectedCameraName = first.name
            }
        } catch {
            print("[CameraPicker] Error loading cameras: \(error)")
        }
        isLoading = false
    }
}
