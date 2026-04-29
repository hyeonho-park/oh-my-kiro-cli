#!/usr/bin/env bash
set -euo pipefail

KIRO_HOME="${KIRO_HOME:-${HOME}/.kiro}"
META_FILE="${KIRO_HOME}/.oh-my-kiro-cli-meta"

quiet=0
for arg in "$@"; do
  case "$arg" in
    --quiet|-q) quiet=1 ;;
  esac
done

emit() { [ "$quiet" -eq 1 ] || echo "$1"; }
emit_err() { echo "$1" >&2; }

if [ ! -f "$META_FILE" ]; then
  emit_err "[doctor] not installed (meta file missing: $META_FILE)"
  exit 2
fi

PROJECT_ROOT="$(grep '^project_root=' "$META_FILE" | cut -d= -f2- || true)"
PROJECT_SHA="$(grep '^project_sha=' "$META_FILE" | cut -d= -f2- || true)"
INSTALL_MODE="$(grep '^install_mode=' "$META_FILE" | cut -d= -f2- || true)"

errors=0
warnings=0

if [ -z "$PROJECT_ROOT" ]; then
  emit "[doctor] WARN: meta has no project_root (legacy install; re-run ./install.sh to refresh)"
  warnings=$((warnings + 1))
elif [ ! -d "$PROJECT_ROOT" ]; then
  emit_err "[doctor] FAIL: project_root missing on disk: $PROJECT_ROOT"
  emit_err "[doctor] Fix: move the project back, or re-run ./install.sh from the new location"
  errors=$((errors + 1))
fi

if [ -d "$KIRO_HOME/skills" ]; then
  while IFS= read -r link; do
    if [ ! -e "$link" ]; then
      emit_err "[doctor] FAIL: dangling symlink: $link -> $(readlink "$link")"
      errors=$((errors + 1))
    fi
  done < <(find "$KIRO_HOME/skills" -maxdepth 1 -type l 2>/dev/null)
fi

if [ "$INSTALL_MODE" = "symlink" ] && [ -n "$PROJECT_SHA" ] && [ -d "${PROJECT_ROOT}/.git" ]; then
  current_sha="$(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || echo '')"
  if [ -n "$current_sha" ] && [ "$current_sha" != "$PROJECT_SHA" ]; then
    emit "[doctor] WARN: project is at $current_sha, installed from $PROJECT_SHA"
    emit "[doctor] Live skills reflect current checkout. Re-run ./install.sh to refresh meta."
    warnings=$((warnings + 1))
  fi
fi

emit "[doctor] errors=$errors warnings=$warnings"

if [ "$errors" -gt 0 ]; then
  exit 1
fi
exit 0
