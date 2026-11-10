// Adds components to src/init.luau: the require, its exported types, and the entry in the components table.
// Usage: node tools/add-exports.mjs Checkbox Dropdown:DropdownProps,DropdownItem,DropdownItems
// Without a type list, every `export type` of the component's init.luau is re-exported.
import fs from "node:fs";
import path from "node:path";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, "$1")), "..");
const INIT = path.join(ROOT, "src/init.luau");
let text = fs.readFileSync(INIT, "utf8");

function components() {
	return [...text.matchAll(/^local (\w+) = require\("@self\/Components\/(\w+)"\)$/gm)]
		.map((m) => m[1])
		.filter((name) => name !== "Types");
}

for (const arg of process.argv.slice(2)) {
	const [name, typeList] = arg.split(":");
	if (components().includes(name)) {
		console.log(`${name}: already exported`);
		continue;
	}
	let types = typeList ? typeList.split(",") : [];
	if (!typeList) {
		const componentInit = path.join(ROOT, "src/Components", name, "init.luau");
		const source = fs.readFileSync(componentInit, "utf8");
		types = [...source.matchAll(/^export type (\w+)(<[^>]*>)?/gm)].map((m) => m[1] + (m[2] ?? ""));
	}
	const typeLines = types.map((t) => {
		const bare = t.replace(/<.*>/, "");
		const params = t.includes("<") ? t.slice(t.indexOf("<")).replace(/\s*=\s*[^,>]+/g, "") : "";
		return `export type ${t} = ${name}.${bare}${params}\n`;
	});
	const block = `local ${name} = require("@self/Components/${name}")\n${typeLines.join("")}\n`;
	const after = components()
		.filter((n) => n > name)
		.sort()[0];
	const marker = after
		? `local ${after} = require("@self/Components/${after}")`
		: 'local FoundationProvider = require("@self/Providers/Foundation/FoundationProvider")';
	text = text.replace(marker, block + marker);
	console.log(`${name}: ${types.length} types`);
}

const names = components().sort();
text = text.replace(/\t-- Components\n(\t\w+ = \w+,\n)+/, "\t-- Components\n" + names.map((n) => `\t${n} = ${n},\n`).join(""));
fs.writeFileSync(INIT, text);
