import { copyFile, readFile, rm } from "node:fs/promises";
import { spawn } from "node:child_process";
import path from "node:path";
import process from "node:process";

const workerDirectory = process.cwd();
const checkedInTypes = path.resolve(workerDirectory, "src/worker-env.d.ts");
const writeTypes = process.argv.includes("--write");
const generatedTypes = writeTypes
  ? checkedInTypes
  : path.resolve(workerDirectory, "src/.worker-env.check.d.ts");
const sourceConfig = path.resolve(workerDirectory, "wrangler.jsonc.example");
const checkConfig = path.resolve(workerDirectory, ".wrangler.check.jsonc");
const npx = process.platform === "win32" ? "npx.cmd" : "npx";

let exitCode = 0;
try {
  await copyFile(sourceConfig, checkConfig);
  exitCode = await run(npx, [
    "wrangler",
    "types",
    generatedTypes,
    "--config",
    checkConfig,
    "--env-interface",
    "WorkerEnv",
    "--include-runtime",
    "false",
    "--strict-vars",
    "false",
  ]);
  if (exitCode === 0 && !writeTypes) {
    const [checkedIn, generated] = await Promise.all([
      readFile(checkedInTypes, "utf8"),
      readFile(generatedTypes, "utf8"),
    ]);
    if (declarations(checkedIn) !== declarations(generated)) {
      console.error(
        "Worker binding declarations are out of date. Run `npm run types:worker` to regenerate.",
      );
      exitCode = 1;
    } else {
      console.log("Worker binding declarations are up to date.");
    }
  }
} finally {
  await rm(checkConfig, { force: true });
  if (!writeTypes) await rm(generatedTypes, { force: true });
}

process.exitCode = exitCode;

function declarations(source) {
  const start = source.indexOf("interface __BaseEnv_");
  return start === -1 ? source : source.slice(start);
}

function run(command, arguments_) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, arguments_, {
      cwd: workerDirectory,
      stdio: "inherit",
    });
    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (signal) {
        reject(new Error(`${command} terminated by ${signal}`));
        return;
      }
      resolve(code ?? 1);
    });
  });
}
