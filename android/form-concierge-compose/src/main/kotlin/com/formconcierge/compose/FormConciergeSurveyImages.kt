package com.formconcierge.compose

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.os.Build
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

private val supportedSurveyImageTypes = setOf("image/jpeg", "image/png", "image/webp", "image/gif")

internal suspend fun prepareSurveyImage(
    payload: SurveyImagePayload,
    processImage: ProcessSurveyImage?,
    encodeJpeg: (ByteArray) -> ByteArray? = ::encodeSurveyImageJpeg,
): SurveyImagePayload? {
    if (processImage != null) return processImage(payload)?.takeIf { it.bytes.isNotEmpty() }
    if (payload.bytes.isEmpty()) return null
    if (payload.contentType in supportedSurveyImageTypes) return payload
    val jpeg = withContext(Dispatchers.IO) { encodeJpeg(payload.bytes) }
    require(jpeg != null && jpeg.isNotEmpty()) { "The selected image could not be converted to JPEG" }
    return SurveyImagePayload(jpeg, "image/jpeg")
}

private fun encodeSurveyImageJpeg(bytes: ByteArray): ByteArray? {
    // ImageDecoder handles EXIF orientation and HEIF on supported Android versions.
    val bitmap =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            ImageDecoder.decodeBitmap(ImageDecoder.createSource(ByteBuffer.wrap(bytes))) { decoder, _, _ ->
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            }
        } else {
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        } ?: return null
    return try {
        ByteArrayOutputStream().use { output ->
            if (bitmap.compress(Bitmap.CompressFormat.JPEG, 85, output)) output.toByteArray() else null
        }
    } finally {
        bitmap.recycle()
    }
}
