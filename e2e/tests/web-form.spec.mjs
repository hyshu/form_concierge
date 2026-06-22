import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { expect, test } from '@playwright/test';

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

async function seedData() {
  const raw = await readFile(path.join(rootDir, 'e2e/.artifacts/seed.json'), 'utf8');
  return JSON.parse(raw);
}

test('Jaspr web form loads and submits a response', async ({ page, baseURL }) => {
  const seed = await seedData();
  await page.goto(`${baseURL}/${seed.projectSlug}/${seed.surveyId}`);

  await expect(page.getByText('Customer feedback')).toBeVisible();
  await expect(page.getByText('Tell us what you think')).toBeVisible();
  await expect(page.getByText('Your name')).toBeVisible();

  await page.locator('input[type="text"]').fill('Jaspr respondent');
  await page.getByRole('button', { name: 'Submit' }).click();

  await expect(page.getByText('Thank you!')).toBeVisible();
  await expect(page.getByText('Your response has been submitted successfully.')).toBeVisible();
});
