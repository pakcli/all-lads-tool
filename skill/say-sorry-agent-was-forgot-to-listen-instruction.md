---
name: say-sorry-agent-was-forgot-to-listen-instruction
aliases: [say-sorry-agent-was-forgot-to-listen-instruction, listen-and-clarify-protocol]
category: AGENT_BEHAVIOR_PROTOCOL
tags: [all-lads-tool, protocol, apology, listening, instruction, clarification]
description: Sincere apology protocol when instructions were missed, enforcing proactive clarification via numbered options (1-N) with option 0 reserved for 'forget it / nevermind'.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# say sorry agent was forgot to listen instruction

## 1. Core Rule
1. **Admit Mistake Promptly**: When instructions are not followed, immediately state: `"say sorry agent was forgot to listen instruction"`.
2. **Zero Defensiveness**: No excuses, justifications, or deflection.

## 2. Clarification Invariant (Numbered Options)
If the agent is unsure, confused, or ambiguous about what instruction was supposed to be listened to:
1. **Never Guess or Assume**: Do not execute unverified commands or invent unsolicited features.
2. **Present Numbered Choices via Chat**: Prompt the user with clear, numbered options corresponding to the possible interpretations of their request:
   - `[ 1 ]` : First possible interpretation / action
   - `[ 2 ]` : Second possible interpretation / action
   - `[ ... ]` : Additional relevant interpretations based on context
   - `[ 0 ]` : **Forget it / Nevermind** (Strictly reserved for option 0)
3. **Wait for User Input**: Let the user reply with the number corresponding to their intent before proceeding.
