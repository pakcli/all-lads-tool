---
name: skill-scope-lifecycle-activation
aliases: [skill-scope-levels-project-epoch-oneshot, three-tier-skill-scope, skill-execution-scope-lifecycle, skill-scope-taxonomy]
category: AGENTIC_DEVELOPMENT_LIFECYCLE
tags: [all-lads-tool, skill, scope, lifecycle, activation, session, milestone, one-shot, protocol]
description: Three-tier skill execution and lifecycle scoping standard classifying skills into Session-Wide (whole chat), Milestone/Epoch-Bounded (until a certain point), and One-Shot (single turn ephemeral).
dependencies:
  - "[[01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED]]"
  - "[[zero-hardcoded-sensitive-variables]]"
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
related:
  - "[[decoupled-skill-trigger-catalog]]"
  - "[[ai-code-editing-iteration-flow]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
pros:
  - "Eliminates cognitive clutter by preventing one-shot directives from lingering across future prompts"
  - "Provides clear lifecycle boundaries for milestone-specific quarantines and release combos"
  - "Keeps safety invariants permanently active throughout the entire session without manual re-triggering"
cons:
  - "Requires agents to track scope expiration conditions at the end of each turn"
---

# Three-Tier Skill Scope & Lifecycle Activation (`skill-scope-lifecycle-activation`)

> [!IMPORTANT]
> **THE 3-TIER SCOPE INVARIANT**:
> Directives, skills, and execution modes must never be treated as having identical lifecycles.
> Every skill belongs to one of three discrete activation tiers:
> 1. **Session Scope (Whole Chat)**: Permanently active across all turns in the session.
> 2. **Milestone Scope (Certain Point)**: Active across multiple turns until a designated checkpoint or condition is fulfilled.
> 3. **One-Shot Scope (Single Turn)**: Active strictly for the current prompt; immediately expires upon delivery.

---

## 1. Architectural Scope Matrix

| Scope Tier | Temporal Lifetime | Activation Trigger | Expiration / Deactivation | Example Skills |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Session Scope** | Entire chat session / project lifecycle | Configured on session start or permanent repo rule | Never expires; active until explicitly repealed | `zero-hardcoded-sensitive-variables`<br/>`01-number-one-rule-DONOT-REMOVE...`<br/>`ai-code-editing-iteration-flow` |
| **Tier 2: Milestone Scope** | Multiple turns (epoch/checkpoint) | User initiates a bounded workflow or brief milestone | Automatically expires once the gate or milestone is approved | `donot-code-yet-allow-markdown...`<br/>`update-readme-and-guide-and-what...`<br/>`git-checkpoint-rollback` |
| **Tier 3: One-Shot Scope** | Single prompt / response turn only | Tagged or invoked for an immediate specific task | Expires immediately at the end of the current turn (*"after this, the thing isn't anymore"*) | `say-sorry-*`<br/>`protocol-dry-run` (single preview)<br/>`interactive-asking-cli` |

---

## 2. Monospace Lifecycle Pipeline Diagram

```text
+-------------------------------------------------------------------------------+
|                    THREE-TIER SKILL SCOPE & LIFECYCLE                         |
+-------------------------------------------------------------------------------+
|                                                                               |
|  TIER 1: SESSION SCOPE (WHOLE CHAT)                                           |
|  [Session Start] =============================================> [Session End] |
|  - Invariant rules that guard repo safety, coding ethics, and confidentiality |
|  - Always active on every turn; zero decay                                    |
|                                                                               |
|  TIER 2: MILESTONE SCOPE (TO CERTAIN POINT)                                   |
|  [User: "buat brief 04-00"] ---> [Drafting] ---> [User approves]              |
|  | <------ donot-code-yet active ------> |             |                      |
|                                                        v                      |
|                                             [Deactivated / Next Milestone]    |
|                                                                               |
|  TIER 3: ONE-SHOT SCOPE (SINGLE CHAT ONLY)                                    |
|  [User Prompt] ---> [Single Turn Delivery] ---> [EXPIRED / GONE]              |
|  - One-time apology, quick preview, or ad-hoc diagnostic                      |
|  - Clean teardown; leaves zero lingering constraints on subsequent prompts    |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 3. Detailed Scope Specifications

### 3.1 Tier 1: Session Scope (`scope: session`)
- **Intent**: Foundational safety, coding standards, and repository invariants.
- **Agent Behavior**: The agent must evaluate every action against these skills on every single turn.
- **Persistence**: Retained in working context; never dropped.
- **Representative Skills**:
  - `zero-hardcoded-sensitive-variables`: Never leak machine paths or credentials.
  - `01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED`: Never delete unrequested code.
  - `ai-code-editing-iteration-flow`: Always modify `src/` directly; strictly zero scratch scripts.

### 3.2 Tier 2: Milestone Scope (`scope: milestone`)
- **Intent**: Bounded workflows that span several steps to achieve a specific milestone.
- **Agent Behavior**: The agent applies the constraints until the target outcome is verified or the user grants explicit permission to transition.
- **Expiration Trigger**:
  - Reaching a completion condition (e.g. user approves design brief -> release `donot-code-yet`).
  - Proposing a commit message -> release `update-readme-and-guide-and-what-commit-message-donot-commit-yet`.
- **Representative Skills**:
  - `donot-code-yet-allow-markdown-creation-brief-only`: Freezes code until architectural brief sign-off.
  - `brief-revisions-to-perfection`: Active during multi-pass review roadmap.

### 3.3 Tier 3: One-Shot Scope (`scope: one-shot`)
- **Intent**: Ephemeral commands, single-response interventions, or single-action corrections.
- **Agent Behavior**: The agent applies the skill exclusively to formulate the immediate response. In the subsequent turn, the skill is considered dormant and inactive unless tagged again.
- **Crucial Invariant**: *"After this, the thing isn't anymore."* The agent must NOT drag single-turn behaviors into subsequent unrelated prompts.
- **Representative Skills**:
  - `say-sorry-agent-make-decision-not-based-on-brief-latest-version`: Formulate apology and realign in current response only.
  - `run-dry` / `protocol-dry-run`: Provide one preview output without binding future runs to dry-run mode.
  - `wdyt`: Provide a one-off critical review without continuing to critique in later implementation steps.

---

## 4. Metadata Schema Declaration

Skills can declare their default intended scope in YAML frontmatter, and projects can override them in `_catalog.json`:

### Markdown Frontmatter
```yaml
---
name: sample-skill
scope: one-shot    # Options: session | milestone | one-shot
---
```

### Decoupled Catalog Registry (`_catalog.json`)
```json
[
  {
    "slug": "ai-code-editing-iteration-flow",
    "scope": "session"
  },
  {
    "slug": "donot-code-yet-allow-markdown-creation-brief-only",
    "scope": "milestone",
    "expires_on": "user_design_approval"
  },
  {
    "slug": "say-sorry-agent-make-decision-not-based-on-brief-latest-version",
    "scope": "one-shot"
  }
]
```

---

## 5. Agent Verification Checklist

When processing any prompt:

- [ ] **Tier 1 Audit**: Are all Session-Scope safety invariants active and respected?
- [ ] **Tier 2 Audit**: Has the active milestone condition been reached? If yes, transition out cleanly.
- [ ] **Tier 3 Audit**: Was a One-Shot skill executed in this turn? If yes, ensure it is marked expired and not carried over to the next turn.
