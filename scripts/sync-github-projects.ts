#!/usr/bin/env tsx

/**
 * Sync Admin Database Tasks → GitHub Projects
 *
 * This script synchronizes tasks from the admin database
 * to GitHub Issues and Projects for team collaboration.
 */

import { Octokit } from '@octokit/rest';
import { createClient } from '@supabase/supabase-js';

// Configuration
const config = {
  github: {
    token: process.env.GITHUB_TOKEN!,
    org: process.env.GITHUB_ORG || 'your-org',
    repo: 'ewh',
    projectNumber: parseInt(process.env.GITHUB_PROJECT_NUMBER || '1'),
  },
  supabase: {
    url: process.env.SUPABASE_URL!,
    serviceKey: process.env.SUPABASE_SERVICE_KEY!,
  },
};

// Clients
const octokit = new Octokit({ auth: config.github.token });
const supabase = createClient(config.supabase.url, config.supabase.serviceKey);

interface Task {
  id: string;
  app_code: string;
  app_name: string;
  category: string;
  category_color: string;
  title: string;
  description: string;
  task_type: string;
  priority: 'low' | 'medium' | 'high' | 'critical';
  complexity: string;
  status: 'todo' | 'in_progress' | 'blocked' | 'review' | 'completed' | 'cancelled';
  assigned_to: string | null;
  due_date: string | null;
  estimated_hours: number | null;
  actual_hours: number | null;
  dependencies_count: number;
  blocks_count: number;
  subtasks_total: number;
  subtasks_completed: number;
  urgency: 'normal' | 'due_soon' | 'overdue';
}

async function main() {
  console.log('🔄 Starting GitHub Projects sync...\n');

  try {
    // 1. Fetch all tasks from admin database
    console.log('📊 Fetching tasks from admin database...');
    const { data: tasks, error } = await supabase
      .from('v_tasks_with_dependencies')
      .select('*')
      .order('priority', { ascending: false });

    if (error) throw error;
    console.log(`   ✅ Found ${tasks.length} tasks\n`);

    // 2. Get existing issues (to avoid duplicates)
    console.log('🔍 Fetching existing GitHub issues...');
    const { data: existingIssues } = await octokit.issues.listForRepo({
      owner: config.github.org,
      repo: config.github.repo,
      state: 'all',
      per_page: 100,
    });
    console.log(`   ✅ Found ${existingIssues?.length || 0} existing issues\n`);

    // Build map of task_id → issue
    const taskIssueMap = new Map<string, any>();
    existingIssues?.forEach(issue => {
      const taskLabel = issue.labels.find((l: any) =>
        typeof l === 'string' ? l.startsWith('task:') : l.name?.startsWith('task:')
      );
      if (taskLabel) {
        const taskId = typeof taskLabel === 'string'
          ? taskLabel.replace('task:', '')
          : taskLabel.name?.replace('task:', '');
        if (taskId) taskIssueMap.set(taskId, issue);
      }
    });

    // 3. Sync each task
    let created = 0;
    let updated = 0;
    let closed = 0;

    for (const task of tasks as Task[]) {
      const existingIssue = taskIssueMap.get(task.id);

      if (!existingIssue) {
        // Create new issue
        console.log(`   🆕 Creating issue for task: ${task.title}`);
        await createIssue(task);
        created++;
      } else {
        // Update existing issue
        const shouldUpdate =
          task.status !== getStatusFromLabels(existingIssue.labels) ||
          existingIssue.state !== getIssueState(task.status);

        if (shouldUpdate) {
          console.log(`   🔄 Updating issue #${existingIssue.number}: ${task.title}`);
          await updateIssue(existingIssue.number, task);
          updated++;

          if (task.status === 'completed' && existingIssue.state === 'open') {
            closed++;
          }
        }
      }
    }

    // 4. Summary
    console.log('\n✅ Sync completed successfully!\n');
    console.log('📊 Summary:');
    console.log(`   - Created: ${created} issues`);
    console.log(`   - Updated: ${updated} issues`);
    console.log(`   - Closed: ${closed} issues`);
    console.log(`   - Total: ${tasks.length} tasks synced`);
    console.log(`\n🔗 View project: https://github.com/orgs/${config.github.org}/projects/${config.github.projectNumber}`);

  } catch (error) {
    console.error('❌ Sync failed:', error);
    process.exit(1);
  }
}

async function createIssue(task: Task) {
  const labels = [
    `app:${task.app_code}`,
    `priority:${task.priority}`,
    `status:${task.status}`,
    `task:${task.id}`,
  ];

  if (task.task_type) labels.push(`type:${task.task_type}`);
  if (task.complexity) labels.push(`complexity:${task.complexity}`);

  const body = `
## Description
${task.description || 'No description provided'}

## Details
- **App**: ${task.app_name} (\`${task.app_code}\`)
- **Category**: ${task.category}
- **Priority**: ${task.priority}
- **Complexity**: ${task.complexity || 'Not specified'}
- **Estimated Hours**: ${task.estimated_hours || 'Not estimated'}
- **Due Date**: ${task.due_date ? new Date(task.due_date).toLocaleDateString() : 'Not set'}

## Progress
- **Status**: ${task.status}
- **Subtasks**: ${task.subtasks_completed}/${task.subtasks_total} completed
- **Dependencies**: ${task.dependencies_count}
- **Blocks**: ${task.blocks_count} other tasks

${task.urgency !== 'normal' ? `\n⚠️ **Urgency**: ${task.urgency}\n` : ''}

---
*Auto-synced from admin database (ID: \`${task.id}\`)*
*Last updated: ${new Date().toISOString()}*
  `.trim();

  const issue = await octokit.issues.create({
    owner: config.github.org,
    repo: config.github.repo,
    title: `[${task.app_code.toUpperCase()}] ${task.title}`,
    body,
    labels,
    assignees: task.assigned_to ? [parseUsername(task.assigned_to)] : [],
  });

  return issue.data;
}

async function updateIssue(issueNumber: number, task: Task) {
  const labels = [
    `app:${task.app_code}`,
    `priority:${task.priority}`,
    `status:${task.status}`,
    `task:${task.id}`,
  ];

  if (task.task_type) labels.push(`type:${task.task_type}`);
  if (task.complexity) labels.push(`complexity:${task.complexity}`);

  await octokit.issues.update({
    owner: config.github.org,
    repo: config.github.repo,
    issue_number: issueNumber,
    state: getIssueState(task.status),
    labels,
    assignees: task.assigned_to ? [parseUsername(task.assigned_to)] : [],
  });
}

function getIssueState(status: string): 'open' | 'closed' {
  return status === 'completed' || status === 'cancelled' ? 'closed' : 'open';
}

function getStatusFromLabels(labels: any[]): string | null {
  const statusLabel = labels.find((l: any) =>
    typeof l === 'string' ? l.startsWith('status:') : l.name?.startsWith('status:')
  );

  if (!statusLabel) return null;

  const status = typeof statusLabel === 'string'
    ? statusLabel.replace('status:', '')
    : statusLabel.name?.replace('status:', '');

  return status || null;
}

function parseUsername(email: string): string {
  // Extract GitHub username from email
  // Assumes format: username@domain or just username
  return email.split('@')[0].replace(/[^a-zA-Z0-9-]/g, '');
}

// Run
main();
