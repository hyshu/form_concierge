import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
  import PhotosUI
  import UIKit

  struct SurveyImagePickerButton: View {
    let selectionLimit: Int
    let isDisabled: Bool
    let label: String
    let onPick: ([SurveyImagePayload]) -> Void

    @State private var isPresented = false

    var body: some View {
      Button {
        isPresented = true
      } label: {
        Label(label, systemImage: "photo.badge.plus")
      }
      .disabled(isDisabled || selectionLimit <= 0)
      .sheet(isPresented: $isPresented) {
        PHPickerView(
          selectionLimit: selectionLimit,
          onPick: { images in
            isPresented = false
            onPick(images)
          },
          onCancel: { isPresented = false }
        )
      }
    }
  }

  private struct PHPickerView: UIViewControllerRepresentable {
    let selectionLimit: Int
    let onPick: ([SurveyImagePayload]) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
      Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
      var configuration = PHPickerConfiguration(photoLibrary: .shared())
      configuration.filter = .images
      configuration.selectionLimit = selectionLimit
      configuration.selection = .ordered
      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = context.coordinator
      return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
      private let parent: PHPickerView

      init(parent: PHPickerView) {
        self.parent = parent
      }

      func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
          parent.onCancel()
          return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var images = [SurveyImagePayload?](repeating: nil, count: results.count)

        for (index, result) in results.enumerated() {
          guard let typeIdentifier = imageTypeIdentifier(for: result.itemProvider) else { continue }
          group.enter()
          result.itemProvider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) {
            data, _ in
            defer { group.leave() }
            guard let data, !data.isEmpty else { return }
            let contentType = UTType(typeIdentifier)?.preferredMIMEType ?? "image/jpeg"
            lock.lock()
            images[index] = SurveyImagePayload(data: data, contentType: contentType)
            lock.unlock()
          }
        }

        group.notify(queue: .main) { [parent] in
          parent.onPick(images.compactMap { $0 })
        }
      }

      private func imageTypeIdentifier(for provider: NSItemProvider) -> String? {
        provider.registeredTypeIdentifiers.first {
          UTType($0)?.conforms(to: .image) == true
        }
      }
    }
  }
#elseif canImport(AppKit)
  import PhotosUI

  struct SurveyImagePickerButton: View {
    let selectionLimit: Int
    let isDisabled: Bool
    let label: String
    let onPick: ([SurveyImagePayload]) -> Void

    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
      PhotosPicker(
        selection: $pickerItems,
        maxSelectionCount: selectionLimit,
        matching: .images,
        photoLibrary: .shared()
      ) {
        Label(label, systemImage: "photo.badge.plus")
      }
      .disabled(isDisabled || selectionLimit <= 0)
      .onChange(of: pickerItems) { items in
        guard !items.isEmpty else { return }
        Task { await load(items: items) }
      }
    }

    private func load(items: [PhotosPickerItem]) async {
      defer { pickerItems = [] }
      var images: [SurveyImagePayload] = []
      for item in items {
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else {
          continue
        }
        let contentType = item.supportedContentTypes.first?.preferredMIMEType ?? "image/jpeg"
        images.append(SurveyImagePayload(data: data, contentType: contentType))
      }
      onPick(images)
    }
  }
#endif
