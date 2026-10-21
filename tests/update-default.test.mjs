import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(new URL("../scripts/update-default.py", import.meta.url));

test("the action defaults to a documented exact CLI version", () => {
  const action = readFileSync(new URL("../action.yml", import.meta.url), "utf8");
  const version = action.match(/    default: "([0-9]+\.[0-9]+\.[0-9]+)"/);
  assert.ok(version, "The default must be an exact stable CLI version");
  const readme = readFileSync(new URL("../README.md", import.meta.url), "utf8");
  assert.ok(readme.includes(`currently \`${version[1]}\``));
});

for (const [release, expected, success] of [
  ["v0.6.0", "0.6.0", true],
  ["v0.10.0", "0.10.0", true],
  ["v0.5.0", "0.5.0", true],
  ["v0.4.0", "0.5.0", true],
  ["v0.6.0-rc.1", "0.5.0", false],
]) {
  test(`default update handles ${release}`, (t) => {
    const cwd = mkdtempSync(join(tmpdir(), "diplodocus-default-"));
    t.after(() => rmSync(cwd, { recursive: true, force: true }));
    writeFileSync(join(cwd, "action.yml"), '    default: "0.5.0"\n');
    writeFileSync(join(cwd, "README.md"), 'Default: `0.5.0`. Override: `0.4.0`.\n');
    const result = spawnSync("python3", [script], {
      cwd,
      env: { ...process.env, DIPLODOCUS_RELEASE: release },
      encoding: "utf8",
    });
    assert.equal(result.status === 0, success, result.stderr);
    assert.equal(readFileSync(join(cwd, "action.yml"), "utf8"), `    default: "${expected}"\n`);
    assert.equal(readFileSync(join(cwd, "README.md"), "utf8"), `Default: \`${expected}\`. Override: \`0.4.0\`.\n`);
  });
}
