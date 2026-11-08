---
name: zero-hardcoded-sensitive-variables-without-agent-reading-sistem
aliases: [zero-hardcoded-sensitive-variables-without-agent-reading-system, no-agent-system-probing, workspace-isolated-zero-system-read]
category: SECURITY_AND_PORTABILITY_STANDARD
tags: [all-lads-tool, skill, security, containment, privacy, path-traversal, zero-system-read]
description: Security standard mandating zero hardcoded secrets and prohibiting AI agents from reading or probing host system directories (C:\, user profiles, OS partitions), while allowing documentation to reference generic system directories with strictly censored usernames.
dependencies:
  - "[[zero-hardcoded-sensitive-variables]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[modular-architecture-standard]]"
related:
  - "[[sensitive-data-sanitizer]]"
  - "[[donot-commit-yet]]"
pros:
  - "Prevents autonomous agents from scanning, probing, or reading host operating system files"
  - "Protects user identity by mandating username censoring when system paths are referenced"
  - "Enforces strict boundary confinement within the authorized workspace root"
cons:
  - "Restricts agents from inspecting host system state or global runtime configurations directly"
---

# Zero Hardcoded Sensitive Variables - Without Agent Reading System (`zero-hardcoded-sensitive-variables-without-agent-reading-sistem`)

> [!IMPORTANT]
> **THE AGENT SYSTEM-READ QUARANTINE INVARIANT**:
> 1. **Zero Agent System Reading**: Agents are strictly prohibited from executing read operations, directory listings, or content inspections on host OS partitions, system root directories, or user home directories outside the authorized workspace root (e.g. `C:\`, `C:\Users\`, `C:\Windows\`, `/etc/`).
> 2. **Generic System Documentation Allowed**: Explaining system mechanics, global runtimes, or OS architecture in documentation is permitted using generic paths without personal usernames.
> 3. **Mandatory Username Masking**: Whenever system paths must reference user-level paths, the personal username must be strictly censored (`C:\Users\us****\...` or `%USERPROFILE%`).
> 4. **Strict Workspace Isolation**: All file operations, reads, writes, and script executions by agents must remain completely confined within the authorized `<workspace_root>`.

---

## 1. Permitted vs. Prohibited Matrix

| Action / Entity | Permitted (Compliant) | Prohibited (Violation) |
| :--- | :--- | :--- |
| **Agent File Reads** | Confined inside `./` or `<workspace_root>` | Reading host directories (`C:\...`, `/home/...`) |
| **System Inspection** | Resolving commands via system `PATH` | Calling read/list tools on OS root partitions |
| **System Docs Reference**| Generic paths (`C:\Program Files\`, `%APPDATA%`)| Hardcoding unmasked user machine accounts |
| **User Path In Docs** | Censored username (`C:\Users\us****\...`) | Raw personal user profile (`C:\Users\rawuser\...`) |
| **Credentials & Tokens** | Environment variables (`$env:KEY`, `process.env`) | Plaintext secrets in source or configurations |
| **Workspace Navigation** | Bounded relative navigation (`../sibling-dir`) | Ascending above authorized workspace root |

---

## 2. Containment Topology

```text
┌────────────────────────────────────────────────────────┐
│ AGENT SYSTEM-READ QUARANTINE BOUNDARY                  │
├────────────────────────────────────────────────────────┤
│ HOST SYSTEM PARTITION (C:\, /etc/, /var/):             │
│   - Status: STRICT READ QUARANTINE                     │
│   - Agent Read Tools: BLOCKED / PROHIBITED             │
│   - Documentation : Generic references allowed         │
│   - Username Segment: MANDATORY CENSORING              │
│                                                        │
│ AUTHORIZED WORKSPACE ROOT (<workspace_root>/):         │
│   - Status: AUTHORIZED WORKSPACE JAIL                  │
│   - Agent Read Tools: PERMITTED                        │
│   - Relative Paths : PERMITTED (bounded within root)   │
└────────────────────────────────────────────────────────┘
```

---

## 3. Operational Rules for AI Agents

### 3.1 Prohibited System Probing
Agents must NEVER invoke file inspection or command tools targeting host system directories:
- Forbidden: `Get-ChildItem C:\Users\`
- Forbidden: `read_file Path: "C:\Windows\System32\..."`
- Forbidden: Traversing up to the system root (`cd ../../../.. && dir C:\`)

### 3.2 System Documentation Standard
When describing system setups, installations, or runtime prerequisites in documentation:
- Use standard environment variable tokens: `%APPDATA%`, `%USERPROFILE%`, `$HOME`.
- Use generic program directories without usernames: `C:\Program Files\nodejs\`.
- If referring to a concrete user directory, apply the 2-letter masking standard: `C:\Users\us****\AppData\...`.

---

## 4. Verification Checklist

Before finalizing any task or documentation:

- [ ] Confirm the agent executed **zero read operations** outside the workspace root boundary.
- [ ] Confirm no raw personal usernames appear in documentation, logs, or code.
- [ ] Confirm all project paths remain relative and bounded within `<workspace_root>`.
- [ ] Confirm system paths mentioned in documentation use generic paths or censored usernames.
- [ ] Confirm zero plaintext secrets or tokens exist in source code or templates.
