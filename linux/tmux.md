# 📘 Tmux Reference

A practical cheat sheet for terminal multiplexer (tmux).

---

## 🔹 Installation
- On Debian/Ubuntu:
  ```bash
  sudo apt install tmux
  ```
- On macOS:
  ```bash
  brew install tmux
  ```

---

## 🔹 Basic Commands

### Starting Tmux
```bash
# Start a new session (with default name from 0)
tmux

# Start a new named session
tmux new -s session_name

# Attach the last existing session
tmux attach
tmux a # shorter syntax

# Attach to an existing name session
tmux attach -t session_name
tmux a -t session_name # shorter syntax

# List all sessions
tmux ls

# Kill a named session
tmux kill-session -t session_name

# Kill all tmux sessions:
tmux ls | grep : | cut -d. -f1 | awk '{print substr($1, 0, length($1)-1)}' | xargs kill
```

---

## 🔹 Key Bindings
All commands are prefixed with `Ctrl+b` by default, then:

### Session Management
- `d` → Detach from current session
- `$` → Rename current session
- `)` → Switch to next session
- `(` → Switch to previous session
- `s` → Show session list for selection

### Window Management
- `c` → Create new window
- `,` → Rename current window
- `n` → Move to next window
- `p` → Move to previous window
- `w` → List windows for selection
- `&` → Kill current window
- `0-9` → Switch to window number

### Pane Management
- `%` → Split pane vertically
- `"` → Split pane horizontally
- `o` → Switch to next pane
- `q` → Show pane numbers (press number to select)
- `z` → Toggle pane zoom
- `x` → Kill current pane
- `{` → Move current pane left
- `}` → Move current pane right
- `Arrow keys` → Navigate between panes

---

## 🔹 Copy Mode
- `[` → Enter copy mode
- `Space` → Start selection (in copy mode)
- `Enter` → Copy selection (in copy mode)
- `]` → Paste copied text
- `q` → Quit copy mode

---

## 🔹 Configuration

### Custom Configuration File
Create or edit `~/.tmux.conf`:

```bash
# Change prefix key to Ctrl+a
unbind C-b
set -g prefix C-a

# Enable mouse mode
set -g mouse on

# Start window numbering at 1
set -g base-index 1

# Set easier window split keys
bind-key v split-window -h
bind-key h split-window -v

# Reload config file
bind r source-file ~/.tmux.conf \; display "Config reloaded!"
```

### Apply Configuration
```bash
# Reload config from within tmux
Ctrl+b r  # If you've added the bind r command above

# Or from terminal
tmux source-file ~/.tmux.conf
```

---

## 🔹 Advanced Usage

### Session Management
```bash
# Create a new session in detached mode
tmux new -s session_name -d

# Kill a specific session
tmux kill-session -t session_name

# Kill all sessions except the current one
tmux kill-session -a

# Kill all sessions
tmux kill-server
```

### Synchronized Panes
```bash
# Toggle synchronize-panes (type in one pane, commands go to all panes)
Ctrl+b :setw synchronize-panes
```

### Resizing Panes
Hold `Ctrl+b`, then press and hold an arrow key.

### Save and Restore Sessions
Using the tmux-resurrect plugin:
```bash
# Save session
Ctrl+b Ctrl+s

# Restore session
Ctrl+b Ctrl+r
```
