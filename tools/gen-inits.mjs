// Writes Components/<Name>/init.luau for every component folder that has <Name>.luau but no init.luau.
// The init re-exports the component and its exported types, like Foundation's init modules.
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, "$1")), "../src/Components");
for (const name of fs.readdirSync(root)) {
	const dir = path.join(root, name);
	if (!fs.statSync(dir).isDirectory()) continue;
	const main = path.join(dir, `${name}.luau`);
	const init = path.join(dir, "init.luau");
	if (!fs.existsSync(main) || fs.existsSync(init)) continue;
	const source = fs.readFileSync(main, "utf8");
	const types = [...source.matchAll(/^export type (\w+)(<[^>]*>)?/gm)].map((m) => {
		const params = m[2] ? m[2].replace(/\s*=\s*[^,>]+/g, "") : "";
		return `export type ${m[1]}${m[2] ?? ""} = ${name}.${m[1]}${params}`;
	});
	const body = [`local ${name} = require("@self/${name}")`, "", ...types, ...(types.length ? [""] : []), `return ${name}`, ""];
	fs.writeFileSync(init, body.join("\n"));
	console.log(`Components/${name}/init.luau`);
}
