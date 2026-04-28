📦 KubeNamespaceOps

Governança de namespaces Kubernetes orientada a GitOps para ambientes multi-cluster, com validação, padronização e provisionamento automatizado.

🚀 Visão Geral

O KubeNamespaceOps é uma abordagem orientada à plataforma para gerenciar namespaces Kubernetes em escala utilizando princípios de GitOps.

Ele fornece uma forma centralizada, declarativa e automatizada de:

Gerenciar namespaces em múltiplos clusters
Aplicar padrões organizacionais (quotas, limites, labels)
Validar configurações antes do deploy
Eliminar erros manuais e inconsistências
Escalar o provisionamento de namespaces
🎯 Principais Funcionalidades
✅ Workflow baseado em GitOps
✅ Gerenciamento de namespaces multi-cluster
✅ Geração automática de overlays com Kustomize
✅ Validação de namespaces (DNS-1123, duplicidade, estrutura)
✅ Aplicação automática de ResourceQuota e LimitRange
✅ Estratégia de labels padronizada por cluster
✅ Pipeline CI/CD com validação, dry-run e deploy
✅ Arquitetura idempotente e escalável
🧠 Arquitetura
namespaces-gitops/
├── namespaces.txt              # Fonte única da verdade
├── base/                      # Configuração padrão
├── overlays/                  # Gerado por cluster/namespace
├── scripts/                   # Automação (validação + geração)
└── .gitlab-ci.yml             # Pipeline CI/CD
📄 Fonte de Verdade

Todos os namespaces são definidos em um único arquivo:

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
⚙️ Como Funciona
1. Validação

Garante:

Clusters válidos
Namespaces no padrão DNS-1123
Sem duplicidade
Estrutura correta
bash scripts/validate-namespaces.sh
2. Geração de Overlays

Cria automaticamente a estrutura Kustomize:

bash scripts/generate-overlays.sh
3. Dry-Run

Valida no cluster (server-side):

kubectl apply -k overlays/<cluster>/<namespace> --dry-run=server
4. Deploy

Aplica os namespaces:

kubectl apply -k overlays/<cluster>/<namespace>
🔄 Pipeline CI/CD

O pipeline no GitLab inclui:

🔍 Validação
⚙️ Geração de overlays
🧪 Dry-run por cluster
🚀 Deploy controlado (dev → hml → prd)

Com:

Separação por contexto de cluster
Uso de kubeconfig via variável (base64)
Aprovação manual para produção
🛡️ Governança e Padrões

Cada namespace é criado automaticamente com:

ResourceQuota
LimitRange
Labels padronizadas

Exemplo:

labels:
  cluster: pagueveloz_dev
  namespace-name: payments-v1
  managed-by: kustomize
📈 Casos de Uso
Times de Platform Engineering
Padronização DevSecOps
Ambientes Kubernetes multi-cluster
Governança em ambientes corporativos
🛠️ Roadmap
 Integração com ArgoCD (GitOps completo)
 Policy enforcement (Kyverno / OPA)
 Templates de RBAC por namespace
 Perfis de quota (small / medium / large)
 CLI para self-service
 Observabilidade e detecção de drift
👨‍💻 Autor

Yago Martins
DevSecOps | Platform Engineering | Kubernetes | Multi-Cloud
