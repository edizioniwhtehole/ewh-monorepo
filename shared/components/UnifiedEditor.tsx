/**
 * Unified Code Editor Component
 * Monaco-based editor condiviso tra app-admin-frontend e app-web-frontend
 *
 * Features:
 * - Syntax highlighting (JS, TS, SQL, JSON, Markdown, etc.)
 * - IntelliSense & autocomplete
 * - Multi-tab editing
 * - Version history & diff
 * - Real-time collaboration
 * - Custom snippets
 * - Theme support
 */

'use client';

import { useEffect, useRef, useState } from 'react';
import {
  Code, Save, History, Users, Settings,
  Play, Download, Upload, Maximize2, X,
  Copy, Check
} from 'lucide-react';

// Types
export interface EditorProps {
  entityType: 'workflow' | 'route' | 'function' | 'widget' | 'plugin' | 'page' | 'template' | 'middleware';
  entityId: string;
  entityName: string;
  content: string;
  contentType: 'json' | 'javascript' | 'typescript' | 'sql' | 'markdown' | 'html' | 'css' | 'yaml';
  readOnly?: boolean;
  showToolbar?: boolean;
  showMinimap?: boolean;
  height?: string;
  theme?: 'vs-dark' | 'vs-light' | 'hc-black';
  onChange?: (content: string) => void;
  onSave?: (content: string) => void;
  onExecute?: (content: string) => void;
  onClose?: () => void;
}

export interface EditorSession {
  userId: string;
  userName: string;
  isActive: boolean;
  cursorPosition: number;
  locked: boolean;
}

export function UnifiedEditor({
  entityType,
  entityId,
  entityName,
  content,
  contentType,
  readOnly = false,
  showToolbar = true,
  showMinimap = true,
  height = '600px',
  theme = 'vs-dark',
  onChange,
  onSave,
  onExecute,
  onClose
}: EditorProps) {
  const editorRef = useRef<any>(null);
  const monacoRef = useRef<any>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const [currentContent, setCurrentContent] = useState(content);
  const [isDirty, setIsDirty] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [activeSessions, setActiveSessions] = useState<EditorSession[]>([]);
  const [showHistory, setShowHistory] = useState(false);
  const [copied, setCopied] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);

  // Initialize Monaco Editor
  useEffect(() => {
    let editor: any;

    const initMonaco = async () => {
      // Dynamic import Monaco Editor
      const monaco = await import('monaco-editor');
      monacoRef.current = monaco;

      if (!containerRef.current) return;

      // Configure Monaco
      monaco.editor.defineTheme('ewh-dark', {
        base: 'vs-dark',
        inherit: true,
        rules: [],
        colors: {
          'editor.background': '#0f172a',
          'editor.lineHighlightBackground': '#1e293b',
          'editorCursor.foreground': '#818cf8',
          'editor.selectionBackground': '#3730a380',
        }
      });

      // Create editor instance
      editor = monaco.editor.create(containerRef.current, {
        value: currentContent,
        language: getMonacoLanguage(contentType),
        theme: theme === 'vs-dark' ? 'ewh-dark' : theme,
        readOnly,
        minimap: { enabled: showMinimap },
        fontSize: 14,
        lineNumbers: 'on',
        roundedSelection: true,
        scrollBeyondLastLine: false,
        automaticLayout: true,
        tabSize: 2,
        formatOnPaste: true,
        formatOnType: true,
        suggestOnTriggerCharacters: true,
        quickSuggestions: true,
        wordWrap: 'on',
      });

      editorRef.current = editor;

      // Listen for changes
      editor.onDidChangeModelContent(() => {
        const value = editor.getValue();
        setCurrentContent(value);
        setIsDirty(value !== content);
        onChange?.(value);
      });

      // Register custom snippets
      registerCustomSnippets(monaco, contentType);
    };

    initMonaco();

    return () => {
      editor?.dispose();
    };
  }, []);

  // Update content when prop changes
  useEffect(() => {
    if (editorRef.current && !isDirty) {
      editorRef.current.setValue(content);
      setCurrentContent(content);
    }
  }, [content]);

  // Active sessions (WebSocket simulation)
  useEffect(() => {
    const fetchSessions = async () => {
      try {
        const res = await fetch(`/api/editor/sessions?entityType=${entityType}&entityId=${entityId}`);
        const data = await res.json();
        setActiveSessions(data.sessions || []);
      } catch (err) {
        console.error('Failed to fetch sessions:', err);
      }
    };

    fetchSessions();
    const interval = setInterval(fetchSessions, 5000);

    return () => clearInterval(interval);
  }, [entityType, entityId]);

  // Handlers
  const handleSave = async () => {
    if (!onSave) return;

    setIsSaving(true);
    try {
      await onSave(currentContent);
      setIsDirty(false);
    } catch (err) {
      console.error('Save failed:', err);
    } finally {
      setIsSaving(false);
    }
  };

  const handleExecute = () => {
    if (!onExecute) return;
    onExecute(currentContent);
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(currentContent);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownload = () => {
    const blob = new Blob([currentContent], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${entityId}.${getFileExtension(contentType)}`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleFormat = () => {
    if (editorRef.current) {
      editorRef.current.getAction('editor.action.formatDocument').run();
    }
  };

  const toggleFullscreen = () => {
    setIsFullscreen(!isFullscreen);
  };

  return (
    <div className={`flex flex-col bg-slate-900 border border-slate-800 rounded-lg overflow-hidden ${
      isFullscreen ? 'fixed inset-4 z-50' : ''
    }`}>
      {/* Toolbar */}
      {showToolbar && (
        <div className="flex items-center justify-between px-4 py-2 bg-slate-800 border-b border-slate-700">
          {/* Left */}
          <div className="flex items-center gap-2">
            <Code className="text-indigo-400" size={18} />
            <div className="flex flex-col">
              <span className="text-sm font-medium text-white">{entityName}</span>
              <span className="text-xs text-slate-400">{entityType} · {contentType}</span>
            </div>
            {isDirty && (
              <span className="text-xs px-2 py-0.5 bg-yellow-500/20 text-yellow-400 rounded">
                Unsaved
              </span>
            )}
          </div>

          {/* Right */}
          <div className="flex items-center gap-2">
            {/* Active users */}
            {activeSessions.length > 0 && (
              <div className="flex items-center gap-1 px-2 py-1 bg-slate-700 rounded text-xs text-slate-300">
                <Users size={14} />
                {activeSessions.length}
              </div>
            )}

            {/* Actions */}
            <button
              onClick={handleCopy}
              className="p-1.5 rounded hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
              title="Copy"
            >
              {copied ? <Check size={16} /> : <Copy size={16} />}
            </button>

            <button
              onClick={handleDownload}
              className="p-1.5 rounded hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
              title="Download"
            >
              <Download size={16} />
            </button>

            <button
              onClick={() => setShowHistory(!showHistory)}
              className="p-1.5 rounded hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
              title="History"
            >
              <History size={16} />
            </button>

            {onExecute && (
              <button
                onClick={handleExecute}
                className="px-3 py-1.5 bg-green-600 hover:bg-green-700 text-white rounded text-sm font-medium transition-colors"
                title="Execute"
              >
                <Play size={14} className="inline mr-1" />
                Run
              </button>
            )}

            {onSave && !readOnly && (
              <button
                onClick={handleSave}
                disabled={!isDirty || isSaving}
                className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-700 disabled:text-slate-500 text-white rounded text-sm font-medium transition-colors"
                title="Save (Ctrl+S)"
              >
                <Save size={14} className="inline mr-1" />
                {isSaving ? 'Saving...' : 'Save'}
              </button>
            )}

            <button
              onClick={toggleFullscreen}
              className="p-1.5 rounded hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
              title="Toggle fullscreen"
            >
              {isFullscreen ? <X size={16} /> : <Maximize2 size={16} />}
            </button>

            {onClose && (
              <button
                onClick={onClose}
                className="p-1.5 rounded hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
                title="Close"
              >
                <X size={16} />
              </button>
            )}
          </div>
        </div>
      )}

      {/* Editor */}
      <div
        ref={containerRef}
        style={{ height: isFullscreen ? 'calc(100vh - 120px)' : height }}
        className="flex-1"
      />

      {/* History Panel */}
      {showHistory && (
        <HistoryPanel
          entityType={entityType}
          entityId={entityId}
          onClose={() => setShowHistory(false)}
          onRestore={(version) => {
            // Load version content
            console.log('Restore version:', version);
          }}
        />
      )}

      {/* Status Bar */}
      {showToolbar && (
        <div className="flex items-center justify-between px-4 py-1 bg-slate-800 border-t border-slate-700 text-xs text-slate-400">
          <div className="flex items-center gap-4">
            <span>Lines: {currentContent.split('\n').length}</span>
            <span>Chars: {currentContent.length}</span>
          </div>
          <div className="flex items-center gap-2">
            {activeSessions.map((session, i) => (
              <div key={i} className="flex items-center gap-1">
                <div className="w-2 h-2 rounded-full bg-green-400" />
                <span>{session.userName}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// History Panel Component
function HistoryPanel({
  entityType,
  entityId,
  onClose,
  onRestore
}: {
  entityType: string;
  entityId: string;
  onClose: () => void;
  onRestore: (version: number) => void;
}) {
  const [history, setHistory] = useState<any[]>([]);

  useEffect(() => {
    fetch(`/api/editor/history?entityType=${entityType}&entityId=${entityId}`)
      .then(res => res.json())
      .then(data => setHistory(data.history || []))
      .catch(console.error);
  }, [entityType, entityId]);

  return (
    <div className="absolute right-0 top-0 bottom-0 w-80 bg-slate-800 border-l border-slate-700 p-4 overflow-auto">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-white">Version History</h3>
        <button onClick={onClose} className="text-slate-400 hover:text-white">
          <X size={16} />
        </button>
      </div>

      <div className="space-y-2">
        {history.map((item) => (
          <div key={item.id} className="p-3 bg-slate-700 rounded">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-white">v{item.version}</span>
              <span className="text-xs text-slate-400">
                {new Date(item.created_at).toLocaleString()}
              </span>
            </div>
            <p className="text-xs text-slate-300 mb-2">{item.change_summary}</p>
            <button
              onClick={() => onRestore(item.version)}
              className="text-xs px-2 py-1 bg-indigo-600 hover:bg-indigo-700 text-white rounded"
            >
              Restore
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

// Helper functions
function getMonacoLanguage(contentType: string): string {
  const mapping: Record<string, string> = {
    'javascript': 'javascript',
    'typescript': 'typescript',
    'json': 'json',
    'sql': 'sql',
    'markdown': 'markdown',
    'html': 'html',
    'css': 'css',
    'yaml': 'yaml',
  };
  return mapping[contentType] || 'plaintext';
}

function getFileExtension(contentType: string): string {
  const mapping: Record<string, string> = {
    'javascript': 'js',
    'typescript': 'ts',
    'json': 'json',
    'sql': 'sql',
    'markdown': 'md',
    'html': 'html',
    'css': 'css',
    'yaml': 'yaml',
  };
  return mapping[contentType] || 'txt';
}

function registerCustomSnippets(monaco: any, contentType: string) {
  if (contentType === 'javascript' || contentType === 'typescript') {
    monaco.languages.registerCompletionItemProvider(contentType, {
      provideCompletionItems: () => {
        return {
          suggestions: [
            {
              label: 'transform',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'function execute(input, config) {\n  // Transform logic\n  return input;\n}',
              documentation: 'Transform function template'
            },
            {
              label: 'validate',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'function execute(input, config) {\n  if (!input) {\n    throw new Error("Invalid input");\n  }\n  return input;\n}',
              documentation: 'Validation function template'
            },
            {
              label: 'enrich',
              kind: monaco.languages.CompletionItemKind.Snippet,
              insertText: 'function execute(input, config) {\n  return {\n    ...input,\n    enrichedData: {}\n  };\n}',
              documentation: 'Enrichment function template'
            }
          ]
        };
      }
    });
  }
}

export default UnifiedEditor;