//
//  DoseEntryPhotoSection.swift
//  JabTracker
//
//  Photo section view for dose entry sheet
//  Handles photo picker, preview, and photo management functionality
//

import PhotosUI
import SwiftUI

/// Photo section for dose entry with picker and preview functionality
struct DoseEntryPhotoSection: View {
  @Binding var dosePhotoData: Data?
  @Binding var selectedPhotoItem: PhotosPickerItem?
  @Binding var showingPhotoOptions: Bool
  let isSkipped: Bool

  var body: some View {
    if !self.isSkipped {
      Section {
        self.photoContent
      } header: {
        Text("Photo (Optional)")
      }
      .photosPicker(
        isPresented: self.$showingPhotoOptions, selection: self.$selectedPhotoItem,
        matching: .images
      )
      .onChange(of: self.selectedPhotoItem) { _, newItem in
        Task {
          if let data = try? await newItem?.loadTransferable(type: Data.self) {
            self.dosePhotoData = data
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
          self.showingPhotoOptions = true
        }
        .accessibilityIdentifier("dose-entry-change-photo")

        Button("Remove Photo", role: .destructive) {
          self.dosePhotoData = nil
          self.selectedPhotoItem = nil
        }
        .accessibilityIdentifier("dose-entry-remove-photo")
      }
    } else {
      Button("Add Photo") {
        self.showingPhotoOptions = true
      }
      .accessibilityIdentifier("dose-entry-add-photo")
    }
  }
}
