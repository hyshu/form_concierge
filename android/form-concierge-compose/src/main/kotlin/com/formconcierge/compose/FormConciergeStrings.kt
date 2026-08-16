package com.formconcierge.compose

internal object FormConciergeStrings {
    fun text(
        locale: String,
        key: String,
        vararg replacements: Pair<String, Any>,
    ): String {
        val language = normalizeFormContentLocale(locale)
        var value =
            messages[language]?.get(key)
                ?: messages["en"]?.get(key)
                ?: key
        replacements.forEach { (name, replacement) ->
            value = value.replace("{$name}", replacement.toString())
        }
        return value
    }

    private val messages =
        mapOf(
            "en" to
                mapOf(
                    "loadingSurvey" to "Loading form…",
                    "submit" to "Submit",
                    "submitting" to "Submitting…",
                    "followUpLoading" to "Preparing a few more questions…",
                    "followUpTitle" to "A few more questions",
                    "followUpSubtitle" to "These questions are optional. You can finish without answering them.",
                    "followUpContinue" to "Finish",
                    "followUpSubmitting" to "Finishing…",
                    "captchaRequired" to "Please complete the CAPTCHA before submitting.",
                    "select" to "Select",
                    "thankYou" to "Thank you!",
                    "submittedWithTitle" to "Your response to “{title}” has been submitted.",
                    "done" to "Done",
                    "surveyUnavailable" to "Form unavailable",
                    "tryAgainLater" to "Please try again later.",
                    "requiredQuestion" to "{question} is required.",
                    "minCharacters" to "{question} must be at least {count} characters.",
                    "maxCharacters" to "{question} must be at most {count} characters.",
                    "minChoices" to "{question} requires at least {count} choices.",
                    "maxChoices" to "{question} allows at most {count} choices.",
                    "addPhotos" to "Add photos",
                    "uploadingPhotos" to "Uploading…",
                    "photoUploadFailed" to "Failed to upload image. Please try again.",
                    "maxPhotosReached" to "Maximum {count} photos",
                    "removePhoto" to "Remove photo",
                    "contactUs" to "Contact us",
                    "newInquiry" to "New inquiry",
                    "pastInquiries" to "Past inquiries",
                    "inquiryList" to "Inquiry history",
                    "noInquiriesYet" to "No inquiries yet",
                    "startInquiry" to "Send your first inquiry",
                    "retentionNote" to "Inquiries older than three months are removed from this device.",
                    "replyFromSupport" to "Reply from support",
                    "additionalQuestions" to "Additional questions",
                    "attachedImages" to "Images attached",
                    "noReplyYet" to "No reply yet",
                    "retry" to "Retry",
                    "close" to "Close",
                    "back" to "Back",
                    "loading" to "Loading…",
                    "unknownDate" to "Inquiry",
                    "newReply" to "New",
                ),
            "ja" to
                mapOf(
                    "loadingSurvey" to "フォームを読み込んでいます…",
                    "submit" to "送信",
                    "submitting" to "送信中…",
                    "followUpLoading" to "追加の質問を準備しています…",
                    "followUpTitle" to "追加の質問",
                    "followUpSubtitle" to "すべて任意です。答えずにそのまま完了しても構いません。",
                    "followUpContinue" to "完了する",
                    "followUpSubmitting" to "完了処理中…",
                    "captchaRequired" to "送信する前に CAPTCHA を完了してください。",
                    "select" to "選択",
                    "thankYou" to "ありがとうございます",
                    "submittedWithTitle" to "「{title}」への回答を送信しました。",
                    "done" to "戻る",
                    "surveyUnavailable" to "フォームを利用できません",
                    "tryAgainLater" to "時間をおいて再試行してください。",
                    "requiredQuestion" to "「{question}」は必須です。",
                    "minCharacters" to "「{question}」は{count}文字以上で入力してください。",
                    "maxCharacters" to "「{question}」は{count}文字以内で入力してください。",
                    "minChoices" to "「{question}」は{count}個以上選択してください。",
                    "maxChoices" to "「{question}」は{count}個以内で選択してください。",
                    "addPhotos" to "写真を追加",
                    "uploadingPhotos" to "アップロード中…",
                    "photoUploadFailed" to "画像のアップロードに失敗しました。もう一度お試しください。",
                    "maxPhotosReached" to "最大 {count} 枚まで",
                    "removePhoto" to "写真を削除",
                    "contactUs" to "お問い合わせ",
                    "newInquiry" to "新規お問い合わせ",
                    "pastInquiries" to "過去のお問い合わせ一覧",
                    "inquiryList" to "お問い合わせ一覧",
                    "noInquiriesYet" to "お問い合わせはまだありません",
                    "startInquiry" to "最初のお問い合わせを送る",
                    "retentionNote" to "送信日から3か月以上経過したお問い合わせは、この端末から削除されます。",
                    "replyFromSupport" to "事務局からの返信",
                    "additionalQuestions" to "追加の質問",
                    "attachedImages" to "添付画像あり",
                    "noReplyYet" to "返信はまだありません",
                    "retry" to "再試行",
                    "close" to "閉じる",
                    "back" to "戻る",
                    "loading" to "読み込み中…",
                    "unknownDate" to "お問い合わせ",
                    "newReply" to "新着",
                ),
        )
}
