---
title: Local HTTP Static Server
tool: server.py
category: server & dev
runtime: Python 3
aliases: [server, server-tool]
tags: [all-lads-tool, python, server]
---

# 🛠️ `server.py` — Local HTTP Static Server

> [!INFO]
> **Runtime**: Python 3 | **Directory**: `all-lads-tool/script/python/`

Boots a lightweight zero-dependency local HTTP static server serving repository public distribution.

---

## 1. Quick Syntax & Usage

```powershell
python all-lads-tool/script/python/server.py 8080
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `port` | int | No | `8080` | Listening HTTP port number |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/python/server.py`](..\../script/python/server.py)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
