package com.formconcierge.compose

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class FormConciergeStringsTest {
    @Test
    fun `all supported locales have native inquiry strings`() {
        val english = FormConciergeStrings.text("en", "contactUs")

        formContentLocaleCodes.forEach { locale ->
            val contact = FormConciergeStrings.text(locale, "contactUs")
            assertTrue(contact.isNotBlank(), locale)
            if (locale != "en") assertNotEquals(english, contact, locale)
        }
    }

    @Test
    fun `validation placeholders are preserved in every locale`() {
        formContentLocaleCodes.forEach { locale ->
            assertEquals(
                false,
                FormConciergeStrings.text(
                    locale,
                    "minCharacters",
                    "question" to "Q",
                    "count" to 3,
                ).contains("{"),
                locale,
            )
        }
    }
}
