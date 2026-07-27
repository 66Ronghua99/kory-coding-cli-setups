import { spawn } from "node:child_process";

export function runProcess(command, args = [], options = {}) {
  const { cwd, env = process.env, timeoutMs = 120_000, input, check = false } = options;
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      env: { ...env },
      stdio: [input === undefined ? "ignore" : "pipe", "pipe", "pipe"],
      shell: false,
    });
    let stdout = "";
    let stderr = "";
    let settled = false;
    const timer = timeoutMs > 0 ? setTimeout(() => {
      child.kill("SIGTERM");
      setTimeout(() => child.kill("SIGKILL"), 250).unref();
    }, timeoutMs) : undefined;
    child.stdout?.setEncoding("utf8");
    child.stderr?.setEncoding("utf8");
    child.stdout?.on("data", (chunk) => { stdout += chunk; });
    child.stderr?.on("data", (chunk) => { stderr += chunk; });
    child.once("error", (error) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      reject(error);
    });
    child.once("close", (code, signal) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      const result = { command, args, cwd, code: code ?? 1, signal, stdout, stderr };
      if (check && result.code !== 0) {
        const error = new Error(`${command} ${args.join(" ")} exited ${result.code}: ${stderr.trim() || stdout.trim()}`);
        error.result = result;
        reject(error);
        return;
      }
      resolve(result);
    });
    if (input !== undefined) {
      child.stdin.write(input);
      child.stdin.end();
    }
  });
}

export function commandExists(command) {
  return runProcess("sh", ["-c", `command -v "$1" >/dev/null 2>&1`, "command-exists", command], { timeoutMs: 10_000 }).then((result) => result.code === 0);
}
