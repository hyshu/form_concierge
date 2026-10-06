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

internal suspend fun <Source> uploadSurveyImages(
    sources: List<Source>,
    existingFileKeys: List<String>,
    maxFiles: Int,
    loadImage: suspend (Source) -> SurveyImagePayload?,
    processImage: ProcessSurveyImage?,
    uploadImage: suspend (SurveyImagePayload) -> String,
    onUploaded: (List<String>, SurveyImagePayload) -> Unit,
) {
    val fileKeys = existingFileKeys.toMutableList()
    for (source in sources) {
        if (fileKeys.size >= maxFiles) break
        val payload = loadImage(source) ?: continue
        val processed = prepareSurveyImage(payload, processImage) ?: continue
        fileKeys += uploadImage(processed)
        // Save each acknowledged upload before starting another network request.
        onUploaded(fileKeys.toList(), processed)
    }
}

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
    val bitmap = decodeSurveyImageBitmap(bytes) ?: return null
    return try {
        ByteArrayOutputStream().use { output ->
            if (bitmap.compress(Bitmap.CompressFormat.JPEG, 85, output)) output.toByteArray() else null
        }
    } finally {
        bitmap.recycle()
    }
}

internal fun decodeSurveyImagePreview(bytes: ByteArray): Bitmap? = decodeSurveyImageBitmap(bytes, maxSide = 160)

internal fun surveyImagePreviewSize(
    width: Int,
    height: Int,
    maxSide: Int,
): Pair<Int, Int> {
    require(width > 0 && height > 0 && maxSide > 0)
    val scale = minOf(1.0, maxSide.toDouble() / maxOf(width, height))
    return (width * scale).toInt().coerceAtLeast(1) to (height * scale).toInt().coerceAtLeast(1)
}

private fun decodeSurveyImageBitmap(
    bytes: ByteArray,
    maxSide: Int? = null,
): Bitmap? {
    // ImageDecoder handles EXIF orientation and HEIF on supported Android versions.
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        return ImageDecoder.decodeBitmap(ImageDecoder.createSource(ByteBuffer.wrap(bytes))) { decoder, info, _ ->
            decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            if (maxSide != null) {
                val (width, height) = surveyImagePreviewSize(info.size.width, info.size.height, maxSide)
                decoder.setTargetSize(width, height)
            }
        }
    }
    val options = BitmapFactory.Options()
    if (maxSide != null) {
        options.inJustDecodeBounds = true
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
        if (options.outWidth <= 0 || options.outHeight <= 0) return null
        options.inJustDecodeBounds = false
        options.inSampleSize = 1
        while (maxOf(options.outWidth, options.outHeight) / (options.inSampleSize * 2) >= maxSide) {
            options.inSampleSize *= 2
        }
    }
    val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options) ?: return null
    if (maxSide == null) return bitmap
    val (width, height) = surveyImagePreviewSize(bitmap.width, bitmap.height, maxSide)
    if (bitmap.width == width && bitmap.height == height) return bitmap
    return Bitmap.createScaledBitmap(bitmap, width, height, true).also { bitmap.recycle() }
}
