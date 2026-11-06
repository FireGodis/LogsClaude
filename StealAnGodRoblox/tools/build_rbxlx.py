#!/usr/bin/env python3
"""
build_rbxlx.py — builds build/StealAnGod.rbxlx from src/ using the same mapping as
default.project.json (Rojo conventions), with no external tools:

  src/shared  -> ReplicatedStorage.Shared               (Folder)
  src/server  -> ServerScriptService.Server             (Script, from init.server.luau)
  src/client  -> StarterPlayer.StarterPlayerScripts.Client (LocalScript, from init.client.luau)

  *.server.luau -> Script, *.client.luau -> LocalScript, *.luau -> ModuleScript,
  *.json -> ModuleScript returning the decoded table, folders -> Folder.

Open the generated file in Roblox Studio (File > Open from File), press Play — the world builds
itself on the first server start — or run tools/StudioWipeAndBuild.luau in the command bar to
generate the map in edit mode before publishing.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
_ref = [0]


def ref():
    _ref[0] += 1
    return f"RBX{_ref[0]:08X}"


def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def cdata(s: str) -> str:
    return "<![CDATA[" + s.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def lua_value(v, indent=1):
    pad = "\t" * indent
    if v is None:
        return "nil"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v) if isinstance(v, float) else str(v)
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, list):
        if not v:
            return "{}"
        return "{\n" + "".join(f"{pad}{lua_value(x, indent + 1)},\n" for x in v) + "\t" * (indent - 1) + "}"
    if isinstance(v, dict):
        items = [(k, x) for k, x in v.items() if x is not None]
        if not items:
            return "{}"
        return "{\n" + "".join(f"{pad}[{json.dumps(k, ensure_ascii=False)}] = {lua_value(x, indent + 1)},\n" for k, x in items) + "\t" * (indent - 1) + "}"
    raise TypeError(type(v))


def item(cls: str, name: str, source: str | None = None, children=()):
    props = f'<string name="Name">{esc(name)}</string>'
    if source is not None:
        props += f'<ProtectedString name="Source">{cdata(source)}</ProtectedString>'
    inner = "".join(children)
    return f'<Item class="{cls}" referent="{ref()}"><Properties>{props}</Properties>{inner}</Item>'


def file_item(path: str):
    name = os.path.basename(path)
    if name.endswith(".json"):
        data = json.load(open(path, encoding="utf-8"))
        return item("ModuleScript", name[:-5], "-- generated from " + name + "\nreturn " + lua_value(data) + "\n")
    src = open(path, encoding="utf-8").read()
    for suffix, cls in ((".server.luau", "Script"), (".client.luau", "LocalScript"), (".luau", "ModuleScript"), (".lua", "ModuleScript")):
        if name.endswith(suffix):
            return item(cls, name[: -len(suffix)], src)
    return None


def dir_item(path: str, name: str):
    children = []
    init_cls, init_src = "Folder", None
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        if entry in ("init.server.luau", "init.client.luau", "init.luau"):
            init_cls = {"init.server.luau": "Script", "init.client.luau": "LocalScript", "init.luau": "ModuleScript"}[entry]
            init_src = open(full, encoding="utf-8").read()
            continue
        if os.path.isdir(full):
            children.append(dir_item(full, entry))
        else:
            it = file_item(full)
            if it:
                children.append(it)
    return item(init_cls, name, init_src, children)


def main():
    src = os.path.join(ROOT, "src")
    shared = dir_item(os.path.join(src, "shared"), "Shared")
    server = dir_item(os.path.join(src, "server"), "Server")
    client = dir_item(os.path.join(src, "client"), "Client")
    body = (
        item("ReplicatedStorage", "ReplicatedStorage", None, [shared])
        + item("ServerScriptService", "ServerScriptService", None, [server])
        + item("StarterPlayer", "StarterPlayer", None, [item("StarterPlayerScripts", "StarterPlayerScripts", None, [client])])
    )
    xml = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">' + body + "</roblox>\n"
    out_dir = os.path.join(ROOT, "build")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "StealAnGod.rbxlx")
    with open(out, "w", encoding="utf-8") as f:
        f.write(xml)
    scripts = xml.count('class="ModuleScript"') + xml.count('class="Script"') + xml.count('class="LocalScript"')
    print(f"wrote {os.path.relpath(out, ROOT)} ({len(xml) // 1024} KB, {scripts} scripts)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
