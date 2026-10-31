---
name: donot-overengineer-instructions
aliases: [no-overengineering, strict-scope-adherence, zero-unsolicited-features]
category: AGENT_BEHAVIOR_PROTOCOL
tags: [all-lads-tool, protocol, rules, scope, discipline]
description: Strict 5-line agent discipline protocol prohibiting unsolicited feature injection, scope creep, and over-engineering.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 🛑 Zero Over-Engineering Protocol (`donot-overengineer-instructions`)

1. **Strict Scope Adherence**: Execute exactly what was commanded—never assume, invent, or inject unrequested features.
2. **Boundary Separation**: Instructions for documentation (README/docs) must stay in docs; never inject them into code or menus.
3. **Pure Single-Responsibility**: Keep CLI menus, dispatchers, and scripts strictly confined to their designated functional scope.
4. **Suggest First, Never Force**: If an optimization or shortcut comes to mind, propose it as text first—never build without permission.
5. **Zero Scope Creep**: Deliver the minimal, direct solution with zero unsolicited architectural expansion.
