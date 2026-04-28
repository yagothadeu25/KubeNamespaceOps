# 📦 KubeNamespaceOps

> Governança de namespaces Kubernetes orientada a GitOps para ambientes multi-cluster, com validação, padronização e provisionamento automatizado.

---

## 🚀 Visão Geral

O **KubeNamespaceOps** é uma abordagem orientada à plataforma para gerenciar namespaces Kubernetes em escala utilizando princípios de **GitOps**.

Ele fornece uma forma **centralizada, declarativa e automatizada** de:

- Gerenciar namespaces em múltiplos clusters  
- Aplicar padrões organizacionais (quotas, limites, labels)  
- Validar configurações antes do deploy  
- Eliminar erros manuais e inconsistências  
- Escalar o provisionamento de namespaces  

---

## 🎯 Principais Funcionalidades

- ✅ Workflow baseado em GitOps  
- ✅ Gerenciamento de namespaces multi-cluster  
- ✅ Geração automática de overlays com Kustomize  
- ✅ Validação de namespaces (DNS-1123, duplicidade, estrutura)  
- ✅ Aplicação automática de ResourceQuota e LimitRange  
- ✅ Estratégia de labels padronizada por cluster  
- ✅ Pipeline CI/CD com validação, dry-run e deploy  
- ✅ Arquitetura idempotente e escalável  

---

## 🧠 Arquitetura
namespaces-gitops/
├── namespaces.txt # Fonte única da verdade
├── base/ # Configuração padrão
├── overlays/ # Gerado por cluster/namespace
├── scripts/ # Automação (validação + geração)
└── .gitlab-ci.yml # Pipeline CI/CD

---

## 📄 Fonte de Verdade

Todos os namespaces são definidos em um único arquivo:

```txt
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
