package com.formconcierge.compose

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.io.IOException
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertSame

class FormConciergeSurveyImageUploadTest {
    @Test
    fun `first upload remains in answers when next request fails`() =
        runTest {
            val first = image(1)
            val second = image(2)
            var answer = listOf("existing")
            var requests = 0
            assertFailsWith<IOException> {
                uploadSurveyImages(
                    sources = listOf(first, second),
                    existingFileKeys = answer,
                    maxFiles = 3,
                    loadImage = { it },
                    processImage = null,
                    uploadImage = { payload ->
                        requests++
                        if (payload === first) {
                            "first-upload"
                        } else {
                            assertEquals(listOf("existing", "first-upload"), answer)
                            throw IOException("Upload failed")
                        }
                    },
                    onUploaded = { keys, payload ->
                        answer = keys
                        assertSame(first, payload)
                    },
                )
            }
            assertEquals(2, requests)
            assertEquals(listOf("existing", "first-upload"), answer)
        }

    @Test
    fun `each success publishes immutable answer snapshot up to file limit`() =
        runTest {
            val answers = mutableListOf<List<String>>()
            val loaded = mutableListOf<Int>()
            uploadSurveyImages(
                sources = listOf(1, 2, 3),
                existingFileKeys = listOf("existing"),
                maxFiles = 3,
                loadImage = {
                    loaded += it
                    image(it)
                },
                processImage = null,
                uploadImage = { "upload-${it.bytes.single()}" },
                onUploaded = { keys, _ -> answers += keys },
            )
            assertEquals(listOf(1, 2), loaded)
            assertEquals(
                listOf(listOf("existing", "upload-1"), listOf("existing", "upload-1", "upload-2")),
                answers,
            )
        }

    @Test
    fun `host omitted image does not consume attachment slot`() =
        runTest {
            var answer = emptyList<String>()
            uploadSurveyImages(
                sources = listOf(1, 2),
                existingFileKeys = answer,
                maxFiles = 1,
                loadImage = { image(it) },
                processImage = { if (it.bytes.single() == 1.toByte()) null else it },
                uploadImage = { "second-upload" },
                onUploaded = { keys, _ -> answer = keys },
            )
            assertEquals(listOf("second-upload"), answer)
        }

    @Test
    fun `cancelled later upload keeps acknowledged files and propagates cancellation`() =
        runTest {
            var answer = emptyList<String>()
            assertFailsWith<CancellationException> {
                uploadSurveyImages(
                    sources = listOf(1, 2),
                    existingFileKeys = answer,
                    maxFiles = 3,
                    loadImage = { image(it) },
                    processImage = null,
                    uploadImage = {
                        if (it.bytes.single() == 2.toByte()) throw CancellationException("Form left")
                        "first-upload"
                    },
                    onUploaded = { keys, _ -> answer = keys },
                )
            }
            assertEquals(listOf("first-upload"), answer)
        }

    private fun image(id: Int): SurveyImagePayload = SurveyImagePayload(byteArrayOf(id.toByte()), "image/png")
}
