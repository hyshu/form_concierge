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

async function typeIntoFlutterInput(locator, value) {
  await expect(locator).toBeVisible();
  await locator.scrollIntoViewIfNeeded();
  await locator.click({ force: true });
  await locator.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await locator.press('Backspace');
  await locator.pressSequentially(value, { delay: 10 });
  await expect(locator).toHaveValue(value);
}

function apiResponse(apiUrl, pathname) {
  const expected = new URL(pathname, apiUrl);
  return (response) => {
    const actual = new URL(response.url());
    return response.status() === 200 &&
      actual.origin === expected.origin &&
      actual.pathname === expected.pathname;
  };
}

async function login(page, seed, apiUrl) {
  await enableFlutterSemantics(page);
  await expect(page.locator('body')).toContainText('Login');

  const loginResponsePromise = page.waitForResponse(
    apiResponse(apiUrl, '/api/admin/auth/login'),
  );
  const projectResponsePromise = page.waitForResponse(
    apiResponse(apiUrl, '/api/admin/projects'),
  );

  await typeIntoFlutterInput(page.locator('input[autocomplete="email"]'), seed.adminEmail);
  const passwordInput = page.locator('input[type="password"]');
  await typeIntoFlutterInput(passwordInput, seed.adminPassword);
  await passwordInput.press('Enter');

  await loginResponsePromise;
  return projectResponsePromise;
}

test('admin dashboard logs in and renders seeded project data', async ({ page }) => {
  const seed = await seedData();
  const adminUrl = process.env.ADMIN_URL ?? 'http://127.0.0.1:8080';
  const apiUrl = process.env.API_URL ?? seed.apiUrl;

  await page.goto(adminUrl);
  const projectResponse = await login(page, seed, apiUrl);
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

test('admin dashboard creates a new project from the UI', async ({ page }) => {
  const seed = await seedData();
  const adminUrl = process.env.ADMIN_URL ?? 'http://127.0.0.1:8080';
  const apiUrl = process.env.API_URL ?? seed.apiUrl;

  await page.goto(adminUrl);
  await login(page, seed, apiUrl);

  await page.getByRole('button', { name: 'Create Project' }).first().click();
  await expect(page.locator('body')).toContainText('New Project');

  const uniqueSuffix = Date.now().toString(36);
  const projectName = `E2E project ${uniqueSuffix}`;
  // Hint-based names disappear once a value is typed, so target by position:
  // the New Project form renders name, slug, custom domain in order.
  await expect(page.getByRole('textbox', { name: 'Enter project name' })).toBeVisible();
  await typeIntoFlutterInput(page.getByRole('textbox').nth(0), projectName);
  await typeIntoFlutterInput(page.getByRole('textbox').nth(1), `e2e-project-${uniqueSuffix}`);

  const createResponsePromise = page.waitForResponse((response) => {
    const url = new URL(response.url());
    return response.request().method() === 'POST' &&
      url.pathname === '/api/admin/projects' &&
      response.status() === 201;
  });
  await page.getByRole('button', { name: 'Create Project' }).click();
  const created = await (await createResponsePromise).json();
  expect(created.slug).toBe(`e2e-project-${uniqueSuffix}`);

  // The dashboard exposes each project card's name via its group aria-label.
  await expect(page.getByRole('group', { name: new RegExp(projectName) })).toBeVisible();
});
