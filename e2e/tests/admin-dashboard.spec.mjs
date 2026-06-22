import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { expect, test } from '@playwright/test';

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

async function seedData() {
  const raw = await readFile(path.join(rootDir, 'e2e/.artifacts/seed.json'), 'utf8');
  return JSON.parse(raw);
}

async function enableFlutterSemantics(page) {
  await page.waitForSelector('flt-semantics-placeholder', { timeout: 15_000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
}

test('admin dashboard logs in and renders seeded project data', async ({ page }) => {
  const seed = await seedData();
  const adminUrl = process.env.ADMIN_URL ?? 'http://127.0.0.1:8080';
  const apiUrl = process.env.API_URL ?? seed.apiUrl;

  await page.goto(adminUrl);
  await enableFlutterSemantics(page);

  await expect(page.locator('body')).toContainText('Login');

  const projectResponsePromise = page.waitForResponse(
    (response) => response.url() === `${apiUrl}/api/admin/projects` && response.status() === 200,
  );

  const inputs = page.locator('input, textarea');
  await inputs.nth(0).fill(seed.adminEmail);
  await inputs.nth(1).fill(seed.adminPassword);
  await page.getByRole('button', { name: 'Login' }).click();

  const projectResponse = await projectResponsePromise;
  const projects = await projectResponse.json();
  expect(projects).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        project: expect.objectContaining({
          slug: seed.projectSlug,
        }),
      }),
    ]),
  );

  await expect(page.locator('body')).toContainText('Create Project');
  await page.screenshot({ path: 'test-results/admin-dashboard.png', fullPage: true });
});
