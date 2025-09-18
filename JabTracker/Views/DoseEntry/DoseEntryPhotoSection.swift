//
//  DoseEntryPhotoSection.swift
//  JabTracker
//
//  Photo section view for dose entry sheet
//  Handles photo picker, preview, and photo management functionality
//

import SwiftUI
import PhotosUI

/// Photo section for dose entry with picker and preview functionality
struct DoseEntryPhotoSection: View {
    @Binding var dosePhotoData: Data?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var showingPhotoOptions: Bool
    let isSkipped: Bool

    var body: some View {
        if !isSkipped {
            Section {
                photoContent
            } header: {
                Text("Photo (Optional)")
            }
            .photosPicker(isPresented: $showingPhotoOptions, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        dosePhotoData = data
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var photoContent: some View {
        if let photoData = dosePhotoData, let uiImage = UIImage(data: photoData) {
            VStack(alignment: .leading, spacing: 8) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .accessibilityIdentifier("dose-entry-photo-preview")

                Button("Change Photo") {
                    showingPhotoOptions = true
                }
                .accessibilityIdentifier("dose-entry-change-photo")

                Button("Remove Photo", role: .destructive) {
                    dosePhotoData = nil
                    selectedPhotoItem = nil
                }
                .accessibilityIdentifier("dose-entry-remove-photo")
            }
        } else {
            Button("Add Photo") {
                showingPhotoOptions = true
            }
            .accessibilityIdentifier("dose-entry-add-photo")
        }
    }
}
