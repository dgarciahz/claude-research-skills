#!/usr/bin/env bash

input=$(cat)

# Parse all fields in one Python call (full path avoids non-interactive PATH issues — jq not installed)
parsed=$(echo "$input" | /c/Python314/python -c "
import sys, json
d = json.load(sys.stdin)
cw = d.get('context_window', {})
rl = d.get('rate_limits', {})
fh = rl.get('five_hour', {})
print(d.get('cwd', ''))
print(cw.get('used_percentage', ''))
print(fh.get('used_percentage', ''))
print(fh.get('resets_at', ''))
print(d.get('output_style', {}).get('name', ''))
" 2>/dev/null | tr -d '\r')

cwd=$(echo "$parsed" | sed -n '1p')
used_pct=$(echo "$parsed" | sed -n '2p')
quota_used_pct=$(echo "$parsed" | sed -n '3p')
quota_resets_at=$(echo "$parsed" | sed -n '4p')
output_style=$(echo "$parsed" | sed -n '5p')

# Convert Windows path to POSIX for Git Bash (C:\... -> /c/...)
if [[ "$cwd" =~ ^[A-Za-z]: ]]; then
  drive_letter=$(echo "${cwd:0:1}" | tr '[:upper:]' '[:lower:]')
  cwd="/${drive_letter}${cwd:2}"
  cwd="${cwd//\\//}"
fi

# Get git branch and remote repo name
git_branch=""
repo_name=""
if [ -n "$cwd" ]; then
  git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  remote_url=$(git -C "$cwd" remote get-url origin 2>/dev/null)
  if [ -n "$remote_url" ]; then
    repo_name=$(basename "$remote_url" .git)
  fi
fi

# ANSI color codes — use $'...' so variables hold real ESC chars, not literal \033
RESET=$'\033[0m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
BOLD=$'\033[1m'

# Build git branch segment
if [ -n "$git_branch" ]; then
  if [ -n "$repo_name" ]; then
    git_segment="${CYAN} ${repo_name}/${git_branch}${RESET}"
  else
    git_segment="${CYAN} ${git_branch}${RESET}"
  fi
else
  git_segment="${CYAN} no-git${RESET}"
fi

# Build context usage segment
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  if [ "$used_int" -ge 90 ] 2>/dev/null; then
    ctx_color="$RED"
  elif [ "$used_int" -ge 75 ] 2>/dev/null; then
    ctx_color="$YELLOW"
  else
    ctx_color="$GREEN"
  fi
  ctx_segment="${ctx_color}ctx_window: ${used_pct}%${RESET}"
else
  ctx_segment="${GREEN}ctx_window: -${RESET}"
fi

# Build quota segment (5h rate limit)
if [ -n "$quota_used_pct" ]; then
  q_int=${quota_used_pct%.*}
  if [ "$q_int" -ge 90 ] 2>/dev/null; then
    q_color="${BOLD}${RED}"
  elif [ "$q_int" -ge 75 ] 2>/dev/null; then
    q_color="$YELLOW"
  else
    q_color="$GREEN"
  fi
  # Formatear % con 1 decimal y hora de reset
  quota_fmt=$(/c/Python314/python -c "
import datetime
pct = float('${quota_used_pct}')
ts  = int('${quota_resets_at}') if '${quota_resets_at}' else 0
reset_str = datetime.datetime.fromtimestamp(ts).strftime('%H:%M') if ts else ''
print(f'{pct:.1f}%' + (f' (reset {reset_str})' if reset_str else ''))
" 2>/dev/null | tr -d '\r')
  quota_segment="${q_color}cuota_5h: ${quota_fmt}${RESET}"
else
  quota_segment="${GREEN}cuota_5h: -${RESET}"
fi

# Build output style segment
if [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
  style_segment="${CYAN}style: ${output_style}${RESET}"
  printf "%s\n" "${git_segment} | ${ctx_segment} | ${quota_segment} | ${style_segment}"
else
  printf "%s\n" "${git_segment} | ${ctx_segment} | ${quota_segment}"
fi
