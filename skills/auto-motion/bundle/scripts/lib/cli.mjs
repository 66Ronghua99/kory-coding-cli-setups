export function parseArgs(argv = process.argv.slice(2)) {
  const options = {};
  const positionals = [];
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === "--") {
      positionals.push(...argv.slice(index + 1));
      break;
    }
    if (!token.startsWith("--")) {
      positionals.push(token);
      continue;
    }
    const body = token.slice(2);
    const equals = body.indexOf("=");
    if (equals >= 0) {
      options[body.slice(0, equals)] = body.slice(equals + 1);
      continue;
    }
    const next = argv[index + 1];
    if (next && !next.startsWith("--")) {
      options[body] = next;
      index += 1;
    } else {
      options[body] = true;
    }
  }
  return { options, positionals };
}

export function option(options, name, fallback = undefined) {
  return options[name] === undefined ? fallback : options[name];
}

export function requiredOption(options, name) {
  const value = options[name];
  if (value === undefined || value === true || value === "") {
    throw new Error(`Missing required option --${name}`);
  }
  return value;
}

export function printJson(value) {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}

export function failCli(error) {
  const message = error instanceof Error ? error.message : String(error);
  process.stderr.write(`${message}\n`);
  process.exitCode = 1;
}

export function asBoolean(value) {
  if (value === true || value === "true" || value === "1") return true;
  if (value === false || value === "false" || value === "0") return false;
  throw new Error(`Expected boolean, got ${value}`);
}
