---
name: research-plan-implement
description: "Unified workflow for nontrivial coding tasks: research the problem space, create a persistent design doc, implement from the design, and compound learnings. Use before any nontrivial feature, refactor, or complex bug fix. Replaces brainstorming, writing-plans, and executing-plans as a single flow."
---

# Research, Plan, Implement

Four-phase workflow for nontrivial coding tasks. Each phase produces an artifact. Soft gates between phases — announce the transition and give the user a chance to pause, but don't block unless they want to.

**Announce at start:** "Using research-plan-implement for this task."

## Phase 1: Research

Understand the problem before designing a solution. Ask the user what kind of research is needed:

> "Before I design anything, what should I research? Options:
> 1. **Codebase** — explore relevant code, patterns, recent commits
> 2. **External docs** — read library/API/framework documentation
> 3. **Web** — search for best practices, prior art, known pitfalls
> 4. **All of the above**
> 5. **Skip** — I already know enough, go straight to design"

Then execute the research. Capture findings as you go — these feed the design doc.

**Research checklist:**
- Identify relevant files, modules, and patterns in the codebase
- Check recent commits for context on how this area has evolved
- Find existing conventions to follow
- Surface constraints, edge cases, or gotchas
- If web research: find best practices and alternatives

**Soft gate:** "Research complete. Here's what I found: [summary]. Ready to move to design, or want me to dig deeper?"

## Phase 2: Design

Create a persistent design document at `.context/design-<feature-name>.md`. This doc is the artifact — it should be good enough to hand to another developer (or agent) and have them understand what to build and why.

### Design Process

1. **Ask clarifying questions** — one at a time, prefer multiple choice
2. **Propose 2-3 approaches** — with trade-offs and your recommendation
3. **Present design incrementally** — section by section, confirm as you go
4. **Write the design doc** — save to `.context/design-<feature-name>.md`

### Design Doc Structure

```markdown
# [Feature Name] Design

**Date:** YYYY-MM-DD
**Status:** draft | approved | implementing | complete

## Problem
What problem are we solving and why.

## Research Findings
Key discoveries from the research phase. Sources consulted.

## Approach
The chosen approach and why. Brief mention of alternatives considered.

## Architecture
Components, data flow, interfaces. Scaled to complexity — a few sentences for simple changes, detailed diagrams for complex ones.

## File Changes
- Create: `path/to/new/file.py` — purpose
- Modify: `path/to/existing.py` — what changes and why
- Test: `tests/path/to/test.py` — what's being tested

## Implementation Tasks
Ordered list of bite-sized tasks (2-5 min each). Each task should produce a working, testable change.

### Task 1: [Name]
**Files:** list of files
**Steps:**
1. Step with code/commands
2. Verification step

### Task N: ...

## Success Criteria
How to know it's done and working.
```

### Design Quality

- **YAGNI** — remove unnecessary features
- **Isolation** — each unit has one purpose, clear interfaces
- **Follow existing patterns** — explore the codebase before proposing changes
- **Exact file paths** — always specify real paths
- **Complete code in tasks** — not "add validation here"
- **Include test strategy** — what tests, how to run them

**Soft gate:** "Design doc saved to `.context/design-<name>.md`. Take a look — want to revise anything before I start implementing?"

## Phase 3: Implement

Execute the design doc task by task.

1. Read the design doc
2. For each task:
   - Follow steps exactly as written
   - Run verifications as specified
   - Commit at natural boundaries
3. If blocked: stop and ask, don't guess

**Implementation principles:**
- Follow the design doc, not your own ideas
- TDD when the design specifies tests
- Small, focused commits
- Stop on blockers — surface them rather than working around them

**Soft gate:** "Implementation complete. All tasks done. Want me to run a final check?"

## Phase 4: Compound

After implementation, capture learnings so the next task benefits.

1. **Review what happened** — what went well, what was harder than expected, any surprises
2. **Update CLAUDE.md** — if you discovered conventions, patterns, or gotchas that would help future work in this codebase
3. **Update design doc status** — set status to `complete`
4. **Surface learnings** — tell the user what you'd do differently next time

> "Implementation complete. Here's what I learned that could help future work: [learnings]. I've updated CLAUDE.md with [specific additions]. Design doc marked complete."

## Skipping Phases

The user can skip or abbreviate any phase:
- "Skip research" → go straight to design
- "I already have a design" → go straight to implement (read the provided design first)
- "Skip compound" → finish after implementation

Never skip a phase without the user saying so.
