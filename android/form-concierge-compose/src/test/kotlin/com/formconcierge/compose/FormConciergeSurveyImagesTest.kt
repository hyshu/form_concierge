package com.formconcierge.compose

import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertSame

class FormConciergeSurveyImagesTest {
    @Test
    fun `supported formats preserve original bytes without decoding`() =
        runTest {
            for (contentType in listOf("image/jpeg", "image/png", "image/webp", "image/gif")) {
                val payload = SurveyImagePayload(byteArrayOf(1, 2, 3), contentType)
                assertSame(payload, prepareSurveyImage(payload, null) { error("Supported images must not be re-encoded") })
            }
        }

    @Test
    fun `heic and unknown mime types use converted jpeg bytes`() =
        runTest {
            val original = byteArrayOf(1, 2, 3)
            val jpeg = byteArrayOf(0xff.toByte(), 0xd8.toByte(), 4, 0xff.toByte(), 0xd9.toByte())
            for (contentType in listOf("image/heic", "image/heif", "image/bmp", "application/octet-stream")) {
                val result =
                    prepareSurveyImage(SurveyImagePayload(original, contentType), null) { bytes ->
                        assertSame(original, bytes)
                        jpeg
                    }
                assertEquals("image/jpeg", result?.contentType)
                assertContentEquals(jpeg, result?.bytes)
            }
        }

    @Test
    fun `failed conversion rejects unsupported bytes rather than relabeling them`() =
        runTest {
            for (result in listOf(null, byteArrayOf())) {
                assertFailsWith<IllegalArgumentException> {
                    prepareSurveyImage(SurveyImagePayload(byteArrayOf(1), "image/heic"), null) { result }
                }
            }
        }

    @Test
    fun `host processing overrides default conversion and can omit images`() =
        runTest {
            val payload = SurveyImagePayload(byteArrayOf(1), "image/heic")
            val processed = SurveyImagePayload(byteArrayOf(2), "image/png")
            assertSame(
                processed,
                prepareSurveyImage(payload, { original ->
                    assertSame(payload, original)
                    processed
                }) { error("Host processing must bypass the default converter") },
            )
            assertNull(prepareSurveyImage(payload, { null }) { error("Omitted images must not be converted") })
            assertNull(prepareSurveyImage(payload, { SurveyImagePayload(byteArrayOf(), "image/png") }))
        }

    @Test
    fun `empty source image is omitted without decoding`() =
        runTest {
            assertNull(prepareSurveyImage(SurveyImagePayload(byteArrayOf(), "image/heic"), null) { error("No bytes to decode") })
        }
}
