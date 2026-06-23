export const meta = {
  name: 'otta-build',
  description: 'TDD shipping pipeline for one issue: build → spec-review → adversarial verify → ship. Uses the builder/reviewer/qa/devops subagents.',
  phases: [
    { title: 'Build' },
    { title: 'Spec Review' },
    { title: 'Verify' },
    { title: 'Ship' },
  ],
}

// args: { issue, pluginRoot }. pluginRoot lets the stages call the real otta
// engine scripts (seed / gate / capture) deterministically instead of prose.
const issue = (args && (args.issue ?? args)) || 'the current issue'
const root = (args && args.pluginRoot) || '${CLAUDE_PLUGIN_ROOT}'
const SEED = `bash "${root}/scripts/seed-pr-body.sh"`
const GATE = `bash "${root}/scripts/otta-gate.sh"`

const REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    compliant: { type: 'boolean', description: 'true only if every AC is met and there is no extra scope' },
    gaps: { type: 'string', description: 'specific missing or extra behavior with file references; empty if compliant' },
  },
  required: ['compliant', 'gaps'],
}

const VERIFY_SCHEMA = {
  type: 'object',
  properties: {
    gatePassed: { type: 'boolean' },
    allAcsPass: { type: 'boolean', description: 'true only if every AC has real evidence' },
    detail: { type: 'string', description: 'gate result + per-AC verdicts with evidence or failure reason' },
  },
  required: ['gatePassed', 'allAcsPass', 'detail'],
}

// 1. BUILD — seed the body via the engine if needed, then implement test-first
phase('Build')
const built = await agent(
  `Implement issue #${issue} test-first.\n` +
    `FIRST: if .pr-body.md does not exist, seed it from the issue's acceptance criteria by running:\n` +
    `  ${SEED} ${issue}\n` +
    `Then read .pr-body.md — each "- [ ] AC" is what you must satisfy. ` +
    `Write the smallest failing test, make it pass, keep changes surgical, and keep .pr-body.md's Verification honest. ` +
    `Return what you changed, the test added, and which ACs it satisfies.`,
  { agentType: 'otta:builder', label: `build:#${issue}`, phase: 'Build' },
)

// 2. SPEC REVIEW — compliance, with one fix loop
phase('Spec Review')
let review = await agent(
  `Review the implementation for issue #${issue} against the acceptance block in .pr-body.md. ` +
    `For each AC cite the file:line that satisfies it. Flag missing or extra behavior.`,
  { agentType: 'otta:reviewer', label: 'spec-review', phase: 'Spec Review', schema: REVIEW_SCHEMA },
)
if (review && !review.compliant) {
  log(`spec review found gaps — sending back to builder`)
  await agent(
    `Spec review found gaps for issue #${issue}:\n${review.gaps}\nFix exactly these. Keep changes surgical.`,
    { agentType: 'otta:builder', label: 'build:fix-spec', phase: 'Build' },
  )
  review = await agent(
    `Re-review issue #${issue} against .pr-body.md after the fix. Confirm COMPLIANT or list remaining gaps.`,
    { agentType: 'otta:reviewer', label: 'spec-review:2', phase: 'Spec Review', schema: REVIEW_SCHEMA },
  )
}

// 3. VERIFY — run the real Otta gate (auto-captures the verdict to the ledger),
//    then adversarial per-AC check
phase('Verify')
const verify = await agent(
  `For issue #${issue}:\n` +
    `1. Run the Otta gate (it also runs the project gate + captures the verdict to the LEARN ledger):\n` +
    `   ${GATE}\n` +
    `2. Run the project's own tests (bash scripts/gate.sh if present, else typecheck + affected tests).\n` +
    `3. Adversarially verify EACH acceptance criterion in .pr-body.md — produce concrete evidence or mark it FAILED.\n` +
    `Return the gate result (gatePassed) and per-AC verdicts (allAcsPass + detail).`,
  { agentType: 'otta:qa', label: 'verify', phase: 'Verify', schema: VERIFY_SCHEMA },
)

// 4. SHIP — only when verify is fully green
phase('Ship')
if (verify && verify.gatePassed && verify.allAcsPass) {
  const shipped = await agent(
    `Issue #${issue} passed verify. Ship it:\n` +
      `1. Run the Otta gate once more — do not push past a failing gate:\n   ${GATE}\n` +
      `2. Commit, then open the PR with: gh pr create --body-file .pr-body.md --title "<conventional title>"\n` +
      `   Target staging if .selfloop.yml names a staging branch, else main.\n` +
      `Return the PR URL.`,
    { agentType: 'otta:devops', label: 'ship', phase: 'Ship' },
  )
  return { issue, status: 'shipped', spec: review, verify, ship: shipped }
}

log(`verify failed — not shipping #${issue}`)
return { issue, status: 'blocked', spec: review, verify }
