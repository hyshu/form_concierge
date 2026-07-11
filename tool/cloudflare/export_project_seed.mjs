import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const [databaseName, rawProjectId, outputFile] = process.argv.slice(2);

if (!databaseName || !rawProjectId || !outputFile) {
  console.error('Usage: export_project_seed.mjs <database-name> <project-id> <output-file>');
  process.exit(1);
}

const projectId = Number.parseInt(rawProjectId, 10);
if (!Number.isInteger(projectId) || projectId < 1 || String(projectId) !== rawProjectId) {
  console.error('Project ID must be a positive integer.');
  process.exit(1);
}

function query(sql) {
  let raw;
  const args = ['wrangler', 'd1', 'execute', databaseName, '--local'];
  if (process.env.LOCAL_D1_PERSIST_TO) {
    args.push('--persist-to', process.env.LOCAL_D1_PERSIST_TO);
  }
  args.push('--json', '--command', sql);
  try {
    raw = execFileSync(
      'npx',
      args,
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
    );
  } catch (error) {
    const stdout = error.stdout?.toString().trim();
    const details = error.stderr?.toString().trim();
    if (stdout) console.error(stdout);
    if (details) console.error(details);
    console.error('Local D1 query failed. Run `cd worker && npm install && npm run d1:migrate:local && npm run dev`, create a project in the local admin dashboard, then run `form_concierge setup cloudflare --list-local-projects`.');
    console.error('If the error says `no such table: projects`, reset stale local D1 state with `rm -rf worker/.wrangler/state/v3/d1`, then rerun local migrations.');
    process.exit(1);
  }

  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed) || parsed.length === 0 || parsed[0].success !== true) {
    console.error(`Local D1 query failed: ${sql}`);
    process.exit(1);
  }
  return parsed[0].results ?? [];
}

function list(values) {
  return values.length === 0 ? 'NULL' : values.join(', ');
}

function sqlValue(value) {
  if (value == null) return 'NULL';
  if (typeof value === 'number') return Number.isFinite(value) ? String(value) : 'NULL';
  if (typeof value === 'boolean') return value ? '1' : '0';
  return `'${String(value).replaceAll("'", "''")}'`;
}

function insert(table, columns, row, overrides = {}) {
  const values = columns.map((column) => (
    Object.hasOwn(overrides, column) ? overrides[column] : row[column]
  ));
  return `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${values.map(sqlValue).join(', ')});`;
}

const projectRows = query(`SELECT * FROM projects WHERE id = ${projectId}`);
if (projectRows.length !== 1) {
  console.error(`No local project found for project ID ${projectId}.`);
  console.error('Run `form_concierge setup cloudflare --list-local-projects` to see available local project IDs.');
  process.exit(1);
}

const project = projectRows[0];
const surveys = query(`SELECT * FROM surveys WHERE project_id = ${projectId} ORDER BY id`);
const surveyIds = surveys.map((survey) => survey.id);
const questions = surveyIds.length === 0
  ? []
  : query(`SELECT * FROM questions WHERE survey_id IN (${list(surveyIds)}) ORDER BY id`);
const questionIds = questions.map((question) => question.id);
const choices = questionIds.length === 0
  ? []
  : query(`SELECT * FROM choices WHERE question_id IN (${list(questionIds)}) ORDER BY id`);
const visibilityRules = surveyIds.length === 0
  ? []
  : query(`SELECT * FROM question_visibility_rules WHERE survey_id IN (${list(surveyIds)}) ORDER BY id`);
const notificationSettings = surveyIds.length === 0
  ? []
  : query(`SELECT * FROM notification_settings WHERE survey_id IN (${list(surveyIds)}) ORDER BY id`);

const lines = [
  `DELETE FROM notification_settings WHERE survey_id IN (${list(surveyIds)});`,
  `DELETE FROM question_visibility_rules WHERE survey_id IN (${list(surveyIds)}) OR target_question_id IN (${list(questionIds)}) OR source_question_id IN (${list(questionIds)});`,
  `DELETE FROM choices WHERE question_id IN (${list(questionIds)});`,
  `DELETE FROM questions WHERE id IN (${list(questionIds)}) OR survey_id IN (${list(surveyIds)});`,
  `DELETE FROM surveys WHERE id IN (${list(surveyIds)}) OR project_id = ${projectId};`,
  `DELETE FROM projects WHERE id = ${projectId} OR slug = ${sqlValue(project.slug)};`,
  insert('projects', [
    'id',
    'slug',
    'custom_domain',
    'default_locale',
    'supported_locales',
    'name',
    'created_by_admin_id',
    'created_at',
    'updated_at',
  ], project, { created_by_admin_id: null }),
  ...surveys.map((survey) => insert('surveys', [
    'id',
    'project_id',
    'title_translations',
    'description_translations',
    'status',
    'web_enabled',
    'auth_requirement',
    'created_by_admin_id',
    'created_at',
    'updated_at',
    'starts_at',
    'ends_at',
  ], survey, { created_by_admin_id: null })),
  ...questions.map((question) => insert('questions', [
    'id',
    'survey_id',
    'text_translations',
    'type',
    'order_index',
    'is_required',
    'placeholder_translations',
    'min_length',
    'max_length',
    'min_selected',
    'max_selected',
    'visibility_condition_mode',
    'is_deleted',
  ], question)),
  ...choices.map((choice) => insert('choices', [
    'id',
    'question_id',
    'text_translations',
    'order_index',
    'value',
  ], choice)),
  ...visibilityRules.map((rule) => insert('question_visibility_rules', [
    'id',
    'survey_id',
    'target_question_id',
    'source_question_id',
    'operator',
    'value_json',
    'created_at',
    'updated_at',
  ], rule)),
  ...notificationSettings.map((setting) => insert('notification_settings', [
    'id',
    'survey_id',
    'enabled',
    'recipient_email',
    'updated_at',
  ], setting)),
  '',
];

writeFileSync(outputFile, lines.join('\n'));
console.error(`Exported local project ${projectId} (${project.slug}) with ${surveys.length} surveys.`);
