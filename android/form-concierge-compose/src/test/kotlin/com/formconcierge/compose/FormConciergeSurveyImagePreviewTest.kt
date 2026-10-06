package com.formconcierge.compose

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class FormConciergeSurveyImagePreviewTest {
    @Test
    fun `large portrait and landscape images keep ratio within preview bound`() {
        assertEquals(160 to 120, surveyImagePreviewSize(4000, 3000, 160))
        assertEquals(120 to 160, surveyImagePreviewSize(3000, 4000, 160))
        assertEquals(160 to 160, surveyImagePreviewSize(4000, 4000, 160))
    }

    @Test
    fun `small images are never enlarged and very narrow images stay decodable`() {
        assertEquals(80 to 60, surveyImagePreviewSize(80, 60, 160))
        assertEquals(1 to 160, surveyImagePreviewSize(1, 4000, 160))
        assertEquals(160 to 1, surveyImagePreviewSize(4000, 1, 160))
    }

    @Test
    fun `invalid image bounds are rejected before configuring decoder`() {
        assertFailsWith<IllegalArgumentException> { surveyImagePreviewSize(0, 160, 160) }
        assertFailsWith<IllegalArgumentException> { surveyImagePreviewSize(160, -1, 160) }
        assertFailsWith<IllegalArgumentException> { surveyImagePreviewSize(160, 160, 0) }
    }
}
