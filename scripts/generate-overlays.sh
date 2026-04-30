#!/bin/bash
set -euo pipefail

NAMESPACES_FILE="${1:-namespaces.txt}"
OVERLAYS_DIR="overlays"

# Perfis de recursos por tipo de cluster
load_profile() {
  local cluster="$1"
  case "$cluster" in
    *dev*)
      CPU_REQ="500m";  MEM_REQ="1Gi";  CPU_LIM="1";  MEM_LIM="2Gi";  PODS="10"
      CTR_CPU_DEF="200m"; CTR_MEM_DEF="128Mi"
      CTR_CPU_REQ="50m";  CTR_MEM_REQ="64Mi"
      CTR_CPU_MAX="500m"; CTR_MEM_MAX="1Gi"
      ;;
    *hml*)
      CPU_REQ="1";     MEM_REQ="2Gi";  CPU_LIM="2";  MEM_LIM="4Gi";  PODS="15"
      CTR_CPU_DEF="300m"; CTR_MEM_DEF="256Mi"
      CTR_CPU_REQ="100m"; CTR_MEM_REQ="128Mi"
      CTR_CPU_MAX="1";    CTR_MEM_MAX="2Gi"
      ;;
    *prd*)
      CPU_REQ="2";     MEM_REQ="4Gi";  CPU_LIM="4";  MEM_LIM="8Gi";  PODS="30"
      CTR_CPU_DEF="500m"; CTR_MEM_DEF="512Mi"
      CTR_CPU_REQ="100m"; CTR_MEM_REQ="128Mi"
      CTR_CPU_MAX="2";    CTR_MEM_MAX="4Gi"
      ;;
    *)
      CPU_REQ="1";     MEM_REQ="2Gi";  CPU_LIM="2";  MEM_LIM="4Gi";  PODS="15"
      CTR_CPU_DEF="300m"; CTR_MEM_DEF="256Mi"
      CTR_CPU_REQ="100m"; CTR_MEM_REQ="128Mi"
      CTR_CPU_MAX="1";    CTR_MEM_MAX="2Gi"
      ;;
  esac
}

echo "📦 Gerando overlays Kustomize..."

current_cluster=""
declare -A cluster_namespaces

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  [[ -z "$line" || "$line" == \#* ]] && continue

  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    current_cluster="${BASH_REMATCH[1]}"
    cluster_namespaces[$current_cluster]=""
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

  load_profile "$current_cluster"

  # ── kustomization.yaml ────────────────────────────────────────────────────
  cat > "$overlay_path/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${ns}

resources:
  - ../../../base
  - peer-authentication.yaml

patches:
  - path: patch-namespace.yaml
    target:
      kind: Namespace
  - path: patch-resourcequota.yaml
    target:
      kind: ResourceQuota
  - path: patch-limitrange.yaml
    target:
      kind: LimitRange

commonLabels:
  namespace-name: ${ns}
  cluster: ${current_cluster}
  managed-by: kustomize
  source: namespaces-gitops
EOF

  # ── patch-namespace.yaml (nome + label Istio) ─────────────────────────────
  cat > "$overlay_path/patch-namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${ns}
  labels:
    istio-injection: enabled
EOF

  # ── patch-resourcequota.yaml ──────────────────────────────────────────────
  cat > "$overlay_path/patch-resourcequota.yaml" <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
spec:
  hard:
    requests.cpu: "${CPU_REQ}"
    requests.memory: ${MEM_REQ}
    limits.cpu: "${CPU_LIM}"
    limits.memory: ${MEM_LIM}
    pods: "${PODS}"
EOF

  # ── patch-limitrange.yaml ─────────────────────────────────────────────────
  cat > "$overlay_path/patch-limitrange.yaml" <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
spec:
  limits:
    - type: Container
      default:
        cpu: ${CTR_CPU_DEF}
        memory: ${CTR_MEM_DEF}
      defaultRequest:
        cpu: ${CTR_CPU_REQ}
        memory: ${CTR_MEM_REQ}
      max:
        cpu: "${CTR_CPU_MAX}"
        memory: ${CTR_MEM_MAX}
EOF

  # ── peer-authentication.yaml (Istio mTLS STRICT) ──────────────────────────
  cat > "$overlay_path/peer-authentication.yaml" <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: ${ns}
spec:
  mtls:
    mode: STRICT
EOF

  # Acumula namespaces por cluster para gerar kustomization raiz
  if [[ -z "${cluster_namespaces[$current_cluster]}" ]]; then
    cluster_namespaces[$current_cluster]="$ns"
  else
    cluster_namespaces[$current_cluster]="${cluster_namespaces[$current_cluster]} $ns"
  fi

done < "$NAMESPACES_FILE"

# ── kustomization.yaml raiz por cluster (para ArgoCD / Flux) ─────────────────
echo ""
echo "📋 Gerando kustomization.yaml raiz por cluster..."

for cluster in "${!cluster_namespaces[@]}"; do
  root_kustomization="$OVERLAYS_DIR/$cluster/kustomization.yaml"

  {
    echo "apiVersion: kustomize.config.k8s.io/v1beta1"
    echo "kind: Kustomization"
    echo ""
    echo "resources:"
    for ns in ${cluster_namespaces[$cluster]}; do
      echo "  - ./$ns"
    done
  } > "$root_kustomization"

  echo "  → $root_kustomization"
done

echo ""
echo "✅ Overlays gerados com sucesso."
