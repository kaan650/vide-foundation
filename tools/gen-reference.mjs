// Builds reference.project.json: Roblox's React Foundation and its dependency closure, served from the local Studio
// install so stories can render the original next to the Vide port. SafeFlags is replaced by a copy that answers
// with the live client values, because Studio's command bar and plugins cannot read FFlags and would turn every
// flag on. Run again after a Studio update. The output is machine-specific and gitignored.
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, "$1")), "..");
const INDEX = path.join(process.env.LOCALAPPDATA, "Roblox Studio/ExtraContent/LuaPackages/Packages/_Index");
const OUT = path.join(ROOT, "reference");

const seen = new Set();
const queue = ["Foundation"];
while (queue.length) {
	const dir = queue.pop();
	if (seen.has(dir)) continue;
	seen.add(dir);
	for (const file of fs.readdirSync(path.join(INDEX, dir))) {
		const full = path.join(INDEX, dir, file);
		if (!file.endsWith(".lua") || !fs.statSync(full).isFile()) continue;
		const match = fs.readFileSync(full, "utf8").match(/PackageIndex\["([^"]+)"\]/);
		if (match) queue.push(match[1]);
	}
}

const response = await fetch("https://clientsettingscdn.roblox.com/v2/settings/application/PCDesktopClient");
const settings = (await response.json()).applicationSettings;
const flags = {};
for (const [key, value] of Object.entries(settings)) {
	const match = key.match(/^[DF]?FFlag(.+)$/);
	if (match) flags[match[1]] = value === "True" || value === "true";
}

fs.rmSync(OUT, { recursive: true, force: true });
const safeFlags = path.join(OUT, "SafeFlags/SafeFlags");
fs.mkdirSync(safeFlags, { recursive: true });
fs.copyFileSync(path.join(INDEX, "SafeFlags/SafeFlags/init.lua"), path.join(safeFlags, "init.lua"));
for (const name of ["createGetFInt.lua", "createGetFString.lua"]) {
	fs.copyFileSync(path.join(INDEX, "SafeFlags/SafeFlags", name), path.join(safeFlags, name));
}
const entries = Object.entries(flags)
	.filter(([name]) => /^[A-Za-z0-9_]+$/.test(name))
	.map(([name, value]) => `\t${name} = ${value},`)
	.join("\n");
fs.writeFileSync(
	path.join(safeFlags, "createGetFFlag.lua"),
	`-- Live PCDesktopClient values; a flag the client doesn't list is false, as DefineFastFlag would make it.\nlocal live = {\n${entries}\n}\n\nlocal function createGetFFlag(name: string, value: boolean?): () -> boolean\n\tlocal resolved = live[name]\n\tif resolved == nil then\n\t\tresolved = value == true\n\tend\n\treturn function()\n\t\treturn resolved\n\tend\nend\n\nreturn createGetFFlag\n`,
);

const index = { $className: "Folder" };
for (const dir of [...seen].sort()) {
	index[dir] = { $path: dir === "SafeFlags" ? "reference/SafeFlags" : path.join(INDEX, dir).replace(/\\/g, "/") };
}
fs.writeFileSync(
	path.join(ROOT, "reference.project.json"),
	JSON.stringify({ name: "ReferencePackages", tree: { $className: "Folder", _Index: index } }, null, "\t") + "\n",
);
console.log(`${seen.size} packages, ${Object.keys(flags).length} live flags`);
