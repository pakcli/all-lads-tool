#!/usr/bin/env python3
"""
Universal Blender FBX Exporter (Context: blender)
Lean orchestrator dynamically resolving Blender LTS version adapters.
"""
import os
import sys

output_file = sys.argv[1] if len(sys.argv) > 1 else "output.fbx"

# Determine Blender version (defaults to 4.2+, falls back to 3.6)
adapter_name = "v04-02-00"
adapter_path = os.path.join(os.path.dirname(__file__), "adapter", f"{adapter_name}.py")

if not os.path.exists(adapter_path):
    adapter_name = "v03-06-00"
    adapter_path = os.path.join(os.path.dirname(__file__), "adapter", f"{adapter_name}.py")

import importlib.util
spec = importlib.util.spec_from_file_location("blender_adapter", adapter_path)
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)

adapter.check_environment()
adapter.export_fbx(output_file)
