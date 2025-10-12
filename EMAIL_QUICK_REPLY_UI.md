# Email Quick Reply & Routing - UI Components

> **UI per AI Quick Reply, Template Management, e Smart Routing**

---

## 1. Quick Reply Panel in Email Viewer

```tsx
// app-web-frontend/components/email/QuickReplyPanel.tsx

export function QuickReplyPanel({ email }: { email: Email }) {
  const [suggestions, setSuggestions] = useState<ReplySuggestion[]>([])
  const [loading, setLoading] = useState(false)
  const [selectedSuggestion, setSelectedSuggestion] = useState<ReplySuggestion | null>(null)
  const [draftReply, setDraftReply] = useState<EmailDraft | null>(null)

  // Load suggestions when panel opens
  useEffect(() => {
    loadSuggestions()
  }, [email.id])

  const loadSuggestions = async () => {
    setLoading(true)
    const response = await fetch(`/api/v1/email/${email.id}/reply-suggestions`)
    const data = await response.json()
    setSuggestions(data.suggestions)
    setLoading(false)
  }

  const handleSelectSuggestion = async (suggestion: ReplySuggestion) => {
    setSelectedSuggestion(suggestion)
    setLoading(true)

    // Generate reply draft
    const response = await fetch(`/api/v1/email/${email.id}/generate-reply`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ suggestion_id: suggestion.id }),
    })

    const data = await response.json()
    setDraftReply(data.draft)
    setLoading(false)
  }

  return (
    <div className="border-t bg-gray-50 p-4">
      {!draftReply ? (
        // Step 1: Show suggestions
        <div>
          <h3 className="text-sm font-semibold mb-3">💡 Quick Reply Suggestions</h3>

          {loading ? (
            <div className="flex items-center gap-2 text-gray-500">
              <Spinner size="sm" />
              <span className="text-sm">Generating suggestions...</span>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-2">
              {suggestions.map((suggestion) => (
                <button
                  key={suggestion.id}
                  onClick={() => handleSelectSuggestion(suggestion)}
                  className="p-3 border rounded-lg hover:bg-white hover:shadow-sm transition text-left"
                >
                  <div className="flex items-start justify-between mb-1">
                    <span className="text-sm font-semibold">{suggestion.label}</span>
                    {suggestion.type === 'template' ? (
                      <span className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded">
                        Template
                      </span>
                    ) : (
                      <span className="text-xs bg-purple-100 text-purple-700 px-2 py-0.5 rounded">
                        AI
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-gray-600">{suggestion.description}</p>
                  <div className="mt-2">
                    <div className="flex items-center gap-1">
                      <div className="flex-1 bg-gray-200 rounded-full h-1">
                        <div
                          className="bg-green-500 h-1 rounded-full"
                          style={{ width: `${suggestion.confidence * 100}%` }}
                        />
                      </div>
                      <span className="text-xs text-gray-500">
                        {Math.round(suggestion.confidence * 100)}%
                      </span>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}

          {suggestions.length === 0 && !loading && (
            <div className="text-center py-8 text-gray-500">
              <p className="text-sm">No suggestions available.</p>
              <button
                onClick={loadSuggestions}
                className="mt-2 text-blue-600 text-sm hover:underline"
              >
                Refresh suggestions
              </button>
            </div>
          )}
        </div>
      ) : (
        // Step 2: Show draft for approval
        <div>
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <h3 className="text-sm font-semibold">📧 Draft Reply</h3>
              {selectedSuggestion && (
                <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded">
                  {selectedSuggestion.label}
                </span>
              )}
            </div>
            <button
              onClick={() => setDraftReply(null)}
              className="text-xs text-gray-600 hover:text-gray-900"
            >
              ← Back to suggestions
            </button>
          </div>

          {/* Draft Preview */}
          <div className="bg-white border rounded-lg p-4 mb-4">
            <div className="mb-3 pb-3 border-b">
              <div className="text-xs text-gray-500 mb-1">To:</div>
              <div className="text-sm font-semibold">{draftReply.to}</div>
            </div>

            <div className="mb-3 pb-3 border-b">
              <div className="text-xs text-gray-500 mb-1">Subject:</div>
              <div className="text-sm font-semibold">{draftReply.subject}</div>
            </div>

            <div>
              <div className="text-xs text-gray-500 mb-2">Body:</div>
              <div className="prose prose-sm max-w-none">
                <pre className="whitespace-pre-wrap font-sans text-sm">{draftReply.body_text}</pre>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-2">
            <button
              onClick={() => sendReply(draftReply)}
              className="flex-1 bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600 flex items-center justify-center gap-2"
            >
              <span>✓</span>
              <span>Send Reply</span>
            </button>
            <button
              onClick={() => openReplyEditor(draftReply)}
              className="px-4 py-2 border rounded-lg hover:bg-gray-50 flex items-center gap-2"
            >
              <span>✏️</span>
              <span>Edit</span>
            </button>
          </div>

          {/* Calendar Event (if applicable) */}
          {selectedSuggestion?.creates_appointment && (
            <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-center gap-2 mb-2">
                <span>📅</span>
                <span className="text-sm font-semibold">Create Calendar Event</span>
              </div>
              <p className="text-xs text-gray-600 mb-3">
                This reply will create a calendar event with the proposed meeting time.
              </p>
              <button className="text-xs text-blue-600 hover:underline">
                Configure event details →
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
```

---

## 2. Reply Template Management

```tsx
// app-web-frontend/pages/email/settings/reply-templates.tsx

export default function ReplyTemplatesPage() {
  const [templates, setTemplates] = useState<EmailReplyTemplate[]>([])
  const [showCreateModal, setShowCreateModal] = useState(false)

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">Reply Templates</h1>
          <p className="text-gray-600">
            Create quick reply templates for common responses
          </p>
        </div>

        <button
          onClick={() => setShowCreateModal(true)}
          className="bg-blue-500 text-white px-4 py-2 rounded-lg"
        >
          + New Template
        </button>
      </div>

      {/* Template Categories */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <CategoryCard
          icon="✓"
          label="Accept"
          count={templates.filter((t) => t.category === 'accept').length}
        />
        <CategoryCard
          icon="✗"
          label="Reject"
          count={templates.filter((t) => t.category === 'reject').length}
        />
        <CategoryCard
          icon="📅"
          label="Appointment"
          count={templates.filter((t) => t.category === 'appointment').length}
        />
        <CategoryCard
          icon="📝"
          label="Custom"
          count={templates.filter((t) => t.category === 'custom').length}
        />
      </div>

      {/* Templates List */}
      <div className="space-y-4">
        {templates.map((template) => (
          <TemplateCard
            key={template.id}
            template={template}
            onEdit={() => editTemplate(template)}
            onDelete={() => deleteTemplate(template.id)}
            onDuplicate={() => duplicateTemplate(template)}
          />
        ))}
      </div>

      {/* Create Template Modal */}
      {showCreateModal && (
        <CreateTemplateModal
          onClose={() => setShowCreateModal(false)}
          onSuccess={(template) => {
            setTemplates([...templates, template])
            setShowCreateModal(false)
          }}
        />
      )}
    </div>
  )
}

function TemplateCard({ template, onEdit, onDelete, onDuplicate }) {
  return (
    <div className="border rounded-lg p-4 hover:shadow-sm transition">
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="font-semibold">{template.name}</h3>
            <span className="text-xs bg-gray-200 px-2 py-0.5 rounded capitalize">
              {template.category}
            </span>
          </div>
          <p className="text-sm text-gray-600">{template.description}</p>
        </div>

        <div className="flex gap-1">
          <button
            onClick={onEdit}
            className="p-2 hover:bg-gray-100 rounded text-sm"
            title="Edit"
          >
            ✏️
          </button>
          <button
            onClick={onDuplicate}
            className="p-2 hover:bg-gray-100 rounded text-sm"
            title="Duplicate"
          >
            📋
          </button>
          <button
            onClick={onDelete}
            className="p-2 hover:bg-gray-100 rounded text-sm text-red-600"
            title="Delete"
          >
            🗑️
          </button>
        </div>
      </div>

      {/* Template Preview */}
      <div className="bg-gray-50 rounded p-3 text-sm">
        <div className="mb-2">
          <span className="text-xs text-gray-500">Subject:</span>
          <p className="font-mono text-xs mt-1">{template.subject_template}</p>
        </div>
        <div>
          <span className="text-xs text-gray-500">Body:</span>
          <p className="font-mono text-xs mt-1 line-clamp-3">{template.body_template}</p>
        </div>
      </div>

      {/* Auto-suggest Rules */}
      {template.auto_suggest_rules && (
        <div className="mt-3 pt-3 border-t">
          <div className="text-xs text-gray-500 mb-2">Auto-suggest when:</div>
          <div className="flex flex-wrap gap-1">
            {template.auto_suggest_rules.from_contains?.map((rule: string) => (
              <span key={rule} className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded">
                From: {rule}
              </span>
            ))}
            {template.auto_suggest_rules.subject_contains?.map((rule: string) => (
              <span key={rule} className="text-xs bg-purple-100 text-purple-700 px-2 py-0.5 rounded">
                Subject: {rule}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="mt-3 pt-3 border-t flex items-center gap-4 text-xs text-gray-500">
        <span>Used {template.usage_count} times</span>
        {template.creates_calendar_event && <span>📅 Creates event</span>}
      </div>
    </div>
  )
}
```

---

## 3. Email Routing Rules Management

```tsx
// app-web-frontend/pages/email/settings/routing-rules.tsx

export default function EmailRoutingRulesPage() {
  const [rules, setRules] = useState<EmailReplyRule[]>([])
  const [showCreateModal, setShowCreateModal] = useState(false)

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">Email Routing Rules</h1>
          <p className="text-gray-600">
            Automatically route emails from generic inboxes (info@, support@) to specific users or teams
          </p>
        </div>

        <button
          onClick={() => setShowCreateModal(true)}
          className="bg-blue-500 text-white px-4 py-2 rounded-lg"
        >
          + New Rule
        </button>
      </div>

      {/* Example Rules */}
      <div className="mb-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
        <h3 className="font-semibold mb-2">💡 Example Rules</h3>
        <ul className="text-sm text-gray-700 space-y-1">
          <li>• Email about "pagamento" or "fattura" → Forward to accounting@company.com</li>
          <li>• Email from existing CRM client → Assign to their technician</li>
          <li>• Email from "tizio@example.com" → Auto-reply with "Mandalo a quel paese" template</li>
          <li>• Email about "appuntamento" → Suggest calendar appointment</li>
        </ul>
      </div>

      {/* Rules List */}
      <div className="space-y-4">
        {rules.map((rule) => (
          <RuleCard
            key={rule.id}
            rule={rule}
            onEdit={() => editRule(rule)}
            onToggle={() => toggleRule(rule.id)}
            onDelete={() => deleteRule(rule.id)}
          />
        ))}
      </div>

      {rules.length === 0 && (
        <div className="text-center py-12 border-2 border-dashed rounded-lg">
          <p className="text-gray-500 mb-4">No routing rules configured</p>
          <button
            onClick={() => setShowCreateModal(true)}
            className="text-blue-600 hover:underline"
          >
            Create your first rule
          </button>
        </div>
      )}

      {/* Create Rule Modal */}
      {showCreateModal && (
        <CreateRuleModal
          onClose={() => setShowCreateModal(false)}
          onSuccess={(rule) => {
            setRules([...rules, rule])
            setShowCreateModal(false)
          }}
        />
      )}
    </div>
  )
}

function RuleCard({ rule, onEdit, onToggle, onDelete }) {
  return (
    <div className="border rounded-lg p-4">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3 flex-1">
          <Toggle checked={rule.enabled} onChange={onToggle} />
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-semibold">{rule.name}</h3>
              <span className="text-xs bg-gray-200 px-2 py-0.5 rounded">
                Priority: {rule.priority}
              </span>
            </div>
            <p className="text-sm text-gray-600">{rule.description}</p>
          </div>
        </div>

        <div className="flex gap-1">
          <button onClick={onEdit} className="p-2 hover:bg-gray-100 rounded">
            ✏️
          </button>
          <button onClick={onDelete} className="p-2 hover:bg-gray-100 rounded text-red-600">
            🗑️
          </button>
        </div>
      </div>

      {/* Rule Flow */}
      <div className="grid grid-cols-3 gap-4">
        {/* Conditions */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <h4 className="text-xs font-semibold text-blue-900 mb-2">IF (Conditions)</h4>
          <div className="space-y-1">
            {rule.conditions.from_email?.equals && (
              <div className="text-xs">
                From: <code className="bg-white px-1">{rule.conditions.from_email.equals}</code>
              </div>
            )}
            {rule.conditions.subject?.contains?.map((keyword: string) => (
              <div key={keyword} className="text-xs">
                Subject contains: <code className="bg-white px-1">{keyword}</code>
              </div>
            ))}
            {rule.conditions.body?.contains?.map((keyword: string) => (
              <div key={keyword} className="text-xs">
                Body contains: <code className="bg-white px-1">{keyword}</code>
              </div>
            ))}
            {rule.conditions.crm_contact_exists && (
              <div className="text-xs">CRM contact exists</div>
            )}
          </div>
        </div>

        {/* Arrow */}
        <div className="flex items-center justify-center">
          <span className="text-2xl text-gray-400">→</span>
        </div>

        {/* Actions */}
        <div className="bg-green-50 border border-green-200 rounded-lg p-3">
          <h4 className="text-xs font-semibold text-green-900 mb-2">THEN (Actions)</h4>
          <div className="space-y-1">
            {rule.actions.assign_to_user && (
              <div className="text-xs">
                Assign to: <strong>{getUserName(rule.actions.assign_to_user)}</strong>
              </div>
            )}
            {rule.actions.forward_to && (
              <div className="text-xs">
                Forward to: <code className="bg-white px-1">{rule.actions.forward_to}</code>
              </div>
            )}
            {rule.actions.auto_reply && (
              <div className="text-xs">
                Auto-reply with template: <strong>{getTemplateName(rule.actions.auto_reply.template_id)}</strong>
              </div>
            )}
            {rule.actions.add_label?.map((label: string) => (
              <div key={label} className="text-xs">
                Add label: <span className="bg-yellow-100 px-1">{label}</span>
              </div>
            ))}
            {rule.actions.create_task && (
              <div className="text-xs">Create task: {rule.actions.create_task.title}</div>
            )}
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="mt-3 pt-3 border-t flex items-center gap-4 text-xs text-gray-500">
        <span>Executed {rule.execution_count} times</span>
        {rule.last_executed_at && (
          <span>Last run: {formatDate(rule.last_executed_at)}</span>
        )}
      </div>
    </div>
  )
}
```

---

## 4. Calendar Integration UI

```tsx
// app-web-frontend/components/email/CalendarEventSuggestion.tsx

export function CalendarEventSuggestion({ email, contact }: { email: Email; contact?: CRMContact }) {
  const [showCreateEvent, setShowCreateEvent] = useState(false)
  const [eventDetails, setEventDetails] = useState({
    title: `Meeting with ${email.from_name || contact?.name}`,
    description: `Regarding: ${email.subject}`,
    location: '',
    start_time: '',
    duration: 60, // minutes
    attendees: [email.from_email],
  })

  const handleCreateEvent = async () => {
    const response = await fetch('/api/v1/calendar/events', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...eventDetails,
        email_id: email.id,
        crm_contact_id: contact?.id,
      }),
    })

    if (response.ok) {
      toast.success('Calendar event created')
      setShowCreateEvent(false)
    }
  }

  return (
    <div className="border-t bg-blue-50 p-4">
      {!showCreateEvent ? (
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span>📅</span>
            <div>
              <p className="text-sm font-semibold">Schedule a meeting</p>
              <p className="text-xs text-gray-600">
                Create a calendar event from this email
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowCreateEvent(true)}
            className="bg-blue-500 text-white px-4 py-2 rounded-lg text-sm"
          >
            Create Event
          </button>
        </div>
      ) : (
        <div>
          <h3 className="text-sm font-semibold mb-3">📅 Create Calendar Event</h3>

          {/* Event Form */}
          <div className="space-y-3">
            <div>
              <label className="block text-xs font-semibold mb-1">Title</label>
              <input
                type="text"
                value={eventDetails.title}
                onChange={(e) => setEventDetails({ ...eventDetails, title: e.target.value })}
                className="w-full border rounded px-3 py-2 text-sm"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold mb-1">Date & Time</label>
                <input
                  type="datetime-local"
                  value={eventDetails.start_time}
                  onChange={(e) => setEventDetails({ ...eventDetails, start_time: e.target.value })}
                  className="w-full border rounded px-3 py-2 text-sm"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1">Duration</label>
                <select
                  value={eventDetails.duration}
                  onChange={(e) => setEventDetails({ ...eventDetails, duration: parseInt(e.target.value) })}
                  className="w-full border rounded px-3 py-2 text-sm"
                >
                  <option value="30">30 minutes</option>
                  <option value="60">1 hour</option>
                  <option value="90">1.5 hours</option>
                  <option value="120">2 hours</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold mb-1">Location</label>
              <input
                type="text"
                value={eventDetails.location}
                onChange={(e) => setEventDetails({ ...eventDetails, location: e.target.value })}
                placeholder="Office, Zoom, etc."
                className="w-full border rounded px-3 py-2 text-sm"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold mb-1">Attendees</label>
              <div className="flex flex-wrap gap-2">
                {eventDetails.attendees.map((email) => (
                  <span key={email} className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded">
                    {email}
                  </span>
                ))}
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="flex gap-2 mt-4">
            <button
              onClick={handleCreateEvent}
              className="flex-1 bg-blue-500 text-white px-4 py-2 rounded-lg text-sm"
            >
              Create & Send Invite
            </button>
            <button
              onClick={() => setShowCreateEvent(false)}
              className="px-4 py-2 border rounded-lg text-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
```

---

## Summary

### New UI Components

1. ✅ **QuickReplyPanel** - AI suggestions + draft approval
2. ✅ **ReplyTemplatesPage** - Template management
3. ✅ **EmailRoutingRulesPage** - Routing rules IF/THEN builder
4. ✅ **CalendarEventSuggestion** - Create events from emails

### Key Features

- **AI-powered suggestions** (5 options per email)
- **Template variables** ({{sender_name}}, {{date}}, etc.)
- **Conditional routing** (IF conditions THEN actions)
- **CRM integration** (route to assigned technician)
- **Calendar sync** (Google Calendar, Outlook)
- **Approval workflow** (draft review before send)

### Integration Points

- CRM contacts (assigned technician lookup)
- Calendar (Google, Outlook)
- User/Team management
- Email accounts
