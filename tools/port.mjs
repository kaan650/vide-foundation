// Copies a Foundation module into src/ and rewrites its instance requires to relative string requires.
// Usage: node tools/port.mjs <path under Foundation, e.g. Utility/lerp.lua> [more paths...]
// React, Dash, Flags and similar leftovers are reported, not rewritten.
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const FOUNDATION = path.join(
	process.env.LOCALAPPDATA,
	"Roblox Studio/ExtraContent/LuaPackages/Packages/_Index/Foundation/Foundation",
);
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, "$1")), "..");
const SRC = path.join(ROOT, "src");

// Instance path of a module file: init files are their folder.
function instancePath(relFile) {
	const parts = relFile.replace(/\\/g, "/").replace(/\.luau?$/, "").split("/");
	if (parts[parts.length - 1] === "init") parts.pop();
	return parts;
}

function relRequire(fromParts, targetParts) {
	if (fromParts.length === 0) return "@self/" + targetParts.join("/");
	const parent = fromParts.slice(0, -1);
	let k = 0;
	while (k < parent.length && k < targetParts.length && parent[k] === targetParts[k]) k++;
	const ups = parent.length - k;
	const rest = targetParts.slice(k).join("/");
	return (ups === 0 ? "./" : "../".repeat(ups)) + rest;
}

const REMAP = {
	"Packages/Dash": ["Utility", "Dash"],
	"Packages/Motion": ["Utility", "Motion"],
	"Packages/Otter": ["Utility", "Motion"],
	"Packages/ReactOtter": ["Utility", "Motion"],
};

export function port(relFile, destRel = relFile.replace(/\.lua$/, ".luau")) {
	let text = fs.readFileSync(path.join(FOUNDATION, relFile), "utf8").replace(/\r\n/g, "\n");
	const self = instancePath(destRel);
	const parent = self.slice(0, -1);
	const aliases = new Map(); // local name -> instance path parts

	const scriptPath = (expr) => {
		// script(.Parent)* (.Name)* -> parts, relative to this module's instance path
		const m = expr.match(/^script((?:\.Parent)*)((?:\.[A-Za-z_][A-Za-z0-9_]*)*)$/);
		if (!m) return null;
		const ups = (m[1].match(/\.Parent/g) || []).length;
		const names = m[2].split(".").filter(Boolean);
		const base = self.slice(0, self.length - ups);
		return [...base, ...names];
	};

	const resolveExpr = (expr) => {
		expr = expr.trim();
		const fromScript = scriptPath(expr);
		if (fromScript) return fromScript;
		const m = expr.match(/^([A-Za-z_][A-Za-z0-9_]*)((?:\.[A-Za-z_][A-Za-z0-9_]*)*)$/);
		if (!m || !aliases.has(m[1])) return null;
		const names = m[2].split(".").filter(Boolean);
		const base = aliases.get(m[1]);
		// "Parent" segments walk up
		const out = [...base];
		for (const n of names) {
			if (n === "Parent") out.pop();
			else out.push(n);
		}
		return out;
	};

	const lines = text.split("\n");
	const out = [];
	for (const line of lines) {
		let m;
		if ((m = line.match(/^local (\w+) = script:FindFirstAncestor\("Foundation"\)\s*$/))) {
			aliases.set(m[1], []);
			continue;
		}
		if ((m = line.match(/^local (\w+) = (\w+)\.Parent\s*$/)) && aliases.has(m[2]) && aliases.get(m[2]).length === 0) {
			aliases.set(m[1], ["Packages"]);
			continue;
		}
		if ((m = line.match(/^local (\w+) = (script(?:\.Parent)*(?:\.\w+)*|\w+(?:\.\w+)+)\s*$/))) {
			const p = resolveExpr(m[2]);
			if (p) {
				aliases.set(m[1], p);
				continue;
			}
		}
		out.push(line);
	}
	text = out.join("\n");

	text = text.replace(/require\(([^()"]+)\)/g, (whole, expr) => {
		let p = resolveExpr(expr);
		if (!p) return whole;
		p = REMAP[p.join("/")] ?? p;
		return `require("${relRequire(self, p)}")`;
	});

	const leftovers = [];
	// Scan code only: words inside strings and comments are not leftovers.
	const code = text.replace(/"[^"\n]*"/g, '""').replace(/--.*$/gm, "");
	for (const word of ["React", "ReactIs", "ReactUtils", "Flags", "Signal"]) {
		if (new RegExp(`\\b${word}\\b`).test(code)) leftovers.push(word);
	}
	for (const [name, p] of aliases) {
		if (new RegExp(`\\b${name}\\b`).test(code)) leftovers.push(`alias ${name}=${p.join(".")}`);
	}

	const dest = path.join(SRC, destRel);
	fs.mkdirSync(path.dirname(dest), { recursive: true });
	fs.writeFileSync(dest, text);
	return { dest: path.relative(ROOT, dest).replace(/\\/g, "/"), leftovers };
}

if (process.argv[1] && process.argv[1].endsWith("port.mjs")) {
	for (const arg of process.argv.slice(2)) {
		const [from, to] = arg.split("=");
		const r = port(from, to);
		console.log(`${r.dest}${r.leftovers.length ? "  [" + r.leftovers.join(", ") + "]" : ""}`);
	}
}
