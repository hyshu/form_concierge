#if canImport(UIKit)
  import PhotosUI
  import UniformTypeIdentifiers
  import UIKit
  import FormConciergeSwiftUI

  enum UIKitFollowUpAnswerValue: Equatable, Sendable {
    case text(String)
    case single(String)
    case multiple(Set<String>)
    case images([String])
  }

  @MainActor
  enum UIKitComponentFactory {
    static func label(
      _ text: String,
      textStyle: UIFont.TextStyle,
      weight: UIFont.Weight = .regular,
      alignment: NSTextAlignment = .natural
    ) -> UILabel {
      let label = UILabel()
      label.text = text
      label.font = UIFont.systemFont(
        ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize,
        weight: weight
      )
      label.adjustsFontForContentSizeCategory = true
      label.numberOfLines = 0
      label.textAlignment = alignment
      return label
    }

    static func secondaryLabel(
      _ text: String,
      alignment: NSTextAlignment = .natural
    ) -> UILabel {
      let label = label(text, textStyle: .body, alignment: alignment)
      label.textColor = .secondaryLabel
      return label
    }

    static func errorLabel(_ text: String) -> UILabel {
      let label = label(text, textStyle: .body)
      label.textColor = .systemRed
      label.accessibilityTraits.insert(.staticText)
      return label
    }

    static func loadingView(text: String) -> UIView {
      let stack = UIStackView()
      stack.axis = .horizontal
      stack.alignment = .center
      stack.spacing = 10
      stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 32, leading: 8, bottom: 32, trailing: 8)
      stack.isLayoutMarginsRelativeArrangement = true

      let indicator = UIActivityIndicatorView(style: .medium)
      indicator.startAnimating()
      stack.addArrangedSubview(indicator)
      stack.addArrangedSubview(label(text, textStyle: .body))
      return stack
    }

    static func primaryButton(
      title: String,
      loadingTitle: String? = nil,
      isLoading: Bool = false,
      action: @escaping () -> Void
    ) -> UIButton {
      var configuration = UIButton.Configuration.filled()
      configuration.title = isLoading ? (loadingTitle ?? title) : title
      configuration.showsActivityIndicator = isLoading
      configuration.imagePadding = 8
      let button = UIButton(
        configuration: configuration,
        primaryAction: UIAction { _ in action() }
      )
      button.isEnabled = !isLoading
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
      return button
    }

    static func selectionButton(
      title: String,
      selected: Bool,
      enabled: Bool = true,
      multiple: Bool = false,
      action: @escaping () -> Void
    ) -> UIButton {
      var configuration = UIButton.Configuration.plain()
      configuration.title = title
      configuration.titleAlignment = .leading
      configuration.imagePadding = 10
      configuration.baseForegroundColor = .label
      configuration.image = UIImage(
        systemName: selected
          ? (multiple ? "checkmark.square.fill" : "circle.inset.filled")
          : (multiple ? "square" : "circle")
      )
      let button = UIButton(
        configuration: configuration,
        primaryAction: UIAction { _ in action() }
      )
      button.contentHorizontalAlignment = .leading
      button.isEnabled = enabled
      button.accessibilityValue = selected ? "1" : "0"
      button.accessibilityTraits = selected ? [.button, .selected] : [.button]
      return button
    }
  }

  @MainActor
  final class UIKitQuestionView: UIStackView {
    init(
      client: FormConciergeClient,
      question: Question,
      choices: [Choice],
      value: SurveyAnswerValue?,
      locale: String,
      presentingViewController: UIViewController,
      ensureAuthenticated: @escaping () async throws -> Void,
      processImage: ProcessSurveyImage?,
      onChange: @escaping (SurveyAnswerValue, Bool) -> Void
    ) {
      super.init(frame: .zero)
      axis = .vertical
      alignment = .fill
      spacing = 12
      addArrangedSubview(
        UIKitComponentFactory.label(
          question.text(for: locale),
          textStyle: .headline,
          weight: .semibold
        ))

      switch question.type {
      case .textSingle:
        let field = ClosureTextField()
        field.borderStyle = .roundedRect
        field.placeholder = question.placeholder(for: locale)
        if case .text(let text) = value { field.text = text }
        field.onTextChanged = { onChange(.text($0), false) }
        addArrangedSubview(field)

      case .textMultiLine:
        let textView = ClosureTextView()
        if case .text(let text) = value { textView.text = text }
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.layer.borderWidth = 1 / UIScreen.main.scale
        textView.layer.borderColor = UIColor.quaternaryLabel.cgColor
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        textView.onTextChanged = { onChange(.text($0), false) }
        addArrangedSubview(textView)

      case .singleChoice:
        let selectedId: Int?
        if case .single(let choiceId) = value {
          selectedId = choiceId
        } else {
          selectedId = nil
        }
        for choice in choices {
          addArrangedSubview(
            UIKitComponentFactory.selectionButton(
              title: choice.text(for: locale),
              selected: selectedId == choice.id,
              action: { onChange(.single(choice.id), true) }
            ))
        }

      case .multipleChoice:
        let selectedIds: Set<Int>
        if case .multiple(let choiceIds) = value {
          selectedIds = choiceIds
        } else {
          selectedIds = []
        }
        let reachedMaximum = question.maxSelected.map { selectedIds.count >= $0 } ?? false
        for choice in choices {
          let selected = selectedIds.contains(choice.id)
          addArrangedSubview(
            UIKitComponentFactory.selectionButton(
              title: choice.text(for: locale),
              selected: selected,
              enabled: selected || !reachedMaximum,
              multiple: true,
              action: {
                var next = selectedIds
                if selected {
                  next.remove(choice.id)
                } else {
                  next.insert(choice.id)
                }
                onChange(.multiple(next), true)
              }
            ))
        }

      case .imageUpload:
        let fileKeys: [String]
        if case .images(let keys) = value {
          fileKeys = keys
        } else {
          fileKeys = []
        }
        addArrangedSubview(
          UIKitImageUploadView(
            client: client,
            maxFiles: question.maxSelected ?? 3,
            fileKeys: fileKeys,
            locale: locale,
            presentingViewController: presentingViewController,
            ensureAuthenticated: ensureAuthenticated,
            processImage: processImage,
            onChange: { onChange(.images($0), false) }
          ))
      }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

  @MainActor
  final class UIKitFollowUpItemView: UIStackView {
    init(
      client: FormConciergeClient,
      item: FollowUpItem,
      value: UIKitFollowUpAnswerValue?,
      locale: String,
      presentingViewController: UIViewController,
      ensureAuthenticated: @escaping () async throws -> Void,
      processImage: ProcessSurveyImage?,
      onChange: @escaping (UIKitFollowUpAnswerValue, Bool) -> Void
    ) {
      super.init(frame: .zero)
      axis = .vertical
      alignment = .fill
      spacing = 12
      addArrangedSubview(
        UIKitComponentFactory.label(item.text, textStyle: .headline, weight: .semibold))

      switch item.type {
      case .textSingle:
        let field = ClosureTextField()
        field.borderStyle = .roundedRect
        field.placeholder = item.placeholder
        if case .text(let text) = value { field.text = text }
        field.onTextChanged = { onChange(.text($0), false) }
        addArrangedSubview(field)

      case .textMultiLine:
        let textView = ClosureTextView()
        if case .text(let text) = value { textView.text = text }
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.layer.borderWidth = 1 / UIScreen.main.scale
        textView.layer.borderColor = UIColor.quaternaryLabel.cgColor
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        textView.onTextChanged = { onChange(.text($0), false) }
        addArrangedSubview(textView)

      case .singleChoice:
        let selectedId: String?
        if case .single(let choiceId) = value {
          selectedId = choiceId
        } else {
          selectedId = nil
        }
        for choice in item.choices {
          addArrangedSubview(
            UIKitComponentFactory.selectionButton(
              title: choice.label,
              selected: selectedId == choice.id,
              action: { onChange(.single(choice.id), true) }
            ))
        }

      case .multipleChoice:
        let selectedIds: Set<String>
        if case .multiple(let choiceIds) = value {
          selectedIds = choiceIds
        } else {
          selectedIds = []
        }
        for choice in item.choices {
          let selected = selectedIds.contains(choice.id)
          addArrangedSubview(
            UIKitComponentFactory.selectionButton(
              title: choice.label,
              selected: selected,
              multiple: true,
              action: {
                var next = selectedIds
                if selected {
                  next.remove(choice.id)
                } else {
                  next.insert(choice.id)
                }
                onChange(.multiple(next), true)
              }
            ))
        }

      case .imageUpload:
        let fileKeys: [String]
        if case .images(let keys) = value {
          fileKeys = keys
        } else {
          fileKeys = []
        }
        addArrangedSubview(
          UIKitImageUploadView(
            client: client,
            maxFiles: item.maxFiles ?? 1,
            fileKeys: fileKeys,
            locale: locale,
            presentingViewController: presentingViewController,
            ensureAuthenticated: ensureAuthenticated,
            processImage: processImage,
            onChange: { onChange(.images($0), false) }
          ))
      }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

  @MainActor
  private final class ClosureTextField: UITextField {
    var onTextChanged: ((String) -> Void)?

    override init(frame: CGRect) {
      super.init(frame: frame)
      addTarget(self, action: #selector(textChanged), for: .editingChanged)
      font = .preferredFont(forTextStyle: .body)
      adjustsFontForContentSizeCategory = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    @objc private func textChanged() {
      onTextChanged?(text ?? "")
    }
  }

  @MainActor
  private final class ClosureTextView: UITextView, UITextViewDelegate {
    var onTextChanged: ((String) -> Void)?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
      super.init(frame: frame, textContainer: textContainer)
      delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func textViewDidChange(_ textView: UITextView) {
      onTextChanged?(textView.text)
    }
  }

  @MainActor
  private final class UIKitImageUploadView: UIStackView, PHPickerViewControllerDelegate {
    private let client: FormConciergeClient
    private let maxFiles: Int
    private let locale: String
    private weak var presentingViewController: UIViewController?
    private let ensureAuthenticated: () async throws -> Void
    private let processImage: ProcessSurveyImage?
    private let onChange: ([String]) -> Void
    private var fileKeys: [String]
    private var previews: [String: Data] = [:]
    private var isUploading = false
    private var localError: String?

    init(
      client: FormConciergeClient,
      maxFiles: Int,
      fileKeys: [String],
      locale: String,
      presentingViewController: UIViewController,
      ensureAuthenticated: @escaping () async throws -> Void,
      processImage: ProcessSurveyImage?,
      onChange: @escaping ([String]) -> Void
    ) {
      self.client = client
      self.maxFiles = max(maxFiles, 1)
      self.fileKeys = fileKeys
      self.locale = locale
      self.presentingViewController = presentingViewController
      self.ensureAuthenticated = ensureAuthenticated
      self.processImage = processImage
      self.onChange = onChange
      super.init(frame: .zero)
      axis = .vertical
      alignment = .fill
      spacing = 12
      render()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    private func render() {
      removeAllArrangedSubviews()

      if !fileKeys.isEmpty {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.heightAnchor.constraint(equalToConstant: 104).isActive = true
        let previewsStack = UIStackView()
        previewsStack.axis = .horizontal
        previewsStack.alignment = .center
        previewsStack.spacing = 12
        previewsStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(previewsStack)
        NSLayoutConstraint.activate([
          previewsStack.topAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
          previewsStack.leadingAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.leadingAnchor),
          previewsStack.trailingAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.trailingAnchor),
          previewsStack.bottomAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -8),
          previewsStack.heightAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.heightAnchor, constant: -16),
        ])
        for key in fileKeys {
          previewsStack.addArrangedSubview(previewView(for: key))
        }
        addArrangedSubview(scrollView)
      }

      let countText = FormContentMessages.text(locale, "maxPhotosReached")
        .replacingOccurrences(of: "{count}", with: "\(maxFiles)")
      let countLabel = UIKitComponentFactory.label(countText, textStyle: .footnote)
      countLabel.textColor = .secondaryLabel
      addArrangedSubview(countLabel)

      var configuration = UIButton.Configuration.bordered()
      configuration.title = FormContentMessages.text(
        locale,
        isUploading ? "uploadingPhotos" : "addPhotos"
      )
      configuration.image = UIImage(systemName: "photo.badge.plus")
      configuration.imagePadding = 8
      configuration.showsActivityIndicator = isUploading
      let addButton = UIButton(
        configuration: configuration,
        primaryAction: UIAction { [weak self] _ in self?.presentPicker() }
      )
      addButton.isEnabled = !isUploading && fileKeys.count < maxFiles
      addArrangedSubview(addButton)

      if let localError {
        let errorLabel = UIKitComponentFactory.errorLabel(localError)
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        addArrangedSubview(errorLabel)
      }
    }

    private func previewView(for key: String) -> UIView {
      let container = UIView()
      container.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        container.widthAnchor.constraint(equalToConstant: 96),
        container.heightAnchor.constraint(equalToConstant: 96),
      ])

      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
      imageView.layer.cornerRadius = 8
      imageView.backgroundColor = .secondarySystemBackground
      imageView.tintColor = .secondaryLabel
      imageView.image = previews[key].flatMap(UIImage.init(data:)) ?? UIImage(systemName: "photo")
      imageView.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(imageView)

      var configuration = UIButton.Configuration.plain()
      configuration.image = UIImage(systemName: "xmark.circle.fill")
      configuration.baseForegroundColor = .label
      configuration.contentInsets = .zero
      let removeButton = UIButton(
        configuration: configuration,
        primaryAction: UIAction { [weak self] _ in self?.remove(key: key) }
      )
      removeButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.75)
      removeButton.layer.cornerRadius = 12
      removeButton.accessibilityLabel = FormContentMessages.text(locale, "removePhoto")
      removeButton.isEnabled = !isUploading
      removeButton.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(removeButton)

      NSLayoutConstraint.activate([
        imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
        imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
        imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        removeButton.topAnchor.constraint(equalTo: container.topAnchor),
        removeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        removeButton.widthAnchor.constraint(equalToConstant: 28),
        removeButton.heightAnchor.constraint(equalToConstant: 28),
      ])
      return container
    }

    private func remove(key: String) {
      fileKeys.removeAll { $0 == key }
      previews[key] = nil
      localError = nil
      onChange(fileKeys)
      render()
    }

    private func presentPicker() {
      guard let presentingViewController, fileKeys.count < maxFiles else { return }
      var configuration = PHPickerConfiguration(photoLibrary: .shared())
      configuration.filter = .images
      configuration.selectionLimit = maxFiles - fileKeys.count
      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      presentingViewController.present(picker, animated: true)
    }

    func picker(
      _ picker: PHPickerViewController,
      didFinishPicking results: [PHPickerResult]
    ) {
      picker.dismiss(animated: true)
      guard !results.isEmpty else { return }
      Task { [weak self] in
        await self?.upload(results: results)
      }
    }

    private func upload(results: [PHPickerResult]) async {
      isUploading = true
      localError = nil
      render()
      defer {
        isUploading = false
        render()
      }

      do {
        try await ensureAuthenticated()
        for result in results {
          if fileKeys.count >= maxFiles { break }
          let loaded = try await loadImage(from: result.itemProvider)
          let prepared: SurveyImagePayload?
          if let processImage {
            prepared = try await processImage(loaded)
          } else {
            prepared = defaultImagePayload(loaded)
          }
          guard let prepared, !prepared.data.isEmpty else { continue }
          let upload = try await client.uploadMedia(
            data: prepared.data,
            contentType: prepared.contentType
          )
          fileKeys.append(upload.key)
          previews[upload.key] = prepared.data
          onChange(fileKeys)
        }
      } catch {
        localError = FormContentMessages.text(locale, "photoUploadFailed")
      }
    }

    private func loadImage(from provider: NSItemProvider) async throws -> SurveyImagePayload {
      let type = provider.registeredContentTypes.first { $0.conforms(to: .image) } ?? .image
      let data: Data = try await withCheckedThrowingContinuation { continuation in
        provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
          if let error {
            continuation.resume(throwing: error)
          } else if let data {
            continuation.resume(returning: data)
          } else {
            continuation.resume(throwing: FormConciergeError.invalidResponse)
          }
        }
      }
      return SurveyImagePayload(data: data, contentType: contentType(for: type))
    }

    private func contentType(for type: UTType) -> String {
      if type.conforms(to: .png) { return "image/png" }
      if type.conforms(to: .gif) { return "image/gif" }
      if type.conforms(to: .webP) { return "image/webp" }
      if type.conforms(to: .jpeg) { return "image/jpeg" }
      return type.preferredMIMEType ?? "image/jpeg"
    }

    private func defaultImagePayload(_ payload: SurveyImagePayload) -> SurveyImagePayload {
      let allowed = ["image/jpeg", "image/png", "image/webp", "image/gif"]
      if allowed.contains(payload.contentType) {
        return payload
      }
      if let image = UIImage(data: payload.data),
        let jpeg = image.jpegData(compressionQuality: 0.85)
      {
        return SurveyImagePayload(data: jpeg, contentType: "image/jpeg")
      }
      return SurveyImagePayload(data: payload.data, contentType: "image/jpeg")
    }
  }

  @MainActor
  extension UIStackView {
    func removeAllArrangedSubviews() {
      for view in arrangedSubviews {
        removeArrangedSubview(view)
        view.removeFromSuperview()
      }
    }
  }
#endif
