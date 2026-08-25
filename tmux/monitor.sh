#!/usr/bin/env bash

SESSION="monitor"

# If session already exists, just attach to it.
if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux a -t "$SESSION"
    exit 0
fi

tmux new -d -s "$SESSION" \; \
  split-window -h -l '67%' \; \
  split-window -h -l '50%' \; \
  split-window -v -l '67%' \; \
  split-window -v -l '50%' \; \
  select-pane -L \; \
  split-window -v -l '50%' \; \
  send-keys -t "$SESSION:0.0" 'less ~/log/*/*php*.access*.log' C-m \; \
  send-keys -t "$SESSION:0.1" 'tail -f ~/log/*/*php*.access*.log' C-m \; \
  send-keys -t "$SESSION:0.2" 'tail -f ~/log/*/*nginx.access*.log | grep -E " (444|404|503)"' C-m \; \
  send-keys -t "$SESSION:0.3" 'tail -f ~/apps/**/storage/logs/*.log' C-m \; \
  send-keys -t "$SESSION:0.4" 'df -h' C-m \; \
  send-keys -t "$SESSION:0.5" 'htop' C-m \; \
  select-pane -t "$SESSION:0.0"

tmux a -t "$SESSION"