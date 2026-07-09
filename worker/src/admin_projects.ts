import type { AdminContext, Env, ProjectRow, SurveyRow } from './types';
import {
  HttpError,
  integerParam,
  json,
  nowIso,
  optionalCustomDomain,
  readJson,
  requireSlug,
  requireString,
  requiredRow,
} from './utils';
import { projectToJson, surveyToJson } from './serializers';
import { mustProject } from './admin_records';
import {
  requireDefaultLocale,
  requireSupportedLocales,
} from './localization';

export async function listProjects(env: Env, url: URL): Promise<Response> {
  const limit = integerParam(url.searchParams.get('limit'), 'limit', 100, { min: 1, max: 500 });
  const offset = integerParam(url.searchParams.get('offset'), 'offset', 0, { min: 0 });
  const projects = await env.DB.prepare(
    `SELECT * FROM projects ORDER BY updated_at DESC LIMIT ? OFFSET ?`,
  ).bind(limit, offset).all<ProjectRow>();
  const projectIds = projects.results.map((project) => project.id);
  const surveysByProject = new Map<number, SurveyRow[]>();
  if (projectIds.length > 0) {
    const placeholders = projectIds.map(() => '?').join(', ');
    const surveys = await env.DB.prepare(
      `SELECT * FROM surveys WHERE project_id IN (${placeholders}) ORDER BY updated_at DESC`,
    ).bind(...projectIds).all<SurveyRow>();
    for (const survey of surveys.results) {
      const current = surveysByProject.get(survey.project_id) ?? [];
      current.push(survey);
      surveysByProject.set(survey.project_id, current);
    }
  }

  return json(projects.results.map((project) => ({
    project: projectToJson(project),
    surveys: (surveysByProject.get(project.id) ?? []).map(surveyToJson),
  })));
}

export async function getAdminProject(env: Env, projectId: number): Promise<Response> {
  const project = await env.DB.prepare(`SELECT * FROM projects WHERE id = ?`)
    .bind(projectId)
    .first<ProjectRow>();
  if (!project) throw new HttpError(404, 'Project not found');
  const surveys = await env.DB.prepare(
    `SELECT * FROM surveys WHERE project_id = ? ORDER BY updated_at DESC`,
  ).bind(projectId).all<SurveyRow>();
  return json({
    project: projectToJson(project),
    surveys: surveys.results.map(surveyToJson),
  });
}

export async function createProject(request: Request, env: Env, admin: AdminContext): Promise<Response> {
  const body = await readJson(request);
  const slug = requireSlug(body.slug);
  await ensureUniqueProjectSlug(env.DB, slug);
  const customDomain = optionalCustomDomain(body.customDomain);
  await ensureUniqueProjectCustomDomain(env.DB, customDomain);
  const content = parseProjectContent(body);
  const now = nowIso();
  const row = await env.DB.prepare(
    `INSERT INTO projects
       (slug, custom_domain, default_locale, supported_locales, name,
        created_by_admin_id, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     RETURNING *`,
  ).bind(
    slug,
    customDomain,
    content.defaultLocale,
    JSON.stringify(content.supportedLocales),
    content.name,
    admin.id,
    now,
    now,
  ).first<ProjectRow>();
  return json(projectToJson(requiredRow(row, 'Project')), 201);
}

export async function updateProject(request: Request, env: Env, projectId: number): Promise<Response> {
  const existing = await mustProject(env.DB, projectId);
  const body = await readJson(request);
  const slug = requireSlug(body.slug ?? existing.slug);
  await ensureUniqueProjectSlug(env.DB, slug, projectId);
  const customDomain = optionalCustomDomain(
    Object.hasOwn(body, 'customDomain') ? body.customDomain : existing.custom_domain,
  );
  await ensureUniqueProjectCustomDomain(env.DB, customDomain, projectId);
  const content = parseProjectContent(body);
  const row = await env.DB.prepare(
    `UPDATE projects
     SET slug = ?, custom_domain = ?, default_locale = ?, supported_locales = ?,
         name = ?, updated_at = ?
     WHERE id = ?
     RETURNING *`,
  ).bind(
    slug,
    customDomain,
    content.defaultLocale,
    JSON.stringify(content.supportedLocales),
    content.name,
    nowIso(),
    projectId,
  ).first<ProjectRow>();
  return json(projectToJson(requiredRow(row, 'Project')));
}

export async function deleteProject(env: Env, projectId: number): Promise<Response> {
  await env.DB.prepare(`DELETE FROM projects WHERE id = ?`).bind(projectId).run();
  return json({ ok: true });
}

function parseProjectContent(body: Record<string, unknown>): {
  supportedLocales: string[];
  defaultLocale: string;
  name: string;
} {
  const supportedLocales = requireSupportedLocales(body.supportedLocales);
  const defaultLocale = requireDefaultLocale(body.defaultLocale, supportedLocales);
  return {
    supportedLocales,
    defaultLocale,
    name: requireString(body.name, 'name'),
  };
}

async function ensureUniqueProjectSlug(
  db: D1Database,
  slug: string,
  exceptProjectId?: number,
): Promise<void> {
  const row = exceptProjectId == null
    ? await db.prepare(`SELECT id FROM projects WHERE slug = ?`).bind(slug).first<{ id: number }>()
    : await db.prepare(`SELECT id FROM projects WHERE slug = ? AND id != ?`)
      .bind(slug, exceptProjectId)
      .first<{ id: number }>();
  if (row) throw new HttpError(400, 'A project with this slug already exists');
}

async function ensureUniqueProjectCustomDomain(
  db: D1Database,
  customDomain: string | null,
  exceptProjectId?: number,
): Promise<void> {
  if (customDomain == null) return;
  const row = exceptProjectId == null
    ? await db.prepare(`SELECT id FROM projects WHERE custom_domain = ?`).bind(customDomain).first<{ id: number }>()
    : await db.prepare(`SELECT id FROM projects WHERE custom_domain = ? AND id != ?`)
      .bind(customDomain, exceptProjectId)
      .first<{ id: number }>();
  if (row) throw new HttpError(400, 'A project with this custom domain already exists');
}
