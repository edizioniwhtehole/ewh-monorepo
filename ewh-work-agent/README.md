# EWH Work Agent - Desktop Activity Monitor

**Cross-platform desktop application** (Electron) for employee activity monitoring with transparent policy enforcement and contextual access control.

## 🎯 Features

- 🖥️ **Cross-Platform** - Windows, macOS, Linux support
- 📊 **Real-Time Monitoring** - Application tracking, input activity, idle detection
- 🌐 **Embedded Browser** - Secure browsing with content filtering
- 🔒 **Policy Enforcement** - Automatic blocking of unauthorized apps/domains
- 📸 **Screenshot Capture** - Optional periodic screenshots (consent-based)
- 🔔 **Transparent UI** - Always-visible tray icon, desktop notifications
- 📈 **Personal Dashboard** - View your own activity and budgets
- ✅ **Privacy-First** - No keylogging, user control over data

---

## 📋 Installation

### Pre-built Installers

Download from: `https://releases.polosaas.it/ewh-work-agent/`

**Windows:**
- `ewh-work-agent-setup-1.0.0.exe` (NSIS installer)

**macOS:**
- `ewh-work-agent-1.0.0.dmg` (DMG image)

**Linux:**
- `ewh-work-agent_1.0.0_amd64.deb` (Debian/Ubuntu)
- `ewh-work-agent-1.0.0.AppImage` (Universal)

### From Source

```bash
# Clone repository
git clone https://github.com/edizioniwhitehole/ewh-work-agent

# Install dependencies
npm install

# Development mode
npm run dev

# Build for your platform
npm run build:win   # Windows
npm run build:mac   # macOS
npm run build:linux # Linux
```

---

## 🚀 Quick Start

### First Launch

1. **Install** the application using the appropriate installer
2. **Launch** EWH Work Agent - it will start automatically
3. **Login** with your company credentials
4. **Grant permissions** (screen recording on macOS, accessibility on Windows)
5. **Review policy** - Read and accept the monitoring policy
6. **Start working** - Agent runs in background with tray icon

### System Tray

The agent runs in the system tray with an always-visible icon:

```
🟢 [EWH] - Monitoring Active
   ├─ Dashboard
   ├─ My Activity Today
   ├─ Budget Status
   ├─ Policy Documents
   ├─ Settings
   └─ Quit (requires password)
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│  Main Process (Electron/Node.js)        │
│  ┌─────────────────────────────────┐   │
│  │  App Monitor                     │   │ <- Native API (Win32/NSWorkspace/X11)
│  │  - Active window tracking        │   │
│  │  - Mouse/keyboard activity       │   │
│  │  - Running apps detection        │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │  Heartbeat Sender                │   │ <- REST API to backend
│  │  - Every 30 seconds             │   │
│  │  - Offline queue                │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │  Policy Enforcer                 │   │
│  │  - Block unauthorized apps       │   │
│  │  - Domain filtering              │   │
│  │  - Violation logging             │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │  Browser Manager                 │   │
│  │  - Embedded Chromium             │   │
│  │  - Content filtering             │   │
│  │  - URL tracking                  │   │
│  └─────────────────────────────────┘   │
└────────────────┬────────────────────────┘
                 │ IPC Bridge
┌────────────────▼────────────────────────┐
│  Renderer Process (React)               │
│  - Dashboard UI                          │
│  - Settings panel                        │
│  - Activity viewer                       │
└─────────────────────────────────────────┘
```

---

## ⚙️ Configuration

Configuration stored in: `~/.ewh-work-agent/config.json`

```json
{
  "api_url": "https://api.polosaas.it",
  "heartbeat_interval_seconds": 30,
  "screenshot_enabled": false,
  "enforce_policies": true,
  "notifications_enabled": true,
  "send_window_titles": true
}
```

**Edit via Settings UI** in the application.

---

## 🔐 What is Monitored?

### ✅ Monitored (with consent)
- **Applications:** Names of apps you use and time spent
- **Window Titles:** Titles of active windows (e.g., "GitHub - Pull Requests")
- **Websites:** URLs you visit in the work browser
- **Input Activity:** Mouse movement and keyboard presence (NOT content)
- **Screenshots:** Optional, periodic captures (if enabled)

### ❌ NOT Monitored
- **Keystrokes:** No keylogging - content of what you type is never captured
- **Personal Communications:** No email/chat content
- **Off-Hours:** No tracking outside work hours
- **Private Browsing:** Activity in personal browsers (Chrome, Firefox) is not tracked

---

## 🌐 Work Browser

### Features
- **Embedded Chromium** - Full-featured browser
- **Content Filtering** - Automatic blocking of restricted sites
- **Justified Access** - Request access with reason
- **Session Tracking** - Time spent per page logged

### Requesting Access

When you visit a restricted site (e.g., YouTube):

1. **Justification Modal** appears
2. **Select reason:** Tutorial, Research, Personal Break, etc.
3. **Provide details:** "React Hooks tutorial for project X"
4. **System decides:**
   - Auto-approved if within budget
   - Pending if requires manager approval
5. **Timer starts:** Session active for approved duration
6. **Activity tracked:** URLs and time logged for relevance scoring

**AI Classification:** Your activity is analyzed to determine if it's work-related (e.g., "React Tutorial" → 92% work-related).

---

## 📊 Personal Dashboard

Access your own data:

### Today's Overview
- **Work Hours:** Total active time
- **Idle Time:** Time away from computer
- **Productivity Score:** Algorithmic score 0-100
- **Top Apps:** Applications you used most

### Time Budgets
- **YouTube:** 15/60 minutes used today
- **Facebook:** 0/120 minutes used today
- **Personal Break:** 10/30 minutes used today

### Timeline
- Minute-by-minute breakdown of your day
- View what apps you used and when

---

## 🛠️ Troubleshooting

### Agent Not Starting

**macOS:**
```bash
# Check permissions
System Preferences > Security & Privacy > Privacy
- Screen Recording: ✅ EWH Work Agent
- Accessibility: ✅ EWH Work Agent

# Check logs
tail -f ~/.ewh-work-agent/logs/app.log
```

**Windows:**
```powershell
# Run as Administrator
Right-click EWH Work Agent → Run as administrator

# Check logs
type %APPDATA%\ewh-work-agent\logs\app.log
```

**Linux:**
```bash
# Check if running
ps aux | grep ewh-work-agent

# Check logs
tail -f ~/.ewh-work-agent/logs/app.log
```

### Can't Access Website

1. Check if domain is in **blocked list** (Settings > Policy)
2. Try **requesting access** with justification
3. Contact your **manager** for approval
4. Check **budget status** - you may have exceeded daily limit

### High CPU Usage

- Screenshots disabled: Settings > Privacy > Screenshot Capture: OFF
- Reduce heartbeat frequency: Settings > Advanced > Interval: 60s (max)

---

## 🔒 Privacy & Security

### Data Collected
- Application names and usage time
- Website URLs (work browser only)
- Window titles (configurable)
- Input activity presence (not content)
- Optional screenshots (with explicit consent)

### Data NOT Collected
- Keystroke content (no keylogging)
- Personal browser history (Chrome/Firefox)
- Off-hours activity
- Email/chat content

### Your Rights (GDPR)
- ✅ **Access:** View all your data anytime
- ✅ **Export:** Download your data as CSV
- ✅ **Correct:** Request data corrections
- ✅ **Delete:** Revoke consent (may affect employment)

**Privacy Officer:** dpo@edizioniwhitehole.it

---

## 🏢 For IT Administrators

### Deployment

**Silent Install (Windows):**
```powershell
ewh-work-agent-setup.exe /S /API_URL=https://api.company.com /AUTO_START=true
```

**MDM Deployment:**
- **InTune** (Windows) - MSI package available
- **Jamf** (macOS) - PKG package available
- **Puppet/Ansible** (Linux) - DEB/RPM packages

### Configuration Management

**Pre-configure via file:**
```bash
# Place config before first launch
# ~/.ewh-work-agent/config.json (Linux/macOS)
# %APPDATA%\ewh-work-agent\config.json (Windows)

{
  "api_url": "https://api.company.com",
  "auto_start_on_boot": true,
  "enforce_policies": true
}
```

### Unattended Installation

```bash
# Windows
msiexec /i ewh-work-agent.msi /quiet API_URL=https://api.company.com

# macOS
sudo installer -pkg ewh-work-agent.pkg -target /

# Linux (Debian)
sudo dpkg -i ewh-work-agent.deb
```

---

## 📚 Documentation

- **User Guide:** [USER_GUIDE.md](./docs/USER_GUIDE.md)
- **Admin Guide:** [ADMIN_GUIDE.md](./docs/ADMIN_GUIDE.md)
- **Privacy Policy:** [PRIVACY.md](./docs/PRIVACY.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)

---

## 📄 License

**Proprietary** - Edizioni White Hole S.r.l.

This software is provided to employees as part of their employment agreement. Unauthorized distribution, modification, or reverse engineering is prohibited.

---

## 🤝 Support

**For Employees:**
- Technical Issues: support@polosaas.it
- Privacy Questions: dpo@edizioniwhitehole.it

**For IT Administrators:**
- Deployment Help: it-support@edizioniwhitehole.it
- Documentation: https://docs.polosaas.it/work-agent

---

**Version:** 1.0.0
**Compatible with:** Windows 10+, macOS 12+, Ubuntu 20.04+
**Last Updated:** 2025-10-02
