# Elastic Fork Implementation Spec (Agent-Executable)

## Purpose
Build an Elastic dashboard fork that preserves Elastic’s current look-and-feel and interaction style while adding two production-ready custom widgets:
1. **Interactive Pass Target Field Widget**
2. **Rebuilt Period Clock Widget**

This spec is written so an AI coding agent can execute the fork in one prompt under ideal conditions.

---

## Non-Negotiable Constraints
- Keep visual style consistent with upstream Elastic (same theme system, spacing, typography, widget chrome, interaction patterns).
- Add features **additively**; do not redesign existing widgets.
- Maintain compatibility with existing Elastic layout schema and topic subscription model.
- Keep existing stock widgets functioning unchanged.
- Use field-native internal units in meters where required by WPILib topics.
- Operator-facing pass target input/display should be inches (with deterministic inch↔meter conversion).

---

## Scope (v1)
### In Scope
- Custom widget framework scaffolding in the fork (for future widgets).
- Custom widget: interactive field targeting with keybind placement.
- Custom widget: Rebuilt period clock with ownership colorization.
- Local persistence for widget settings/state.
- Runtime topic publishing/subscribing needed by both widgets.
- Clear fallback behavior when required topics are missing.

### Out of Scope (v1)
- Replacing stock Match Time widget globally.
- Modifying robot code source files directly from dashboard.
- Auto score-feed integration from FMS/APIs.

---

## Widget 1: Interactive Pass Target Field

### Functional Requirements
- Render standard field map with robot pose compatibility equivalent to stock Field widget behavior.
- Display **Target A** and **Target B** markers simultaneously.
- Placement interaction:
  - Press key `1` to place/update **Target A** at current hover/cursor field location.
  - Press key `2` to place/update **Target B** at current hover/cursor field location.
- No snapping (free placement).
- Clamp placement to legal field bounds.
- Provide optional marker labels (`A`, `B`) if enabled in widget properties.

### Alliance-Oriented View
- Support alliance-oriented viewing so own alliance appears on left side.
- When alliance changes, widget view rotates/mirrors accordingly while preserving world-coordinate correctness.
- Coordinate conversion must be deterministic and reversible.

### Topic Contract
Use these canonical topics (meters-native runtime):
- `ShooterCalculator/Pass/TargetA/XMeters` (double)
- `ShooterCalculator/Pass/TargetA/YMeters` (double)
- `ShooterCalculator/Pass/TargetA/ZMeters` (double, leave unchanged unless UI explicitly edits)
- `ShooterCalculator/Pass/TargetB/XMeters` (double)
- `ShooterCalculator/Pass/TargetB/YMeters` (double)
- `ShooterCalculator/Pass/TargetB/ZMeters` (double)
- `ShooterCalculator/Pass/TargetB/Enabled` (boolean)

Operator-facing inch mirrors (editable/display):
- `ShooterCalculator/Tuning/PassTargets/TargetA/XInches` (double)
- `ShooterCalculator/Tuning/PassTargets/TargetA/YInches` (double)
- `ShooterCalculator/Tuning/PassTargets/TargetB/XInches` (double)
- `ShooterCalculator/Tuning/PassTargets/TargetB/YInches` (double)

### Conversion Rules
- `meters = inches * 0.0254`
- `inches = meters / 0.0254`
- Round display values only in UI; publish full precision doubles.
- Prevent conversion loops by debouncing and source-of-truth tagging.

### Persistence
- Persist widget-local preferences in Elastic local settings:
  - keybinds (default `1`/`2`)
  - label visibility
  - alliance-oriented view enabled
- Do not attempt to edit robot source constants files.
- Optional future extension: publish save-request topic for robot-side config persistence.

### Failure/Degraded Modes
- If topic unavailable, show marker as unavailable state with unobtrusive warning.
- If field metadata unavailable, disable placement and show non-blocking status text.

---

## Widget 2: Rebuilt Period Clock

### Functional Requirements
Display always:
- Current period name
- Time remaining in current period
- Color-coded ownership state (color only; no text ownership required)

### Period Timeline (Fixed)
Use these match clock intervals exactly:
- **Auto:** `2:40` → `2:20`
- **Transition:** `2:20` → `2:10`
- **Alliance Shift 1:** `2:10` → `1:45`
- **Alliance Shift 2:** `1:45` → `1:20`
- **Alliance Shift 3:** `1:20` → `0:55`
- **Alliance Shift 4:** `0:55` → `0:30`
- **Endgame:** `0:30` → `0:00`

### Timing Source Rule
- Reuse the same upstream timing source behavior as existing Match Time widget.
- Widget computes only derived presentation state not already published (period classification and remaining-in-period display).
- Reset semantics should match stock match clock behavior.

### Auto Winner + Shift Ownership
Control model:
- Single toggle: **Auto winner is Red when ON, Blue when OFF**.

Ownership progression across shift periods:
- Ownership alternates every shift, **starting with auto loser**.
  - Example: if auto winner is Red, shift owner sequence is Blue, Red, Blue, Red.

### Color Rules
- Red owner => red clock styling.
- Blue owner => blue clock styling.
- Color communicates owner; no additional owner text required unless optional setting enabled.

### Failure/Degraded Modes
- If timing source unavailable, show paused/unknown state with neutral styling.
- If auto-winner toggle missing/unset, apply configurable default and show small warning icon.

---

## Shared Custom Widget Framework Requirements
- Register custom widgets in the same discovery/registry style used by Elastic.
- Property panels must follow existing Elastic property editor UX conventions.
- Support layout import/export without breaking unknown widget fallback.
- Version custom widget schema to allow forward-compatible migrations.

---

## UX Consistency Requirements (Match Elastic Style)
- Use existing theme tokens/colors/typography primitives from Elastic.
- Match panel header, borders, padding, and hover/focus behaviors.
- Follow Elastic keyboard focus and accessibility patterns.
- Keep control density and visual hierarchy aligned with stock widgets.

---

## Implementation Tasks (Agent Checklist)
1. Fork upstream Elastic and create feature branch.
2. Add custom widget base scaffolding (types, registration, serialization).
3. Implement interactive field widget rendering + coordinate transforms + keybind input.
4. Implement NT subscribe/publish for pass target topics and inch/meter mirror paths.
5. Implement local persistence for widget settings.
6. Implement period clock widget with fixed timeline logic.
7. Implement auto-winner toggle + owner-color derivation.
8. Add degraded-state UI handling for missing topics.
9. Add property editor options for both widgets.
10. Add layout schema migration for custom widget config versions.
11. Add tests (unit + integration smoke).
12. Build and package desktop artifact.

---

## Acceptance Criteria

### Interactive Pass Target Field
- [ ] Pressing `1` updates Target A position at current cursor/hover location.
- [ ] Pressing `2` updates Target B position at current cursor/hover location.
- [ ] Targets are clamped to legal field bounds.
- [ ] A and B markers are visible concurrently.
- [ ] Alliance-oriented view places own alliance on left without coordinate corruption.
- [ ] Meter and inch topics remain synchronized without oscillation.

### Rebuilt Period Clock
- [ ] Correct period label for every timeline segment.
- [ ] Correct time remaining within each period.
- [ ] Shift ownership alternates per rules, starting with auto loser.
- [ ] Clock color reflects owner only (red/blue mapping exact).
- [ ] Start/reset behavior matches stock match-time source behavior.

### Platform/Quality
- [ ] Existing Elastic widgets and layouts continue to work.
- [ ] Custom widgets serialize/deserialize across app restarts.
- [ ] No style regressions versus stock Elastic components.
- [ ] Build passes and application runs with new widgets enabled.

---

## Technical Notes for Agent
- Do not attempt source-file rewrites in robot repo (e.g., editing `Constants.java`) from dashboard directly.
- For persistent robot-side tunables, define a future extension protocol:
  - dashboard publishes save request topic
  - robot code handles file write/load
- Keep all state transitions deterministic and testable.
- Prefer minimal invasive changes to upstream architecture.

---

## Suggested Test Matrix
- Keybind placement: normal, rapid repeat, focus loss, remapped keys.
- Coordinate mapping: both alliances, rotated view on/off, field-edge clicks.
- Topic resilience: delayed NT connect, partial topic availability, reconnect.
- Clock transitions: boundary timestamps at each period edge.
- Ownership logic: both toggle states and full shift progression.
- Persistence: restart app and verify widget settings/state restoration.

---

## Deliverables
- Forked Elastic codebase with both custom widgets implemented.
- Updated docs for widget usage and properties.
- Example layout JSON including both widgets.
- Build artifacts for operator deployment.
