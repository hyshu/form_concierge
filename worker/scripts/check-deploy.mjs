import { readFileSync } from "node:fs";

const raw = readFileSync(new URL("../wrangler.jsonc", import.meta.url), "utf8");

const json = raw
  .replace(/("(?:[^"\\]|\\.)*")|\/\/[^\n]*/g, (m, str) => str || "")
  .replace(/,\s*([}\]])/g, "$1");

const config = JSON.parse(json);
const vars = config.vars ?? {};

const bad = Object.entries(vars).filter(([, v]) =>
  typeof v === "string" && /\blocalhost\b|127\.0\.0\.1/.test(v),
);

if (bad.length) {
  console.error("Deploy blocked: localhost URL(s) in wrangler.jsonc vars:");
  for (const [k, v] of bad) console.error(`  ${k} = ${v}`);
  console.error("\nRun setup.sh or set production URLs before deploying.");
  process.exit(1);
}
