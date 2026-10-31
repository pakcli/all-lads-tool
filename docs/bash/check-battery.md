---
title: Cross-Platform Battery Detail & Health Viewer
tool: sh_check-battery.sh
category: system & telemetry
runtime: Bash / Git Bash / Linux / macOS
aliases: [check-battery, battery-detail]
tags: [all-lads-tool, bash, git-bash, battery, telemetry]
---

# `sh_check-battery.sh` – Battery Telemetry & Detail Viewer

> [!INFO]
> **Runtime**: Bash 4+ / Git Bash (Windows) / macOS / Linux | **Directory**: `all-lads-tool/script/bash/`

Cross-platform battery inspection and health monitoring tool designed to run seamlessly in **Git Bash on Windows**, Linux laptops, and macOS.

---

## 1. Quick Usage

### In Git Bash (Windows):
```bash
./all-lads-tool/script/bash/sh_check-battery.sh
```

### In Linux / macOS / WSL:
```bash
bash ./all-lads-tool/script/bash/sh_check-battery.sh
```

---

## 2. Capabilities & Subsystem Detection

| Environment | Inspection Method | Extracted Metrics |
| :--- | :--- | :--- |
| **Git Bash (Windows)** | Windows CIM / WMI (`Win32_Battery`) | Charge %, Status, Design Voltage, Chemistry, Battery Name |
| **Linux (Laptop/WSL)** | `/sys/class/power_supply/BAT*` | Capacity, Status, Model, Health, Cycle Count |
| **macOS (Darwin)** | `pmset -g batt` | Native battery percentage, power source, charging state |

---

## 3. Rule Compliance
- **Rule #002**: Zero horizontal scroll guaranteed. Output is formatted with clean vertical telemetry cards and visual progress bars.
- **Rule #004**: Enforces `sh_<name>.sh` prefix convention for standalone executable shell scripts.
