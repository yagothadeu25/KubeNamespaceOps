# KubeNamespaceOps

> Governança de namespaces Kubernetes orientada a GitOps para ambientes multi-cluster, com validação, padronização e provisionamento automatizado.

---

## Visão Geral

O **KubeNamespaceOps** é uma plataforma GitOps para gerenciar namespaces Kubernetes em escala. A fonte de verdade é um único arquivo (`namespaces.txt`) que define todos os namespaces por cluster. A partir dele, scripts geram os manifests Kustomize e uma pipeline GitHub Actions valida, gera e distribui os overlays para repositórios separados por cluster.

```
namespaces.txt  →  validate  →  generate overlays  →  push por cluster-repo
```

---

## Funcionalidades

- Workflow GitOps com fonte única de verdade
- Suporte a múltiplos clusters (dev, hml, prd)
- Geração automática de overlays Kustomize por cluster
- Validação de namespaces: DNS-1123, duplicatas e estrutura
- ResourceQuota e LimitRange aplicados automaticamente
- Labels padronizados por cluster e namespace
- Pipeline CI/CD: validação → geração → push para repos separados
- Arquitetura idempotente: re-executar sempre produz o mesmo resultado

---

## Estrutura do Repositório

```
KubeNamespaceOps/
├── namespaces.txt              # Fonte única de verdade
├── base/
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── resourcequota.yaml
│   └── limitrange.yaml
├── scripts/
│   ├── validate-namespaces.sh  # Validação DNS-1123 + duplicatas
│   └── generate-overlays.sh    # Geração de overlays por cluster
└── .github/
    └── workflows/
        └── pipeline.yml        # CI/CD: validate → generate → push
```

Os overlays gerados **não são versionados** neste repositório — eles são enviados para repos dedicados por cluster:

| Cluster | Repositório de destino |
|---|---|
| cluster_dev | `cluster-dev-namespaces` |
| cluster_hml | `cluster-hml-namespaces` |
| cluster_prd | `cluster-prd-namespaces` |

---

## Fonte de Verdade

Todos os namespaces são declarados em `namespaces.txt` usando seções por cluster:

```
[cluster_dev]
payments-v1
orders-v1
auth-v1

[cluster_hml]
payments-v1
orders-v1

[cluster_prd]
payments-v1
orders-v1
auth-v1
```

Regras de validação aplicadas:
- Nome em minúsculas, alfanumérico e hífen (DNS-1123)
- Máximo de 63 caracteres
- Não pode começar ou terminar com hífen
- Sem duplicatas no mesmo cluster

---

## Pipeline CI/CD

O arquivo `.github/workflows/pipeline.yml` define 3 jobs em sequência:

```
validate  →  generate  →  push-clusters (matrix: dev | hml | prd)
```

| Job | Gatilho | O que faz |
|---|---|---|
| `validate` | PR + push em `main` | Executa `validate-namespaces.sh` |
| `generate` | PR + push em `main` | Executa `generate-overlays.sh`, salva artefato |
| `push-clusters` | Apenas push em `main` | Envia overlays para os repos de cluster via matrix |

Em **Pull Requests**, apenas `validate` e `generate` rodam (dry-run). O push para os clusters só acontece no merge em `main`.

---

## Configuração Inicial

### 1. Repositórios de cluster

Crie os 3 repositórios no GitHub (públicos ou privados):

```
<seu-usuario>/cluster-dev-namespaces
<seu-usuario>/cluster-hml-namespaces
<seu-usuario>/cluster-prd-namespaces
```

### 2. Secret GH_PAT

Gere um **Personal Access Token clássico** com escopo `repo` em:
**GitHub → Settings → Developer Settings → Personal access tokens → Tokens (classic)**

Adicione como secret no repositório **KubeNamespaceOps**:
**Settings → Secrets and variables → Actions → New repository secret**

- **Name:** `GH_PAT`
- **Value:** o token gerado

### 3. Execução local

```bash
# Validar namespaces
bash scripts/validate-namespaces.sh

# Gerar overlays localmente
bash scripts/generate-overlays.sh
```

---

## Overlay Gerado (exemplo)

Para o namespace `payments-v1` no `cluster_dev`, a pipeline gera:

**`kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: payments-v1

resources:
  - ../../../base

patches:
  - path: patch-namespace.yaml
    target:
      kind: Namespace

commonLabels:
  namespace-name: payments-v1
  cluster: cluster_dev
  managed-by: kustomize
  source: namespaces-gitops
```

**`patch-namespace.yaml`**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: payments-v1
```

---

## Como adicionar um novo namespace

1. Edite `namespaces.txt` e adicione o nome na seção do cluster desejado
2. Abra um Pull Request — a pipeline valida e gera os overlays (dry-run)
3. Após o merge em `main`, os overlays são enviados automaticamente para o repo do cluster
