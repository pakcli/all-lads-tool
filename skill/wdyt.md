---
name: wdyt
aliases: [what-do-you-think, critical-evaluation, code-architecture-critique, architectural-review]
category: CRITIQUE_EVALUATION
tags: [all-lads-tool, skill, review, critique, evaluation, architecture, code-review]
description: High-fidelity critical evaluation standard for assessing architecture, code quality, design paradigms, and usability. Delivers unvarnished, deep engineering critiques highlighting structural strengths, systemic flaws, architectural blind spots, and security/performance risks.
pros:
  - "Eliminates superficial praise in favor of rigorous, evidence-based technical assessment"
  - "Surfaces architectural bottlenecks, hidden assumptions, and potential edge-case failures upfront"
  - "Evaluates systems holistically across logic, DX, UX, scalability, and security vectors"
cons:
  - "Requires comprehensive codebase or design context to avoid incorrect assumptions"
  - "Demands strict balance between identifying problems and understanding project scope constraints"
---

# What Do You Think Evaluation Standard (`wdyt`)

> [!IMPORTANT]
> **THE UNVARNISHED CRITIQUE INVARIANT**:
> The `wdyt` standard demands uncompromising engineering honesty. Evaluations must reject hollow flattery and perform deep, structural analysis based on first principles, observable code artifacts, concrete failure modes, and user friction points.

---

## 1. Architectural Critique Topology

```text
+-------------------------------------------------------------------------------+
|                            WDYT EVALUATION TOPOLOGY                           |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ Artifact Under Review: Codebase / Architecture / Design / PR ]            |
|                                |                                              |
|         +----------------------+----------------------+                       |
|         |                      |                      |                       |
|         v                      v                      v                       |
|  [ 1. ARCHITECTURE ]    [ 2. CODE QUALITY ]    [ 3. USER EXPERIENCE ]         |
|  - System Boundaries    - Type Correctness     - Ergonomics & Flow            |
|  - Separation of Concerns- Logic Clarity       - Mental Model Fit             |
|  - Coupling & Cohesion  - Error Surface Area   - Accessibility / Friction     |
|         |                      |                      |                       |
|         +----------------------+----------------------+                       |
|                                |                                              |
|         +----------------------+----------------------+                       |
|         |                                             |                       |
|         v                                             v                       |
|  [ 4. EDGE CASES & DEFENSE ]                   [ 5. PERFORMANCE & SCALE ]     |
|  - Race Conditions & State Drift               - Latency & Allocations        |
|  - Boundary Violations & Security              - Complexity Big-O & Leaks     |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 2. Core Pillars of Evaluation

### Pillar 1: Architectural Soundness & Separation of Concerns
- **Domain Boundaries**: Are modules isolated, or does business logic bleed into UI presentation or low-level transport layers?
- **State Topology**: Is state centralized and predictable, or distributed and prone to desynchronization?
- **Coupling Factor**: Can components be tested, swapped, or refactored independently without cascading breakage?

### Pillar 2: Code Quality, Robustness & Type Correctness
- **Contract Enforcement**: Are types strictly modeled without pervasive escape hatches (`any`, unchecked casts, excessive loose strings)?
- **Defensive Invariants**: Does the code validate external input, handle null/undefined guards, and fail fast with meaningful error context?
- **Readability & Cognitive Load**: Can an unfamiliar engineer understand the execution path without tracing circular dependencies?

### Pillar 3: User Experience (UX) & Developer Experience (DX)
- **Ergonomics**: Does the interface (GUI, CLI, or API) match user intuition and standard platform conventions?
- **Feedback Loops**: Are loading states, transitions, error messages, and success confirmations clear and instantaneous?
- **Zero Friction**: Does the implementation introduce unnecessary clicks, redundant keystrokes, or visual noise?

### Pillar 4: Edge Cases, Failure Modes & Security
- **Asynchronous Races**: Are rapid sequential interactions (e.g., debounce, cancellation, re-entrant calls) protected against out-of-order resolution?
- **Boundary Conditions**: How does the system behave on empty states, malformed payloads, huge payloads (10,000+ items), or disconnected network?
- **Security Boundaries**: Are inputs sanitized, secrets isolated, and injection/leakage pathways closed?

### Pillar 5: Performance, Resource Footprint & Efficiency
- **Algorithmic Complexity**: Are loops, lookups, and queries optimized for sub-millisecond execution?
- **Resource Leaks**: Are event listeners, file descriptors, background intervals, and IPC subscriptions cleaned up deterministically?
- **Rendering & DOM Churn**: Does the UI trigger layout thrashing, excessive repaints, or redundant re-renders?

---

## 3. Standard WDYT Evaluation Report Template

When executing `wdyt`, format the output using the following structured sections:

```text
================================================================================
WDYT EVALUATION REPORT: [Target System / Feature Name]
================================================================================

1. EXECUTIVE SUMMARY & FIRST IMPRESSIONS
- High-level perspective: What works well immediately, and what is the overarching impression?
- Core architectural philosophy assessment: Does the direction align with project goals?

2. MAJOR STRENGTHS (WHAT IS WORKING BRILLIANTLY)
- Strength 1: [Specific architectural or implementation highlight with code reference]
- Strength 2: [Specific user experience or robustness highlight]

3. CRITICAL DEFICIENCIES & ARCHITECTURAL WEAKNESSES
- Deficiency 1: [Root cause analysis, mechanism of failure, risk profile]
- Deficiency 2: [Root cause analysis, UX friction point, or maintenance trap]

4. HIDDEN ASSUMPTIONS & BLIND SPOTS
- [Unstated assumptions in the current design that may collapse under stress]
- [Edge cases that have not yet been accounted for]

5. CONCLUSION & STRATEGIC RECOMMENDATION
- Final verdict on feasibility, longevity, and readiness for production deployment.
================================================================================
```
