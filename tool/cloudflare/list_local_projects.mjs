import { execFileSync } from 'node:child_process';

const [databaseName] = process.argv.slice(2);

if (!databaseName) {
  console.error('Usage: list_local_projects.mjs <database-name>');
  process.exit(1);
}

const args = [
  'wrangler',
  'd1',
  'execute',
  databaseName,
  '--local',
  '--json',
  '--command',
  'SELECT id, slug, updated_at FROM projects ORDER BY updated_at DESC;',
];

if (process.env.LOCAL_D1_PERSIST_TO) {
  args.splice(5, 0, '--persist-to', process.env.LOCAL_D1_PERSIST_TO);
}

let raw;
try {
  raw = execFileSync('npx', args, {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
} catch (error) {
  const stdout = error.stdout?.toString().trim();
  const details = error.stderr?.toString().trim();
  if (stdout) console.error(stdout);
  if (details) console.error(details);
  console.error('Could not read local projects. Run `cd worker && npm run d1:migrate:local`, then create a project in the local admin dashboard.');
  console.error('If the error says `no such table: projects`, reset stale local D1 state with `rm -rf worker/.wrangler/state/v3/d1`, then rerun local migrations.');
  process.exit(2);
}

const parsed = JSON.parse(raw);
const rows = parsed[0]?.results ?? [];

if (rows.length === 0) {
  console.log('No local projects found yet.');
  process.exit(0);
}

console.log('Local projects:');
for (const row of rows) {
  console.log(`  ${row.id}\t${row.slug}\t${row.updated_at}`);
}
