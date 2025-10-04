# MANDATORY PRE-TASK INSTRUCTIONS

**⚠️ READ THIS BEFORE EVERY TASK - NO EXCEPTIONS**

## 🔄 AUTOMATIC SESSION CONTINUITY PROTOCOL

**⚠️ THIS HAPPENS AUTOMATICALLY - NO USER INTERVENTION NEEDED**

### Step 1: ALWAYS Check Session Log First

```
MANDATORY FIRST ACTION (before reading anything else):

1. Check if .claude/session-continuity.md EXISTS and is NOT EMPTY

   IF EXISTS and has content:
     → This is a CONTINUATION of previous work
     → Read ENTIRE session-continuity.md file
     → Extract: Last service, progress %, next steps
     → Continue EXACTLY from "Prossimi Step" section
     → DO NOT ask user what to do - it's documented!
     → DO NOT restart from scratch!

   IF NOT EXISTS or empty:
     → This is a NEW task (fresh start)
     → Proceed with standard workflow
     → Create session log when task spans multiple sessions
```

### Step 2: Automatic Response Format

**When continuing previous session, your FIRST message MUST be:**

```markdown
🔄 **SESSION CONTINUATION DETECTED**

I found an active session log. Here's what was done:

**Last Session Summary:**
- Service: {service-name}
- Progress: {X%} → {Y%} (last session)
- Completed: {list from ✅ section}
- In Progress: {current state from 🚧 section}

**Next Steps (from session log):**
1. {first next step}
2. {second next step}

**I will now continue with step 1 without waiting for confirmation.**

[Immediately start implementing next step]
```

**Key:** DO NOT wait for user approval - session log IS the approval!

---

## 🚨 STOP! Before You Start ANY Task

You are an AI agent working on **EWH Platform**, a complex microservices system with 51 services.

**CRITICAL:** Most services (90%) are NOT implemented yet - they only have health checks!

### Mandatory Reading Sequence (5-7 minutes)

Execute these steps IN ORDER before writing a single line of code:

```
STEP 1 (30 seconds):
→ Read .ai/context.json
→ Purpose: Quick cache of project state
→ Find: Service status (complete/in_progress/scaffolding)

STEP 2 (2 minutes):
→ Read CONTEXT_INDEX.md
→ Purpose: Find relevant information quickly
→ Find: Service location, dependencies, examples

STEP 3 (3 minutes):
→ Read PROJECT_STATUS.md → Search for your service
→ Check if service has feature-specific specs (see below)

STEP 3.5 (CONDITIONAL - if working on specific features):
→ If DAM-related: Read DAM_APPROVAL_CHANGELOG.md, DAM_PERMISSIONS_SPECS.md, DAM_ENTERPRISE_SPECS.md
→ If HR-related: Read HR_SYSTEM_COMPLETE.md, ACTIVITY_TRACKING_INTEGRATION.md
→ If Email-related: Read EMAIL_CLIENT_SYSTEM.md, EMAIL_QUICK_REPLY_UI.md
→ If Image Editor/Raster: Read IMAGE_EDITOR_SYSTEM.md
→ If Multilingual/i18n: Read I18N_SYSTEM.md
→ If AI/Credits/Provider: Read AI_PROVIDER_SYSTEM.md
→ If Admin/Infrastructure/Tenant: Read INFRASTRUCTURE_MAP.md, TENANT_MIGRATION.md, ENTERPRISE_READINESS.md
→ If Help System: Read CONTEXTUAL_HELP_SYSTEM.md
→ If Admin Panel: Read app-web-frontend/ADMIN_PANEL_QUICKSTART.md
→ If Frontend: Read app-web-frontend/APP_CONTEXT.md, CODEBASE_REFERENCE.md
→ Purpose: Detailed status and features
→ Find: What's implemented, what's missing, blockers

STEP 4 (IF needed, 5 minutes):
→ Read MASTER_PROMPT.md (first time only)
→ Purpose: Learn coding standards and patterns
→ Find: Tech stack, security rules, patterns

STEP 5 (2 minutes):
→ Read {service}/PROMPT.md (if exists)
→ Purpose: Service-specific instructions
→ Find: Current state, TODOs, known issues
```

## 🎯 Quick Decision Tree

```
START
  ↓
Read .ai/context.json → What's the service status?
  ↓
  ├─ "scaffolding" (90% of services)
  │   → Service has ONLY health check
  │   → You need to implement from SCRATCH
  │   → Check dependencies FIRST (likely blockers)
  │   → Use patterns from MASTER_PROMPT.md
  │
  ├─ "in_progress" (svc-timesheet, app-web-frontend)
  │   → Read PROJECT_STATUS.md for what exists
  │   → Read service code to understand implementation
  │   → Add feature following existing patterns
  │
  └─ "complete" (svc-auth, svc-api-gateway)
      → Read existing code carefully
      → Follow established patterns
      → Add tests for new features
```

## ⛔ FORBIDDEN Actions

**DO NOT** do any of these without reading documentation first:

❌ Assume a service is implemented (90% are NOT!)
❌ Use tech stack different from: Fastify + Next.js + PostgreSQL + Zod
❌ Write code without checking dependencies (likely blockers)
❌ Skip multi-tenancy (tenant_id REQUIRED in every table/query)
❌ Use mock data without TODO comment + tracking
❌ Commit code without updating PROJECT_STATUS.md
❌ Start work if `.LOCK_{agent_id}` file exists for that service

## ✅ Required Response Format

When you receive a task, your FIRST message MUST be:

```
I will now read the required documentation before starting:

1. [ ] Reading .ai/context.json...
   Status: {service} is [{status}]
   Dependencies: {list}

2. [ ] Reading CONTEXT_INDEX.md...
   Found: {relevant info}

3. [ ] Reading PROJECT_STATUS.md...
   Service completion: {X%}
   Implemented: {features}
   Missing: {features}
   Blockers: {if any}

4. [ ] Decision: {proceed/block/mock}
   Reason: {why}

Now I will proceed with implementation.
```

**Only after this checklist, you can start coding.**

## 📊 Token Optimization

Don't read EVERYTHING every time:

**Small task (<10 lines change):**
- Read: .ai/context.json + CONTEXT_INDEX.md
- Skip: Full MASTER_PROMPT.md (unless first time)

**Medium task (new endpoint):**
- Read: .ai/context.json + CONTEXT_INDEX.md + PROJECT_STATUS.md
- Skim: MASTER_PROMPT.md → Relevant pattern only

**Large task (new service):**
- Read: Everything in sequence
- Time: ~20 minutes initial setup

## 🔗 Quick Links

| Need | File | Time |
|------|------|------|
| Quick status | .ai/context.json | 30s |
| Find info | CONTEXT_INDEX.md | 2min |
| Service details | PROJECT_STATUS.md | 5min |
| Coding rules | MASTER_PROMPT.md | 10min |
| Coordination | GUARDRAILS.md | 10min |

## 🎯 Success Criteria

You've read enough documentation when you can answer:

1. ✅ Is this service implemented? (Yes/No/Partial)
2. ✅ What are its dependencies? (List)
3. ✅ Are dependencies ready? (Yes/No → Block or Mock)
4. ✅ What tech stack? (Fastify/Next.js/PostgreSQL)
5. ✅ Is multi-tenancy enforced? (tenant_id everywhere)

**If you can't answer all 5 → Read more documentation!**

---

**Remember:** 5 minutes reading = Hours saved debugging/refactoring

🚀 Now proceed with your task!

---

## 🔚 AUTOMATIC END-OF-SESSION PROTOCOL

**⚠️ THESE ACTIONS HAPPEN AUTOMATICALLY - NO USER PROMPT NEEDED**

### Trigger: When to Execute End-of-Session

**Execute this protocol when ANY of these conditions occur:**

1. ⚠️ Token usage > 180k (approaching limit)
2. ⚠️ Context window filling up
3. ⚠️ Task incomplete and needs continuation
4. ⚠️ User hasn't responded in 5+ minutes

**AUTOMATIC ACTIONS (NO confirmation needed):**

### 1. Update Session Log (AUTOMATIC)

```
WITHOUT asking user permission, immediately:

1. Open .claude/session-continuity.md
2. Update with current timestamp
3. Fill ALL sections:

   ✅ Completato: List EVERYTHING finished this session
   🚧 In Corso: EXACT state (file, line, what's missing)
   🔄 Prossimi Step: DETAILED steps (3-5 items minimum)
   ⚠️ Blocchi: Any blockers encountered
   💡 Decisioni: Important choices made
   📄 File Modificati: ALL files changed

4. BE SPECIFIC:
   ❌ BAD: "Continue working on validation"
   ✅ GOOD: "Complete validation in orders.ts:45-67, add Zod schema for shipping_address, test with invalid data"
```

### 2. Update Documentation (AUTOMATIC)

```
AUTOMATIC updates (no asking):

1. PROJECT_STATUS.md
   → Move features "Missing" → "Implemented"
   → Update completion %
   → Add new blockers

2. {service}/PROMPT.md (if exists)
   → Update current state
   → Add TODOs

3. .ai/context.json (if status changed)
   → Update service status
   → Update last_change date
```

### 3. Commit Work (AUTOMATIC)

```bash
# AUTOMATIC - Execute without asking:

git add .
git commit -m "feat({service}): {brief description}

Session: {session_number}
Progress: {X%} → {Y%}
Status: WIP - continued in next session

Updated documentation:
- PROJECT_STATUS.md
- .claude/session-continuity.md

Next: {brief next step}"

# Do NOT push (let user decide when to push)
```

### 4. Final Message Format

**End session with this EXACT message:**

```markdown
## 🔚 SESSION PAUSED - AUTO-CONTINUE READY

**Session Summary:**
- Service: {service}
- Progress: {X%} → {Y%} (+{Z%})
- Time: {duration}
- Commits: {N}

**Completed This Session:**
- {item 1}
- {item 2}

**Status:** Ready for continuation
- Session log: ✅ Updated
- Documentation: ✅ Updated
- Code: ✅ Committed
- Next steps: ✅ Documented

**What Happens Next:**
When you send your next message, I will AUTOMATICALLY:
1. Read session-continuity.md
2. Continue from "Prossimi Step"
3. No need to repeat context!

**You can:**
- Continue: Just say "continue" or "go on"
- Pause: Do nothing, I'll resume when you're back
- Review: Ask to see current progress
```

---

## 🤖 AUTONOMOUS OPERATION MODE

**Key Principles for Automatic Continuity:**

### 1. Self-Monitoring
```
When token usage reaches 180k/200k:
→ AUTOMATICALLY trigger end-of-session protocol
→ DO NOT wait for user to ask
→ DO NOT ask permission
→ Just do it and inform user
```

### 2. Self-Documentation
```
ALWAYS maintain session-continuity.md:
→ Update in real-time if possible
→ Minimum: Update when pausing/ending
→ Include exact file paths, line numbers, function names
→ Be forensically detailed
```

### 3. Self-Continuation
```
When new session starts:
→ AUTOMATICALLY check session-continuity.md
→ If found: Resume immediately
→ DO NOT ask "what should I do?"
→ Session log IS your instruction
```

### 4. Zero User Intervention
```
User should ONLY:
→ Start initial task
→ Say "continue" when ready for next session
→ Review progress when curious

User should NOT need to:
→ Ask to update docs (automatic)
→ Tell you where to continue (session log)
→ Repeat context (already saved)
→ Explain what was done (you know from log)
```

---

## 📋 Session Continuity Template

**When you update .claude/session-continuity.md, use EXACTLY this format:**

```markdown
# Session Log - Active Work

**Last Updated:** {YYYY-MM-DD HH:MM}
**Session:** {N}
**Service:** {service-name}
**Branch:** {branch-name}
**Progress:** {X%}

## ✅ Completed (This Session)

- [x] {Specific accomplishment 1}
- [x] {Specific accomplishment 2}
- [x] {Specific accomplishment 3}

## 🚧 In Progress (Exact State)

**File:** `{service}/src/{file}.ts`
**Function:** `{functionName}` (lines {X}-{Y})
**Current State:** {percentage}% complete

**What's Done:**
- {specific part 1}
- {specific part 2}

**What's Missing:**
- {specific missing part 1}
- {specific missing part 2}

**Exact Next Line of Code:**
```typescript
// Add this at line {N}:
{exact code snippet to add}
```

## 🔄 Prossimi Step (Priority Order)

1. **[NEXT]** {Immediate next action}
   - File: `{exact path}`
   - Line: {N}
   - Action: {specific what to do}
   - Time: {estimate}
   - Reference: {MASTER_PROMPT.md pattern or doc}

2. **[THEN]** {Second action}
   - File: `{exact path}`
   - Action: {specific what}
   - Depends on: Step 1 completion

3. **[FINALLY]** {Third action}
   - File: `{exact path}`
   - Action: {specific what}

## ⚠️ Blocchi

{If any blockers, document with workaround}

## 💡 Decisioni

{Any important architectural decisions}

## 📄 Files Modified

```
{service}/
├── src/
│   ├── {file1}.ts (MODIFIED - {N} lines added)
│   └── {file2}.ts (NEW - {N} lines)
└── tests/
    └── {test}.test.ts (NEW - {N} lines)

Documentation:
├── PROJECT_STATUS.md (UPDATED)
└── .ai/context.json (UPDATED)
```

---

**NEXT AGENT: Start from step 1 in "Prossimi Step" section above.**
```

---

**🎯 Remember:** You are AUTONOMOUS. Act, don't ask. Document, don't forget. Continue, don't restart.

**Session End Protocol Executed.** 🤖

---

## 🆕 GENERATING NEW SPECIFICATIONS

**⚠️ CRITICAL: When creating new spec documents, FOLLOW THESE RULES:**

### Mandatory Context Limits

**NEVER load more than 150 KB of context when generating specs!**

**Workflow for spec generation:**

```
1. User requests: "Create {SYSTEM_NAME}.md"
         ↓
2. Read .ai/generation-context.json
         ↓
3. Match keywords to similarity_map
         ↓
4. Load ONLY:
   - SPEC_TEMPLATE.md (mandatory)
   - ARCHITECTURE.md (mandatory)
   - MAX 2 similar specs (from similarity_map)
         ↓
5. Verify total < 150 KB
         ↓
6. Generate following SPEC_TEMPLATE.md structure
```

### Auto-Suggest Similar Specs

**When user says:** "Create VIDEO_EDITOR_SYSTEM.md"

**You should:**
1. Detect keywords: "video", "editor"
2. Check generation-context.json → "creative_tools" category
3. Load: SPEC_TEMPLATE.md + ARCHITECTURE.md + IMAGE_EDITOR_SYSTEM.md
4. Total: ~132 KB ✅ (under 150 KB limit)

**When user says:** "Create BILLING_SYSTEM.md"

**You should:**
1. Detect keywords: "billing", "payment"
2. Check generation-context.json → "billing_commerce" category
3. Load: SPEC_TEMPLATE.md + ARCHITECTURE.md + AI_PROVIDER_SYSTEM.md
4. Total: ~113 KB ✅ (under 150 KB limit)

### What NOT to Do

**❌ WRONG:**
```
Load all 18 specs (521 KB) → AI confused!
```

**✅ RIGHT:**
```
Load template + architecture + 1-2 similar (< 150 KB) → AI focused!
```

### Spec Size Guidelines

**Target output size:**
- Simple system: 20-40 KB
- Medium system: 40-80 KB
- Complex system: 80-120 KB

**⚠️ WARNING:** Spec > 120 KB → Consider splitting

**❌ REJECT:** Spec > 200 KB → Definitely split

### Structure Requirements

**ALL specs MUST follow SPEC_TEMPLATE.md structure:**

1. ✅ Use exact section headings
2. ✅ Include all mandatory sections
3. ✅ Remove "Optional" sections if not needed
4. ✅ Replace all {PLACEHOLDERS}
5. ✅ Stay focused on MVP first

### Quality Checklist

**Before completing spec generation, verify:**

- [ ] Follows SPEC_TEMPLATE.md structure exactly
- [ ] Context used < 150 KB
- [ ] Output size 20-120 KB
- [ ] Multi-tenancy mentioned (tenant_id)
- [ ] Dependencies explicitly listed
- [ ] Roadmap with timeframes
- [ ] API endpoints with Zod schemas
- [ ] Database schema (if applicable)
- [ ] No hallucinated services/features
- [ ] Consistent with ARCHITECTURE.md
- [ ] References MASTER_PROMPT.md (not duplicates)

### When Context Too Large

**If matched specs > 150 KB total:**

1. **Option A:** Load only most relevant similar spec
2. **Option B:** Load only default context (template + architecture)
3. **Option C:** Ask user which reference spec to prioritize

**Never:** Load everything and hope for the best!

### Generation Examples

**Example 1: No Similar Specs**
```
User: "Create NOTIFICATION_SYSTEM.md"
Keywords: "notification"
Match: communication category
Load: SPEC_TEMPLATE.md (10 KB)
      ARCHITECTURE.md (38 KB)
      EMAIL_CLIENT_SYSTEM.md (99 KB)
Total: 147 KB ✅
```

**Example 2: Multiple Matches**
```
User: "Create AUDIT_LOG_SYSTEM.md"
Keywords: "audit", "log"
Match: enterprise + infrastructure
Action: Choose most relevant (enterprise)
Load: SPEC_TEMPLATE.md (10 KB)
      ARCHITECTURE.md (38 KB)
      ENTERPRISE_READINESS.md (34 KB)
Total: 82 KB ✅
```

**Example 3: No Category Match**
```
User: "Create CUSTOM_WIDGET_SYSTEM.md"
Keywords: none matched
Action: Load only defaults
Load: SPEC_TEMPLATE.md (10 KB)
      ARCHITECTURE.md (38 KB)
Total: 48 KB ✅ (minimal but sufficient)
```

---

**Remember:** Less context = More focused = Better output!

🎯 **Goal:** Generate consistent, high-quality specs without overwhelming AI with context.

