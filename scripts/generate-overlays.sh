#!/bin/bash
set -euo pipefail

NAMESPACES_FILE="${1:-namespaces.txt}"
OVERLAYS_DIR="overlays"

echo "📦 Gerando overlays Kustomize..."

current_cluster=""

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  [[ -z "$line" || "$line" == \#* ]] && continue

  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    current_cluster="${BASH_REMATCH[1]}"
    echo "🔧 Cluster: $current_cluster"
    continue
  fi

  if [[ -z "$current_cluster" ]]; then
    echo "⚠️  Namespace '$line' ignorado — fora de uma seção de cluster" >&2
    continue
  fi

  ns="$line"
  overlay_path="$OVERLAYS_DIR/$current_cluster/$ns"

  echo "  → $current_cluster/$ns"

  mkdir -p "$overlay_path"

  cat > "$overlay_path/patch-namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${ns}
EOF

  cat > "$overlay_path/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${ns}

resources:
  - ../../../base

patches:
  - path: patch-namespace.yaml
    target:
      kind: Namespace

commonLabels:
  namespace-name: ${ns}
  cluster: ${current_cluster}
  managed-by: kustomize
  source: namespaces-gitops
EOF

done < "$NAMESPACES_FILE"

echo "✅ Overlays gerados com sucesso."
