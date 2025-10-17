# PM System - Smart UI Conditional Logic

## 🎯 Obiettivo

UI che si adatta automaticamente al numero di utenti attivi:
- **1 utente attivo** → UI semplificata, no dropdown
- **2+ utenti attivi** → UI completa con team selection

---

## 📊 Logica Condizionale

### Backend: API `GET /api/pm/context`

Nuova API che ritorna il contesto corrente:

```typescript
// GET /api/pm/context
fastify.get('/api/pm/context', async (request, reply) => {
  // Conta utenti attivi
  const result = await db.query(`
    SELECT COUNT(*) as count
    FROM users
    WHERE status = 'active'
  `);

  const activeUserCount = parseInt(result.rows[0].count);
  const isTeamMode = activeUserCount > 1;

  // Info utente corrente
  const currentUser = request.user; // Già iniettato dal middleware

  reply.send({
    success: true,
    data: {
      currentUser: {
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        role: currentUser.role
      },
      teamMode: isTeamMode,
      activeUserCount: activeUserCount,
      showTeamFeatures: isTeamMode,
      showUserSelector: isTeamMode
    }
  });
});
```

### Frontend: Hook `useTeamContext`

```typescript
// hooks/useTeamContext.ts
import { useState, useEffect } from 'react';

interface TeamContext {
  currentUser: {
    id: string;
    name: string;
    email: string;
    role: string;
  };
  teamMode: boolean;
  activeUserCount: number;
  showTeamFeatures: boolean;
  showUserSelector: boolean;
}

export function useTeamContext() {
  const [context, setContext] = useState<TeamContext | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadContext();
  }, []);

  async function loadContext() {
    try {
      const res = await fetch('/api/pm/context');
      const data = await res.json();
      if (data.success) {
        setContext(data.data);
      }
    } catch (error) {
      console.error('Failed to load team context:', error);
    } finally {
      setLoading(false);
    }
  }

  return {
    context,
    loading,
    isTeamMode: context?.teamMode || false,
    showUserSelector: context?.showUserSelector || false,
    currentUserId: context?.currentUser?.id
  };
}
```

---

## 🎨 Componenti Intelligenti

### 1. Smart Task Assignment

```typescript
// components/SmartTaskAssignment.tsx
import React, { useState, useEffect } from 'react';
import { useTeamContext } from '../hooks/useTeamContext';

interface User {
  id: string;
  name: string;
  status: string;
}

interface SmartTaskAssignmentProps {
  taskId?: string;
  currentAssignee?: string;
  onAssign: (userId: string) => void;
}

export function SmartTaskAssignment({
  taskId,
  currentAssignee,
  onAssign
}: SmartTaskAssignmentProps) {
  const { context, loading, showUserSelector, currentUserId } = useTeamContext();
  const [users, setUsers] = useState<User[]>([]);

  useEffect(() => {
    if (showUserSelector) {
      loadUsers();
    }
  }, [showUserSelector]);

  async function loadUsers() {
    const res = await fetch('/api/pm/users?status=active');
    const data = await res.json();
    if (data.success) {
      setUsers(data.data);
    }
  }

  // AUTO-ASSIGN: Se solo 1 utente, assegna automaticamente
  useEffect(() => {
    if (!loading && !showUserSelector && currentUserId && !currentAssignee) {
      onAssign(currentUserId);
    }
  }, [loading, showUserSelector, currentUserId, currentAssignee]);

  if (loading) {
    return <div className="text-gray-500">Loading...</div>;
  }

  // SINGLE USER MODE: No selector, show only "Assigned to Me"
  if (!showUserSelector) {
    return (
      <div className="flex items-center gap-2 text-sm text-gray-600">
        <span className="font-medium">Assigned to:</span>
        <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded">
          {context?.currentUser.name || 'Me'}
        </span>
      </div>
    );
  }

  // TEAM MODE: Show full selector
  return (
    <div className="flex items-center gap-2">
      <label className="text-sm font-medium text-gray-700">
        Assign to:
      </label>
      <select
        value={currentAssignee || ''}
        onChange={(e) => onAssign(e.target.value)}
        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
      >
        <option value="">Unassigned</option>
        {users.map(user => (
          <option key={user.id} value={user.id}>
            {user.name}
          </option>
        ))}
      </select>
    </div>
  );
}
```

### 2. Smart Navigation Menu

```typescript
// components/SmartNavigation.tsx
import React from 'react';
import { Link } from 'react-router-dom';
import { useTeamContext } from '../hooks/useTeamContext';
import { FolderKanban, Users, Settings } from 'lucide-react';

export function SmartNavigation() {
  const { showTeamFeatures } = useTeamContext();

  return (
    <nav className="flex gap-6">
      <Link to="/projects" className="flex items-center gap-2">
        <FolderKanban className="w-5 h-5" />
        <span>Projects</span>
      </Link>

      {/* CONDITIONAL: Show Team tab only if multiple users */}
      {showTeamFeatures && (
        <Link to="/team" className="flex items-center gap-2">
          <Users className="w-5 h-5" />
          <span>Team</span>
        </Link>
      )}

      <Link to="/settings" className="flex items-center gap-2">
        <Settings className="w-5 h-5" />
        <span>Settings</span>
      </Link>
    </nav>
  );
}
```

### 3. Smart Project Detail

```typescript
// pages/ProjectDetail.tsx (aggiornato)
import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useTeamContext } from '../hooks/useTeamContext';
import { SmartTaskAssignment } from '../components/SmartTaskAssignment';

export function ProjectDetail() {
  const { id } = useParams();
  const { currentUserId, showUserSelector } = useTeamContext();
  const [tasks, setTasks] = useState([]);
  const [newTaskName, setNewTaskName] = useState('');

  async function createTask() {
    if (!newTaskName) return;

    const payload = {
      projectId: id,
      taskName: newTaskName,
      // AUTO-ASSIGN: Se single-user, assegna automaticamente
      assignedTo: !showUserSelector ? currentUserId : undefined
    };

    const res = await api.createTask(payload);
    if (res.success) {
      loadTasks();
      setNewTaskName('');
    }
  }

  async function loadTasks() {
    const res = await api.getProjectTasks(id);
    if (res.success) {
      setTasks(res.data);
    }
  }

  useEffect(() => {
    loadTasks();
  }, [id]);

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Project Details</h1>

      {/* Create Task Form */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <h2 className="text-lg font-semibold mb-4">New Task</h2>
        <div className="flex gap-4">
          <input
            type="text"
            value={newTaskName}
            onChange={(e) => setNewTaskName(e.target.value)}
            placeholder="Task name..."
            className="flex-1 px-4 py-2 border rounded-lg"
          />
          <button
            onClick={createTask}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Create
          </button>
        </div>

        {/* Info text cambia in base al mode */}
        {!showUserSelector && (
          <p className="text-sm text-gray-500 mt-2">
            New tasks will be automatically assigned to you
          </p>
        )}
      </div>

      {/* Tasks List */}
      <div className="space-y-4">
        {tasks.map(task => (
          <div key={task.id} className="bg-white rounded-lg shadow p-4">
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <h3 className="font-semibold">{task.task_name}</h3>
                <div className="flex items-center gap-4 mt-2">
                  <span className={`px-2 py-1 rounded text-sm ${
                    task.status === 'done' ? 'bg-green-100 text-green-800' :
                    task.status === 'in_progress' ? 'bg-blue-100 text-blue-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {task.status}
                  </span>

                  {/* SMART ASSIGNMENT: Condizionale */}
                  <SmartTaskAssignment
                    taskId={task.id}
                    currentAssignee={task.assigned_to}
                    onAssign={(userId) => handleAssignTask(task.id, userId)}
                  />
                </div>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => handleUpdateStatus(task.id, 'in_progress')}
                  className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700"
                  disabled={task.status === 'done'}
                >
                  Start
                </button>
                <button
                  onClick={() => handleUpdateStatus(task.id, 'done')}
                  className="px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700"
                  disabled={task.status === 'done'}
                >
                  Done
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  async function handleAssignTask(taskId: string, userId: string) {
    await api.updateTask(taskId, { assignedTo: userId });
    loadTasks();
  }

  async function handleUpdateStatus(taskId: string, status: string) {
    await api.updateTask(taskId, { status });
    loadTasks();
  }
}
```

### 4. Smart Dashboard

```typescript
// pages/Dashboard.tsx
import React from 'react';
import { useTeamContext } from '../hooks/useTeamContext';

export function Dashboard() {
  const { context, showTeamFeatures } = useTeamContext();

  return (
    <div className="p-6">
      {/* Header cambia in base al mode */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold">
          {showTeamFeatures ? 'Team Dashboard' : 'My Projects'}
        </h1>
        <p className="text-gray-600 mt-2">
          {showTeamFeatures
            ? `Managing ${context?.activeUserCount} team members`
            : 'Your personal project workspace'
          }
        </p>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-3 gap-6 mb-8">
        <StatCard
          title="Active Projects"
          value="12"
          icon="📊"
        />
        <StatCard
          title="Tasks This Week"
          value="34"
          icon="✅"
        />
        {showTeamFeatures ? (
          <StatCard
            title="Team Members"
            value={context?.activeUserCount || 0}
            icon="👥"
          />
        ) : (
          <StatCard
            title="Completed Tasks"
            value="156"
            icon="🎯"
          />
        )}
      </div>

      {/* Recent activity */}
      <RecentActivity showUserColumn={showTeamFeatures} />
    </div>
  );
}
```

---

## 🔧 Backend: Auto-Assign Logic

```typescript
// services/TaskService.ts - createTask method (aggiornato)
async createTask(req: CreateTaskRequest): Promise<Task> {
  let assignedTo = req.assignedTo;

  // AUTO-ASSIGN: Se non specificato, assegna all'utente corrente
  if (!assignedTo) {
    assignedTo = req.userId; // Sempre presente dal middleware
  }

  // Se è specificato useAiAssignment, usa AI
  let assignmentMethod = 'manual';
  let aiSuggestions = null;

  if (req.useAiAssignment) {
    const suggestions = await this.aiService.suggestAssignment({
      projectId: req.projectId,
      taskName: req.taskName,
      taskCategory: req.taskCategory,
      estimatedHours: req.estimatedHours
    });

    if (suggestions.length > 0) {
      assignedTo = suggestions[0].userId;
      assignmentMethod = 'ai';
      aiSuggestions = suggestions;
    }
  }

  const result = await this.db.query(`
    INSERT INTO pm.tasks (
      project_id,
      tenant_id,
      task_name,
      task_category,
      description,
      priority,
      estimated_hours,
      due_date,
      assigned_to,        -- Sempre valorizzato
      ai_suggested_users,
      ai_assignment_reasoning,
      assignment_method,
      status
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
    RETURNING *
  `, [
    req.projectId,
    req.tenantId,
    req.taskName,
    req.taskCategory || null,
    req.description || null,
    req.priority || 'medium',
    req.estimatedHours || null,
    req.dueDate || null,
    assignedTo,  // ← SEMPRE presente (current user se non specificato)
    aiSuggestions ? JSON.stringify(aiSuggestions.map(s => s.userId)) : null,
    aiSuggestions ? JSON.stringify(aiSuggestions) : null,
    assignmentMethod,
    'todo'
  ]);

  return this.mapTask(result.rows[0]);
}
```

---

## 📊 Database: Aggiunta `is_default_user`

```sql
-- Migration: Add is_default_user flag
ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_default_user BOOLEAN DEFAULT false;

-- Marca l'utente corrente come default
UPDATE users
SET is_default_user = true
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Index per performance
CREATE INDEX IF NOT EXISTS idx_users_default
ON users(is_default_user) WHERE is_default_user = true;

-- Query per contare utenti attivi
-- (usata in /api/pm/context)
CREATE INDEX IF NOT EXISTS idx_users_active_count
ON users(status) WHERE status = 'active';
```

---

## 🎯 Flussi Completi

### Flusso 1: Freelancer (1 utente)

```
1. Apre app → GET /api/pm/context
   Response: {
     teamMode: false,
     activeUserCount: 1,
     showUserSelector: false
   }

2. Va su "New Task"
   → Campo "Assign to" NASCOSTO
   → Task auto-assegnato a lui

3. Vede task list
   → Tutti i task mostrano "Assigned to: Me"
   → No dropdown di selezione

4. Menu navigation
   → NO tab "Team"
   → Solo "Projects" e "Settings"
```

### Flusso 2: Team Lead (3 utenti)

```
1. Apre app → GET /api/pm/context
   Response: {
     teamMode: true,
     activeUserCount: 3,
     showUserSelector: true
   }

2. Va su "New Task"
   → Campo "Assign to" VISIBILE
   → Dropdown con: Sara, Luca, Mario
   → Può scegliere o lasciare "Unassigned"

3. Vede task list
   → Ogni task mostra utente assegnato
   → Può cambiare assegnazione con dropdown

4. Menu navigation
   → Tab "Team" PRESENTE
   → Può gestire membri team
```

### Flusso 3: Downsizing (3 → 1 utente)

```
1. Team Lead va su "Team Management"
2. Disabilita Sara e Luca
3. GET /api/pm/context aggiornato automaticamente
   Response: {
     teamMode: false,  ← Cambiato!
     activeUserCount: 1,
     showUserSelector: false
   }

4. UI si aggiorna automaticamente:
   → Dropdown assegnazione SCOMPAIONO
   → Task assegnati a Sara/Luca mostrano badge "(disabled)"
   → Nuovi task auto-assegnati a Mario
   → Tab "Team" rimane (per vedere storico)
```

---

## ✅ Vantaggi Chiave

### 1. Zero Cognitive Load
- ✅ Freelancer: UI pulita, no complessità inutile
- ✅ Team: UI completa solo quando serve

### 2. Transizioni Automatiche
- ✅ Aggiungi utente → UI si espande automaticamente
- ✅ Rimuovi utenti → UI si semplifica automaticamente

### 3. Performance
- ✅ Single query per context: `COUNT(*) WHERE status = 'active'`
- ✅ Cache context in frontend (refresh ogni operazione team)

### 4. Backward Compatible
- ✅ Task vecchi: assigned_to sempre valorizzato
- ✅ Utenti disabilitati: visibili in storico

---

## 🚀 Implementation Checklist

### Backend
- [ ] API `GET /api/pm/context` con team mode detection
- [ ] TaskService auto-assign logic
- [ ] Middleware sempre inietta `request.userId`

### Frontend
- [ ] Hook `useTeamContext()`
- [ ] Component `<SmartTaskAssignment />`
- [ ] Component `<SmartNavigation />`
- [ ] Update `ProjectDetail.tsx` con conditional UI

### Database
- [ ] Add `is_default_user` column
- [ ] Add indexes for performance
- [ ] Migration script

Procedo con l'implementazione? 🎯
