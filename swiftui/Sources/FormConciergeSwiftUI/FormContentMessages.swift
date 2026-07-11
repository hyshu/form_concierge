import Foundation

enum FormContentMessages {
  static func text(_ locale: String, _ key: String) -> String {
    let localized = messages[normalizeFormContentLocale(locale)]
      ?? messages[defaultFormContentLocale]
    return localized?[key]
      ?? messages[defaultFormContentLocale]?[key]
      ?? key
  }

  static func requiredQuestion(_ locale: String, question: String) -> String {
    text(locale, "requiredQuestion").replacingOccurrences(of: "{question}", with: question)
  }

  static func minCharacters(_ locale: String, question: String, count: Int) -> String {
    text(locale, "minCharacters")
      .replacingOccurrences(of: "{question}", with: question)
      .replacingOccurrences(of: "{count}", with: "\(count)")
  }

  static func maxCharacters(_ locale: String, question: String, count: Int) -> String {
    text(locale, "maxCharacters")
      .replacingOccurrences(of: "{question}", with: question)
      .replacingOccurrences(of: "{count}", with: "\(count)")
  }

  static func minChoices(_ locale: String, question: String, count: Int) -> String {
    text(locale, "minChoices")
      .replacingOccurrences(of: "{question}", with: question)
      .replacingOccurrences(of: "{count}", with: "\(count)")
  }

  static func maxChoices(_ locale: String, question: String, count: Int) -> String {
    text(locale, "maxChoices")
      .replacingOccurrences(of: "{question}", with: question)
      .replacingOccurrences(of: "{count}", with: "\(count)")
  }

  static func submittedWithTitle(_ locale: String, title: String) -> String {
    text(locale, "submittedWithTitle").replacingOccurrences(of: "{title}", with: title)
  }
}

private let messages: [String: [String: String]] = [
  "en": [
    "loadingSurvey": "Loading survey...",
    "submit": "Submit",
    "submitting": "Submitting...",
    "select": "Select",
    "thankYou": "Thank you!",
    "submittedWithTitle": "Your response to \"{title}\" has been submitted.",
    "done": "Done",
    "surveyUnavailable": "Survey unavailable",
    "tryAgainLater": "Please try again later.",
    "requiredQuestion": "{question} is required.",
    "minCharacters": "{question} must be at least {count} characters.",
    "maxCharacters": "{question} must be at most {count} characters.",
    "minChoices": "{question} requires at least {count} choices.",
    "maxChoices": "{question} allows at most {count} choices.",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "ja": [
    "loadingSurvey": "フォームを読み込んでいます...",
    "submit": "送信",
    "submitting": "送信中...",
    "select": "選択",
    "thankYou": "ありがとうございます",
    "submittedWithTitle": "「{title}」への回答を送信しました。",
    "done": "戻る",
    "surveyUnavailable": "フォームを利用できません",
    "tryAgainLater": "時間をおいて再試行してください。",
    "requiredQuestion": "「{question}」は必須です。",
    "minCharacters": "「{question}」は{count}文字以上で入力してください。",
    "maxCharacters": "「{question}」は{count}文字以内で入力してください。",
    "minChoices": "「{question}」は{count}個以上選択してください。",
    "maxChoices": "「{question}」は{count}個以内で選択してください。",
    "addPhotos": "写真を追加",
    "uploadingPhotos": "アップロード中...",
    "photoUploadFailed": "画像のアップロードに失敗しました。もう一度お試しください。",
    "maxPhotosReached": "最大 {count} 枚まで",
    "removePhoto": "削除",
    "imageUploadUnsupported": "画像アップロードは Flutter アプリで利用できます。"
  ],
  "zh-Hans": [
    "loadingSurvey": "正在加载表单...",
    "submit": "提交",
    "submitting": "正在提交...",
    "select": "选择",
    "thankYou": "谢谢！",
    "submittedWithTitle": "您对“{title}”的回答已提交。",
    "done": "完成",
    "surveyUnavailable": "表单不可用",
    "tryAgainLater": "请稍后重试。",
    "requiredQuestion": "“{question}”为必填项。",
    "minCharacters": "“{question}”至少需要 {count} 个字符。",
    "maxCharacters": "“{question}”最多允许 {count} 个字符。",
    "minChoices": "“{question}”至少选择 {count} 项。",
    "maxChoices": "“{question}”最多选择 {count} 项。",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "zh-Hant": [
    "loadingSurvey": "正在載入表單...",
    "submit": "送出",
    "submitting": "送出中...",
    "select": "選擇",
    "thankYou": "謝謝！",
    "submittedWithTitle": "您對「{title}」的回答已送出。",
    "done": "完成",
    "surveyUnavailable": "表單無法使用",
    "tryAgainLater": "請稍後再試。",
    "requiredQuestion": "「{question}」為必填項。",
    "minCharacters": "「{question}」至少需要 {count} 個字元。",
    "maxCharacters": "「{question}」最多允許 {count} 個字元。",
    "minChoices": "「{question}」至少選擇 {count} 項。",
    "maxChoices": "「{question}」最多選擇 {count} 項。",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "ko": [
    "loadingSurvey": "양식을 불러오는 중...",
    "submit": "제출",
    "submitting": "제출 중...",
    "select": "선택",
    "thankYou": "감사합니다!",
    "submittedWithTitle": "\"{title}\"에 대한 응답이 제출되었습니다.",
    "done": "완료",
    "surveyUnavailable": "양식을 사용할 수 없습니다",
    "tryAgainLater": "잠시 후 다시 시도해 주세요.",
    "requiredQuestion": "\"{question}\"은 필수입니다.",
    "minCharacters": "\"{question}\"은 최소 {count}자 이상이어야 합니다.",
    "maxCharacters": "\"{question}\"은 최대 {count}자까지 입력할 수 있습니다.",
    "minChoices": "\"{question}\"은 최소 {count}개를 선택해야 합니다.",
    "maxChoices": "\"{question}\"은 최대 {count}개까지 선택할 수 있습니다.",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "de": [
    "loadingSurvey": "Formular wird geladen...",
    "submit": "Absenden",
    "submitting": "Wird gesendet...",
    "select": "Auswählen",
    "thankYou": "Vielen Dank!",
    "submittedWithTitle": "Ihre Antwort zu \"{title}\" wurde gesendet.",
    "done": "Fertig",
    "surveyUnavailable": "Formular nicht verfügbar",
    "tryAgainLater": "Bitte versuchen Sie es später erneut.",
    "requiredQuestion": "\"{question}\" ist erforderlich.",
    "minCharacters": "\"{question}\" muss mindestens {count} Zeichen haben.",
    "maxCharacters": "\"{question}\" darf höchstens {count} Zeichen haben.",
    "minChoices": "\"{question}\" erfordert mindestens {count} Optionen.",
    "maxChoices": "\"{question}\" erlaubt höchstens {count} Optionen.",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "es": [
    "loadingSurvey": "Cargando formulario...",
    "submit": "Enviar",
    "submitting": "Enviando...",
    "select": "Seleccionar",
    "thankYou": "¡Gracias!",
    "submittedWithTitle": "Tu respuesta a \"{title}\" se ha enviado.",
    "done": "Listo",
    "surveyUnavailable": "Formulario no disponible",
    "tryAgainLater": "Inténtalo de nuevo más tarde.",
    "requiredQuestion": "\"{question}\" es obligatorio.",
    "minCharacters": "\"{question}\" debe tener al menos {count} caracteres.",
    "maxCharacters": "\"{question}\" puede tener como máximo {count} caracteres.",
    "minChoices": "\"{question}\" requiere al menos {count} opciones.",
    "maxChoices": "\"{question}\" permite como máximo {count} opciones.",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "fr": [
    "loadingSurvey": "Chargement du formulaire...",
    "submit": "Envoyer",
    "submitting": "Envoi en cours...",
    "select": "Sélectionner",
    "thankYou": "Merci !",
    "submittedWithTitle": "Votre réponse à « {title} » a été envoyée.",
    "done": "Terminé",
    "surveyUnavailable": "Formulaire indisponible",
    "tryAgainLater": "Veuillez réessayer plus tard.",
    "requiredQuestion": "« {question} » est obligatoire.",
    "minCharacters": "« {question} » doit contenir au moins {count} caractères.",
    "maxCharacters": "« {question} » peut contenir au plus {count} caractères.",
    "minChoices": "« {question} » nécessite au moins {count} choix.",
    "maxChoices": "« {question} » autorise au plus {count} choix.",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "it": [
    "loadingSurvey": "Caricamento del modulo...",
    "submit": "Invia",
    "submitting": "Invio in corso...",
    "select": "Seleziona",
    "thankYou": "Grazie!",
    "submittedWithTitle": "La tua risposta a \"{title}\" è stata inviata.",
    "done": "Fine",
    "surveyUnavailable": "Modulo non disponibile",
    "tryAgainLater": "Riprova più tardi.",
    "requiredQuestion": "\"{question}\" è obbligatorio.",
    "minCharacters": "\"{question}\" deve contenere almeno {count} caratteri.",
    "maxCharacters": "\"{question}\" può contenere al massimo {count} caratteri.",
    "minChoices": "\"{question}\" richiede almeno {count} opzioni.",
    "maxChoices": "\"{question}\" consente al massimo {count} opzioni.",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "th": [
    "loadingSurvey": "กำลังโหลดแบบฟอร์ม...",
    "submit": "ส่ง",
    "submitting": "กำลังส่ง...",
    "select": "เลือก",
    "thankYou": "ขอบคุณ!",
    "submittedWithTitle": "ส่งคำตอบสำหรับ \"{title}\" แล้ว",
    "done": "เสร็จสิ้น",
    "surveyUnavailable": "แบบฟอร์มไม่พร้อมใช้งาน",
    "tryAgainLater": "โปรดลองอีกครั้งในภายหลัง",
    "requiredQuestion": "\"{question}\" เป็นฟิลด์ที่จำเป็น",
    "minCharacters": "\"{question}\" ต้องมีอย่างน้อย {count} ตัวอักษร",
    "maxCharacters": "\"{question}\" ใส่ได้สูงสุด {count} ตัวอักษร",
    "minChoices": "\"{question}\" ต้องเลือกอย่างน้อย {count} รายการ",
    "maxChoices": "\"{question}\" เลือกได้สูงสุด {count} รายการ",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ],
  "tr": [
    "loadingSurvey": "Form yükleniyor...",
    "submit": "Gönder",
    "submitting": "Gönderiliyor...",
    "select": "Seç",
    "thankYou": "Teşekkürler!",
    "submittedWithTitle": "\"{title}\" yanıtınız gönderildi.",
    "done": "Tamam",
    "surveyUnavailable": "Form kullanılamıyor",
    "tryAgainLater": "Lütfen daha sonra tekrar deneyin.",
    "requiredQuestion": "\"{question}\" zorunludur.",
    "minCharacters": "\"{question}\" en az {count} karakter olmalıdır.",
    "maxCharacters": "\"{question}\" en fazla {count} karakter olabilir.",
    "minChoices": "\"{question}\" en az {count} seçenek gerektirir.",
    "maxChoices": "\"{question}\" en fazla {count} seçeneğe izin verir.",
    "addPhotos": "Add photos",
    "uploadingPhotos": "Uploading...",
    "photoUploadFailed": "Failed to upload image. Please try again.",
    "maxPhotosReached": "Maximum {count} photos",
    "removePhoto": "Remove",
    "imageUploadUnsupported": "Image upload is available in the Flutter app."
  ]
]
