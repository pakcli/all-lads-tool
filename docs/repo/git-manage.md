---
title: Git Manager
tool: git-manage.ps1
category: repo & git
runtime: PowerShell 5.1+ / 7+
aliases: [git-manage, repo-manager]
tags: [all-lads-tool, repo, git, adapter]
---

# `git-manage.ps1` — Universal Git Manager (Context: Repo)

> [!INFO]
> **Context**: `repo` | **Directory**: `all-lads-tool/script/repo/`
> **Adapters**: `adapter/v02-30-00.psm1` (Git 2.30+), `adapter/v02-40-00.psm1` (Git 2.40+)

Orchestrator Git yang mendeteksi versi Git runtime di mesin pengembang secara dinamis dan memuat adapter yang sesuai.
