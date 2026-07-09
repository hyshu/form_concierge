import Foundation

enum FormContentMessages {
  static func text(_ locale: String, _ key: String) -> String {
    messages[normalizeFormContentLocale(locale)]![key]!
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
    "maxChoices": "{question} allows at most {count} choices."
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
    "maxChoices": "「{question}」は{count}個以内で選択してください。"
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
    "maxChoices": "“{question}”最多选择 {count} 项。"
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
    "maxChoices": "「{question}」最多選擇 {count} 項。"
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
    "maxChoices": "\"{question}\"은 최대 {count}개까지 선택할 수 있습니다."
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
    "maxChoices": "\"{question}\" erlaubt höchstens {count} Optionen."
  ]
]
