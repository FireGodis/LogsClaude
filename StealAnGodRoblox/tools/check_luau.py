#!/usr/bin/env python3
"""
check_luau.py — lightweight structural checker for the Luau sources (no external deps).

It is NOT a replacement for luau-analyze/selene; it catches the mistakes that break a whole
script at load time:
  * unbalanced blocks (function/if/for/while/do/repeat ... end/until)
  * unbalanced (), {}, []
  * C-style operators that are invalid in Luau (!=, &&, ||)
  * unterminated strings / long comments
  * requires of Shared/Server modules that do not exist on disk
  * Net remote/action names used but not declared in Util/Net.luau

Usage: python3 tools/check_luau.py [src_dir]
Exit code 1 when problems are found.
"""
import os
import re
import sys

KEYWORDS_OPEN = {"function", "if", "do", "repeat"}


def tokenize(src: str, path: str, errors: list):
    i, n, line = 0, len(src), 1
    tokens = []
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c in " \t\r":
            i += 1
            continue
        # comments
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            if m:
                close = "]" + m.group(1) + "]"
                j = src.find(close, i + len(m.group(0)))
                if j < 0:
                    errors.append(f"{path}:{line}: unterminated long comment")
                    return tokens
                line += src.count("\n", i, j)
                i = j + len(close)
            else:
                j = src.find("\n", i)
                i = n if j < 0 else j
            continue
        # long strings
        m = re.match(r"\[(=*)\[", src[i:])
        if m:
            close = "]" + m.group(1) + "]"
            j = src.find(close, i + len(m.group(0)))
            if j < 0:
                errors.append(f"{path}:{line}: unterminated long string")
                return tokens
            line += src.count("\n", i, j)
            tokens.append(("str", "", line))
            i = j + len(close)
            continue
        # quoted strings
        if c in "\"'`":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 1
                elif src[j] == "\n" and c != "`":
                    errors.append(f"{path}:{line}: unterminated string")
                    break
                j += 1
            line += src.count("\n", i, j)
            tokens.append(("str", src[i + 1 : j], line))
            i = j + 1
            continue
        m = re.match(r"[A-Za-z_][A-Za-z0-9_]*", src[i:])
        if m:
            tokens.append(("name", m.group(0), line))
            i += len(m.group(0))
            continue
        m = re.match(r"0[xX][0-9a-fA-F_]+|\d[\d_]*(\.\d*)?([eE][+-]?\d+)?|\.\d+", src[i:])
        if m:
            tokens.append(("num", m.group(0), line))
            i += len(m.group(0))
            continue
        for op in ("!=", "&&", "||"):
            if src.startswith(op, i):
                errors.append(f"{path}:{line}: invalid operator '{op}'")
        tokens.append(("op", c, line))
        i += 1
    return tokens


def check_blocks(tokens, path, errors):
    stack = []
    pending_do = 0
    brackets = []
    pairs = {")": "(", "}": "{", "]": "["}
    prev = None
    for kind, val, line in tokens:
        if kind == "op":
            if val in "({[":
                brackets.append((val, line))
            elif val in ")}]":
                if not brackets or brackets[-1][0] != pairs[val]:
                    errors.append(f"{path}:{line}: unbalanced '{val}'")
                    return
                brackets.pop()
        elif kind == "name":
            # ignore field access like a.end / a:function (not valid anyway) and keys like {end=1}
            if prev is not None and prev[0] == "op" and prev[1] in ".:" :
                prev = (kind, val, line)
                continue
            if val in ("for", "while"):
                pending_do += 1
                stack.append((val, line))
            elif val == "do":
                if pending_do > 0:
                    pending_do -= 1
                else:
                    stack.append(("do", line))
            elif val in ("function", "if", "repeat"):
                stack.append((val, line))
            elif val == "end":
                if not stack:
                    errors.append(f"{path}:{line}: 'end' without open block")
                    return
                top = stack.pop()
                if top[0] == "repeat":
                    errors.append(f"{path}:{line}: 'end' closes 'repeat' from line {top[1]}")
            elif val == "until":
                if not stack or stack[-1][0] != "repeat":
                    errors.append(f"{path}:{line}: 'until' without 'repeat'")
                    return
                stack.pop()
        prev = (kind, val, line)
    for kw, line in stack:
        errors.append(f"{path}:{line}: '{kw}' never closed")
    for b, line in brackets:
        errors.append(f"{path}:{line}: '{b}' never closed")


def module_exists(root, parts):
    """parts like ['Shared','Util','Net'] -> src/shared/Util/Net.luau etc."""
    mapping = {"Shared": "shared", "Server": "server", "Client": "client"}
    if not parts or parts[0] not in mapping:
        return True
    base = os.path.join(root, mapping[parts[0]], *parts[1:])
    for ext in (".luau", ".lua", ".json", "/init.luau", ".server.luau", ".client.luau"):
        if os.path.exists(base + ext):
            return True
    return os.path.isdir(base)


def check_cross_module(root):
    """Every S.<System>.<fn> (server) / C.<Ctrl>.<fn> (client) must be defined by that module."""
    errs = []
    for side, var, dirs in (("server", "S", ("Systems", "Bots", "World")), ("client", "C", ("Controllers", "UI", ""))):
        defs = {}
        for d in dirs:
            folder = os.path.join(root, side, d)
            if not os.path.isdir(folder):
                continue
            for name in os.listdir(folder):
                if name.endswith(".luau"):
                    mod = name.split(".")[0]
                    src = open(os.path.join(folder, name), encoding="utf-8").read()
                    fns = set(re.findall(r"^function\s+" + re.escape(mod) + r"[.:](\w+)", src, re.M))
                    fns |= set(re.findall(r"^" + re.escape(mod) + r"\.(\w+)\s*=", src, re.M))
                    defs[mod] = fns
        extra = {"server": {"WorldBuilder", "Net"}, "client": {"State"}}[side]
        for dirpath, _, names in os.walk(os.path.join(root, side)):
            for name in names:
                if not name.endswith(".luau"):
                    continue
                path = os.path.join(dirpath, name)
                src = open(path, encoding="utf-8").read()
                for m in re.finditer(r"\b" + var + r"\.(\w+)\.(\w+)", src):
                    mod, fn = m.group(1), m.group(2)
                    if mod in extra:
                        continue
                    if mod not in defs:
                        errs.append(f"{os.path.relpath(path, root)}: unknown module {var}.{mod}")
                    elif fn not in defs[mod]:
                        errs.append(f"{os.path.relpath(path, root)}: {var}.{mod}.{fn} is not defined")
    return errs


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "src")
    root = os.path.abspath(root)
    errors = []
    files = 0
    net_src = open(os.path.join(root, "shared", "Util", "Net.luau"), encoding="utf-8").read()
    declared = set(re.findall(r"^\t(\w+) = \d+,", net_src, re.M)) | set(re.findall(r'"(\w+)"', net_src.split("Net.ServerEvents")[1].split("}")[0]))
    for dirpath, _, names in os.walk(root):
        for name in names:
            if not name.endswith((".luau", ".lua")):
                continue
            path = os.path.join(dirpath, name)
            rel = os.path.relpath(path, root)
            src = open(path, encoding="utf-8").read()
            files += 1
            for m in re.finditer(r"^\s*(?:local\s+)?function\s+[\w.:]*\[", src, re.M):
                errors.append(f"{rel}:{src.count(chr(10), 0, m.start()) + 1}: invalid function name (use t[k] = function)")
            toks = tokenize(src, rel, errors)
            check_blocks(toks, rel, errors)
            for m in re.finditer(r"require\((?:ReplicatedStorage|game:GetService\(\"ReplicatedStorage\"\))\.(Shared(?:\.\w+)+)\)", src):
                if not module_exists(root, m.group(1).split(".")):
                    errors.append(f"{rel}: require of missing module {m.group(1)}")
            for m in re.finditer(r"require\(Shared\.((?:\w+\.)*\w+)\)", src):
                if not module_exists(root, ["Shared"] + m.group(1).split(".")):
                    errors.append(f"{rel}: require of missing module Shared.{m.group(1)}")
            for m in re.finditer(r"Net\.(?:fire|fireAll|send|listen|handle|on|request)\(\s*(?:[\w.]+,\s*)?\"(\w+)\"", src):
                if m.group(1) not in declared:
                    errors.append(f"{rel}: remote/action '{m.group(1)}' not declared in Net.luau")
    errors.extend(check_cross_module(root))
    if errors:
        print("\n".join(errors))
        print(f"\n{len(errors)} problem(s) in {files} files")
        sys.exit(1)
    print(f"OK — {files} Luau files, blocks/brackets balanced, remotes declared, requires resolved")


if __name__ == "__main__":
    main()
