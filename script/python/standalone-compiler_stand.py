#!/usr/bin/env python3
"""
PY_STANDALONE-COMPILER.PY
Inlines modular Python dependencies from module/ into a standalone, zero-dependency .py script.
"""

import sys
import os
import re

if len(sys.argv) < 2:
    print("Usage: python py_standalone-compiler.py <source_file.py> [output_file.py]")
    sys.exit(1)

source_file = os.path.abspath(sys.argv[1])
output_file = (
    os.path.abspath(sys.argv[2])
    if len(sys.argv) > 2
    else os.path.join(
        os.path.dirname(source_file),
        re.sub(r"_stand$", "", os.path.splitext(os.path.basename(source_file))[0]) + "_stand.py",
    )
)

if not os.path.exists(source_file):
    print(f"[ERROR] Source file not found: {source_file}")
    sys.exit(1)

print(f"[*] Compiling Python script: {os.path.basename(source_file)} -> {output_file} ...")

with open(source_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

inlined = [
    "# ==========================================================================\n",
    "# COMPILED STANDALONE PYTHON - ALL-LADS-TOOL\n",
    f"# Source: {os.path.basename(source_file)}\n",
    "# ==========================================================================\n\n",
]

module_dir = os.path.join(os.path.dirname(source_file), "module")

for line in lines:
    match = re.match(r"^\s*from\s+module\.(\w+)\s+import\s+(.*)", line)
    if match and os.path.exists(module_dir):
        mod_name = match.group(1)
        mod_file = os.path.join(module_dir, f"{mod_name}.py")
        if os.path.exists(mod_file):
            print(f"  [+] Inlining module: {mod_name}.py")
            with open(mod_file, "r", encoding="utf-8") as mf:
                mod_content = mf.read()
            inlined.append(f"# --- [INLINED MODULE: {mod_name}.py] ---\n")
            inlined.append(mod_content + "\n")
            inlined.append(f"# --- [END INLINED MODULE: {mod_name}.py] ---\n\n")
            continue
    inlined.append(line)

os.makedirs(os.path.dirname(output_file), exist_ok=True)
with open(output_file, "w", encoding="utf-8") as f:
    f.writelines(inlined)

print(f"[OK] Standalone Python script generated: {output_file}")
