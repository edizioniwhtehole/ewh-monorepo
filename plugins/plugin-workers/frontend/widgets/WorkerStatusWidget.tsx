/**
 * Worker Status Widget
 * Displays real-time worker pool status
 */

import { useEffect, useState } from 'react';
import { Cpu, Activity, CheckCircle, XCircle, Clock } from 'lucide-react';
import type { WidgetProps } from '@ewh/plugin-engine';

interface WorkerStatus {
  id: string;
  name: string;
  status: 'active' | 'idle' | 'error';
  currentTask?: string;
  tasksCompleted: number;
  uptime: number;
  cpu: number;
  memory: number;
}

interface Config {
  refreshInterval: number;
  showInactive: boolean;
}

export default function WorkerStatusWidget({ instanceId, config, isEditMode }: WidgetProps<Config>) {
  const [workers, setWorkers] = useState<WorkerStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({ active: 0, idle: 0, error: 0 });

  useEffect(() => {
    async function fetchWorkers() {
      try {
        const response = await fetch('/api/workers/status');
        if (response.ok) {
          const data = await response.json();
          setWorkers(data.workers);

          // Calculate stats
          const active = data.workers.filter((w: WorkerStatus) => w.status === 'active').length;
          const idle = data.workers.filter((w: WorkerStatus) => w.status === 'idle').length;
          const error = data.workers.filter((w: WorkerStatus) => w.status === 'error').length;
          setStats({ active, idle, error });
        }
      } catch (error) {
        console.error('Failed to fetch workers:', error);
      } finally {
        setLoading(false);
      }
    }

    fetchWorkers();
    const interval = setInterval(fetchWorkers, config.refreshInterval || 5000);
    return () => clearInterval(interval);
  }, [config.refreshInterval]);

  const statusColors = {
    active: 'bg-emerald-500',
    idle: 'bg-yellow-500',
    error: 'bg-red-500'
  };

  const statusIcons = {
    active: Activity,
    idle: Clock,
    error: XCircle
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-slate-400">Loading workers...</div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-slate-900 rounded-lg border border-slate-800 p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Cpu size={20} className="text-indigo-400" />
          <h3 className="font-semibold text-white">Worker Pool</h3>
        </div>
        <div className="flex gap-2 text-xs">
          <span className="flex items-center gap-1 text-emerald-400">
            <div className="w-2 h-2 rounded-full bg-emerald-500" />
            {stats.active} Active
          </span>
          <span className="flex items-center gap-1 text-yellow-400">
            <div className="w-2 h-2 rounded-full bg-yellow-500" />
            {stats.idle} Idle
          </span>
          {stats.error > 0 && (
            <span className="flex items-center gap-1 text-red-400">
              <div className="w-2 h-2 rounded-full bg-red-500" />
              {stats.error} Error
            </span>
          )}
        </div>
      </div>

      {/* Workers List */}
      <div className="flex-1 overflow-y-auto space-y-2">
        {workers
          .filter(w => config.showInactive || w.status !== 'idle')
          .map((worker) => {
            const StatusIcon = statusIcons[worker.status];
            return (
              <div
                key={worker.id}
                className="flex items-center justify-between p-3 rounded-lg bg-slate-950/50 border border-slate-800"
              >
                <div className="flex items-center gap-3 flex-1">
                  <div className={`w-2 h-2 rounded-full ${statusColors[worker.status]}`} />
                  <div className="flex-1">
                    <div className="text-sm font-medium text-white">{worker.name}</div>
                    {worker.currentTask && (
                      <div className="text-xs text-slate-400 truncate">{worker.currentTask}</div>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-4 text-xs text-slate-400">
                  <div>
                    <CheckCircle size={12} className="inline mr-1" />
                    {worker.tasksCompleted}
                  </div>
                  <div className="text-emerald-400">{worker.cpu}%</div>
                  <div className="text-blue-400">{worker.memory}MB</div>
                </div>
              </div>
            );
          })}
      </div>

      {/* Footer Stats */}
      <div className="mt-4 pt-4 border-t border-slate-800 grid grid-cols-3 gap-4 text-center">
        <div>
          <div className="text-2xl font-bold text-white">{workers.length}</div>
          <div className="text-xs text-slate-400">Total Workers</div>
        </div>
        <div>
          <div className="text-2xl font-bold text-emerald-400">{stats.active}</div>
          <div className="text-xs text-slate-400">Working Now</div>
        </div>
        <div>
          <div className="text-2xl font-bold text-indigo-400">
            {workers.reduce((sum, w) => sum + w.tasksCompleted, 0)}
          </div>
          <div className="text-xs text-slate-400">Tasks Done</div>
        </div>
      </div>
    </div>
  );
}
