#!/usr/bin/env bash
# Strict analyzer gate: prints one line per distinct error location in our own code (vendored data is skipped).
cd "$(dirname "$0")/.."
rojo sourcemap dev.project.json --output sourcemap.json >/dev/null
LSP=$(ls -d ~/.vscode/extensions/johnnymorganz.luau-lsp-*-win32-x64 | tail -1)/bin/server.exe
DEFS="$APPDATA/Code/User/globalStorage/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau"
"$LSP" analyze --platform roblox --sourcemap sourcemap.json --definitions "@roblox=$DEFS" --flag:LuauSolverV2=true "${@:-src/}" 2>&1 \
	| grep -E '^[A-Za-z]:|^src' | grep -vE 'src[\/](Packages|Generated)[\/]' | sed -E 's/ \[game[^]]*\]//' | sort -u
