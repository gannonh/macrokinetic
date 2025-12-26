//
//  QuickPhotoSheet.swift
//  JabTracker
//
//  Quick progress photo entry sheet accessible from ShortcutsSheet.
//

import OSLog
import PhotosUI
import SwiftData
import SwiftUI

/// Quick photo entry sheet for logging progress photos via shortcuts
struct QuickPhotoSheet: View {
    // MARK: - Constants

    /// Maximum image size for CloudKit (1MB)
    private static let maxImageSizeBytes = 1_000_000

    /// Initial JPEG compression quality
    private static let initialCompressionQuality: CGFloat = 0.8

    /// Minimum compression quality before giving up
    private static let minCompressionQuality: CGFloat = 0.1

    /// Compression step size
    private static let compressionStep: CGFloat = 0.1

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var user: User? { users.first }

    // MARK: - State

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoType: PhotoType = .front
    @State private var timestamp: Date = Date()
    @State private var notes: String = ""
    @State private var showingPhotoPicker: Bool = false
    @State private var showingCamera: Bool = false
    @State private var showingSourceSelection: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false

    // MARK: - Logger

    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "QuickPhotoSheet"
    )

    // MARK: - Computed Properties

    private var photoService: ProgressPhotoService? {
        AppServices.shared.progressPhotoService
    }

    /// Check if photo data is available for saving and photo types are enabled
    private var canSave: Bool {
        photoData != nil && hasEnabledPhotoTypes
    }

    /// Check if camera is available on this device
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// Photo types enabled based on user preferences
    private var enabledPhotoTypes: [PhotoType] {
        guard let user = user else {
            // Fall back to defaults if no user
            return PhotoType.allCases.filter { photoType in
                User.defaultEnabledPhotoTypes.contains(photoType.rawValue)
            }
        }
        return PhotoType.allCases.filter { photoType in
            user.enabledPhotoTypes.contains(photoType.rawValue)
        }
    }

    /// True if at least one photo type is enabled
    private var hasEnabledPhotoTypes: Bool {
        !enabledPhotoTypes.isEmpty
    }

    // MARK: - Accessibility Identifiers

    static let sheetIdentifier = "quick-photo-sheet"
    static let photoPreviewIdentifier = "photo-preview"
    static let addPhotoButtonIdentifier = "add-photo-button"
    static let takePhotoButtonIdentifier = "take-photo-button"
    static let choosePhotoButtonIdentifier = "choose-photo-button"
    static let changePhotoButtonIdentifier = "change-photo-button"
    static let removePhotoButtonIdentifier = "remove-photo-button"
    static let photoTypePickerIdentifier = "photo-type-picker"
    static let datePickerIdentifier = "date-picker"
    static let saveButtonIdentifier = "save-photo-button"
    static let cancelButtonIdentifier = "cancel-button"

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                if hasEnabledPhotoTypes {
                    photoSection
                    photoTypeSection
                    dateSection
                    notesSection
                } else {
                    noPhotoTypesEnabledSection
                }
            }
            .navigationTitle("Progress Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier(Self.cancelButtonIdentifier)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!canSave || isSaving)
                    .accessibilityIdentifier(Self.saveButtonIdentifier)
                }
            }
        }
        .presentationDetents([.large])
        .accessibilityIdentifier(Self.sheetIdentifier)
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                handleCameraImage(image)
            }
            .ignoresSafeArea()
        }
        .confirmationDialog("Add Photo", isPresented: $showingSourceSelection) {
            if isCameraAvailable {
                Button("Take Photo") {
                    showingCamera = true
                }
            }
            Button("Choose from Library") {
                showingPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await loadPhoto(from: newItem) }
        }
        .errorAlert(isPresented: $showingError, message: errorMessage)
    }

    // MARK: - Sections

    @ViewBuilder
    private var photoSection: some View {
        Section {
            if let data = photoData, let uiImage = UIImage(data: data) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                        .accessibilityIdentifier(Self.photoPreviewIdentifier)

                    Button("Change Photo") {
                        showingSourceSelection = true
                    }
                    .accessibilityIdentifier(Self.changePhotoButtonIdentifier)

                    Button("Remove Photo", role: .destructive) {
                        photoData = nil
                        selectedPhotoItem = nil
                    }
                    .accessibilityIdentifier(Self.removePhotoButtonIdentifier)
                }
            } else {
                // Show both options when no photo selected
                VStack(spacing: 12) {
                    if isCameraAvailable {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier(Self.takePhotoButtonIdentifier)
                    }

                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(Self.choosePhotoButtonIdentifier)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Progress Photo")
        }
    }

    private var photoTypeSection: some View {
        Section("Photo Type") {
            Picker("Type", selection: $photoType) {
                ForEach(enabledPhotoTypes, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(Self.photoTypePickerIdentifier)
        }
    }

    private var dateSection: some View {
        Section("Date & Time") {
            DatePicker(
                "When",
                selection: $timestamp,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .accessibilityIdentifier(Self.datePickerIdentifier)
        }
    }

    private var notesSection: some View {
        Section("Notes (optional)") {
            TextField("Add notes", text: $notes)
        }
    }

    private var noPhotoTypesEnabledSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("No Photo Types Enabled", systemImage: "camera")
                    .font(.headline)
                Text(
                    "You haven't enabled any progress photo types for tracking. "
                        + "Go to More → Feature Settings → Body Metrics Visibility "
                        + "to choose which photo types to capture."
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("no-photo-types-enabled-section")
    }

    // MARK: - Actions

    private func handleCameraImage(_ image: UIImage?) {
        guard let image = image else { return }

        if let data = image.jpegData(compressionQuality: Self.initialCompressionQuality) {
            if let compressed = compressImage(data) {
                photoData = compressed
                logger.debug("Camera photo compressed: \(compressed.count) bytes")
            } else {
                photoData = data
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let compressed = compressImage(data) {
                    await MainActor.run {
                        photoData = compressed
                    }
                    logger.debug("Loaded and compressed photo: \(compressed.count) bytes")
                } else {
                    logger.warning("Failed to compress photo, using original")
                    await MainActor.run {
                        photoData = data
                    }
                }
            }
        } catch {
            logger.error("Failed to load photo: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load photo: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    /// Compress image to JPEG with target size under 1MB for CloudKit
    /// Uses progressive quality reduction, then resizes if still too large
    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        // Try compression first
        if let result = compressWithQuality(image: image) {
            return result
        }

        // If compression alone doesn't work, resize and compress
        return resizeAndCompress(image: image)
    }

    /// Attempt compression with progressively lower quality
    private func compressWithQuality(image: UIImage) -> Data? {
        var compression: CGFloat = Self.initialCompressionQuality
        var compressed = image.jpegData(compressionQuality: compression)

        while let currentData = compressed,
            currentData.count > Self.maxImageSizeBytes,
            compression > Self.minCompressionQuality
        {
            compression -= Self.compressionStep
            compressed = image.jpegData(compressionQuality: compression)
        }

        // Return only if under target size
        if let result = compressed, result.count <= Self.maxImageSizeBytes {
            return result
        }
        return nil
    }

    /// Resize image and compress to meet size target
    private func resizeAndCompress(image: UIImage) -> Data? {
        var currentImage = image
        var scale: CGFloat = 0.9

        // Progressively reduce dimensions until under target size
        while scale > 0.1 {
            let newSize = CGSize(
                width: currentImage.size.width * scale,
                height: currentImage.size.height * scale
            )

            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { _ in
                currentImage.draw(in: CGRect(origin: .zero, size: newSize))
            }

            // Try compressing the resized image
            if let compressed = resizedImage.jpegData(compressionQuality: Self.initialCompressionQuality),
                compressed.count <= Self.maxImageSizeBytes
            {
                logger.debug(
                    "Resized image to \(Int(newSize.width))x\(Int(newSize.height)) (\(compressed.count) bytes)")
                return compressed
            }

            // Try lower quality on resized image
            if let result = compressWithQuality(image: resizedImage) {
                logger.debug("Resized and compressed to \(result.count) bytes")
                return result
            }

            currentImage = resizedImage
            scale = 0.8  // More aggressive reduction on subsequent passes
        }

        logger.warning("Could not compress image below \(Self.maxImageSizeBytes) bytes")
        // Return best effort - the smallest we could achieve
        return currentImage.jpegData(compressionQuality: Self.minCompressionQuality)
    }

    @MainActor
    private func save() async {
        guard let service = photoService else {
            logger.error("ProgressPhotoService not initialized")
            errorMessage = "Unable to save photo. Please restart the app and try again."
            showingError = true
            return
        }

        guard let imageData = photoData else {
            errorMessage = "Please select a photo"
            showingError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await service.logPhoto(
                imageData: imageData,
                photoType: photoType,
                timestamp: timestamp,
                notes: notes.isEmpty ? nil : notes
            )

            logger.info("Logged progress photo (\(photoType.displayName))")
            dismiss()
        } catch {
            logger.error("Failed to log photo: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Camera Picker

/// UIImagePickerController wrapper for camera access
struct CameraPicker: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage?) -> Void

        init(onImageCaptured: @escaping (UIImage?) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            onImageCaptured(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImageCaptured(nil)
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    QuickPhotoSheet()
        .modelContainer(DataController.preview.container)
}
