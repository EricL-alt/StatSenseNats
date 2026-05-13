import SwiftUI
import PhotosUI
import SwiftData

struct CaptureView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @EnvironmentObject var graphAnalyzer: GraphAnalyzer
    @Environment(\.modelContext) private var modelContext
    @StateObject private var cameraService = CameraService.create()

    @State private var showingImagePicker = false
    @State private var showingResults = false
    @State private var selectedImage: UIImage?
    @State private var isFlashOn = false

    var body: some View {
        NavigationStack {
            ZStack {
                if cameraService.isAuthorized {
                    CameraPreviewView(session: cameraService.session)
                        .ignoresSafeArea()
                } else {
                    CameraPermissionView()
                }

                VStack {

                    topBar

                    Spacer()

                    if graphAnalyzer.isAnalyzing {
                        analysisProgressView
                    }

                    captureControls
                }
            }
            .navigationTitle("StatSense")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cameraService.startSession()
            }
            .onDisappear {
                cameraService.stopSession()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showingResults) {
                if let result = graphAnalyzer.currentResult {
                    ResultsView(result: result)
                }
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    analyzeImage(image)
                }
            }
            .alert("Analysis Error", isPresented: Binding<Bool>(
                get: { graphAnalyzer.errorMessage != nil || cameraService.error != nil },
                set: { if !$0 {
                    graphAnalyzer.errorMessage = nil
                    cameraService.error = nil
                } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let message = graphAnalyzer.errorMessage {
                    Text(message)
                } else if let cameraError = cameraService.error {
                    Text(cameraError.localizedDescription)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            AccessibilityModeIndicator(mode: accessibilityManager.preferences.primaryMode)
            Spacer()

            Button(action: { isFlashOn.toggle() }) {
                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .accessibilityLabel(isFlashOn ? "Flash on" : "Flash off")
        }
        .padding()
    }

    private var captureControls: some View {
        HStack(spacing: 40) {
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Choose from photo library")

            Button(action: capturePhoto) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(AccessibleColors.primary)
                        .frame(width: 65, height: 65)
                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Capture and analyze graph")
            .disabled(graphAnalyzer.isAnalyzing)

            ModeSwitcherButton()
        }
        .padding(.bottom, 40)
    }

    private var analysisProgressView: some View {
        VStack(spacing: 15) {
            ProgressView(value: graphAnalyzer.analysisProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: AccessibleColors.primary))
                .frame(width: 200)

            Text("Analyzing graph...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
    }

    private func capturePhoto() {
        accessibilityManager.playHaptic(.attention)

        cameraService.capturePhoto { image in
            if let capturedImage = image {
                analyzeImage(capturedImage)
            } else {
                graphAnalyzer.errorMessage = "Failed to capture photo. Please check camera permissions or try again."
            }
        }
    }

    private func analyzeImage(_ image: UIImage) {
        Task {
            if let result = await graphAnalyzer.analyzeImage(image, language: accessibilityManager.preferences.language) {
                if let compressedData = image.jpegData(compressionQuality: 0.8) {
                    do {
                        let savedGraph = try SavedGraph(imageData: compressedData, interpretationResult: result)
                        modelContext.insert(savedGraph)
                        try modelContext.save()
                    } catch {
                        print("Failed to save graph to history: \(error)")
                    }
                }

                showingResults = true
                accessibilityManager.playHaptic(.success)

                if accessibilityManager.preferences.speechSettings.autoPlay {
                    accessibilityManager.speak(graphAnalyzer.currentResult?.summary ?? "Analysis complete")
                }
            }
        }
    }
}

struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(AccessibleColors.primary)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("StatSense needs camera access to capture and analyze graphs.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

