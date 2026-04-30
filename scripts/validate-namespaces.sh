#!/bin/bash
set -euo pipefail

NAMESPACES_FILE="${1:-namespaces.txt}"
ERRORS=0
current_cluster=""

declare -A seen_per_cluster  # "cluster:ns" -> 1  (detecta duplicata dentro do cluster)

echo "🔍 Validando namespaces em '$NAMESPACES_FILE'..."
echo ""

# DNS-1123 label: lowercase, alfanumérico + hífen, max 63 chars, sem começar/terminar com hífen
dns1123_re='^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$'

line_number=0

while IFS= read -r line || [[ -n "$line" ]]; do
  line_number=$((line_number + 1))

  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  [[ -z "$line" || "$line" == \#* ]] && continue

  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    current_cluster="${BASH_REMATCH[1]}"
    continue
  fi

  ns="$line"

  # ── 1. Fora de seção de cluster ───────────────────────────────────────────
  if [[ -z "$current_cluster" ]]; then
    echo "❌ Linha $line_number: '$ns' está fora de uma seção [cluster]"
    ((ERRORS++))
    continue
  fi

  # ── 2. DNS-1123 ───────────────────────────────────────────────────────────
  if [[ ! "$ns" =~ $dns1123_re ]]; then
    if [[ ${#ns} -gt 63 ]]; then
      echo "❌ [$current_cluster] '$ns' — excede 63 caracteres (${#ns})"
    elif [[ "$ns" != "${ns,,}" ]]; then
      echo "❌ [$current_cluster] '$ns' — contém letras maiúsculas"
    elif [[ "$ns" =~ ^- || "$ns" =~ -$ ]]; then
      echo "❌ [$current_cluster] '$ns' — não pode começar ou terminar com hífen"
    else
      echo "❌ [$current_cluster] '$ns' — inválido (DNS-1123: minúsculas, alfanumérico e hífen)"
    fi
    ((ERRORS++))
  fi

  # ── 3. Duplicata no mesmo cluster ─────────────────────────────────────────
  key="${current_cluster}:${ns}"
  if [[ -n "${seen_per_cluster[$key]+_}" ]]; then
    echo "❌ [$current_cluster] '$ns' — duplicado no mesmo cluster"
    ((ERRORS++))
  else
    seen_per_cluster[$key]=1
  fi

done < "$NAMESPACES_FILE"

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo "✅ Todos os namespaces são válidos."
else
  echo "❌ $ERRORS erro(s) encontrado(s)."
  exit 1
fi
