# K8s Monitoring App Helm Chart

Um Helm Chart para implantar o K8s Monitoring App em Kubernetes, com coleta automática de métricas de aplicações e recursos do cluster, autenticação via Google OAuth 2.0 e alertas opcionais via Slack.

## Description

O K8s Monitoring App é uma aplicação nativa de Kubernetes que coleta métricas (pods, CPU, memória, PVC, nós, health checks HTTP) e armazena em SQLite. A autenticação pode ser habilitada via Google OAuth 2.0 com restrição por domínio, e alertas podem ser enviados via Slack.

## Features

- ✅ Coleta automática de métricas com intervalo configurável
- ✅ Vários tipos de métricas: saúde HTTP, pods, CPU, memória, PVC e nós
- ✅ Monitoramento de conexões: Redis, PostgreSQL, MongoDB, MySQL e Kong
- ✅ Armazenamento em SQLite (arquivo)
- ✅ Autenticação Google OAuth 2.0 (restrição por domínio)
- ✅ RBAC e ServiceAccount opcionais
- ✅ Web UI com atualização automática

## Installation

### Prerequisites

- Kubernetes `>= 1.27`
- Helm `>= 3.0`
- `metrics-server` instalado no cluster
- Credenciais Google OAuth 2.0 (se autenticação estiver habilitada)

### Install the Chart

```bash
# Adicionar repositório (se aplicável)
helm repo add cloudscript https://charts.cloudscript.technology
helm repo update

# Instalar a partir do repositório
helm install k8s-monitoring-app cloudscript/k8s-monitoring-app -f values.yaml

# OU instalar localmente a partir do diretório do chart
helm install k8s-monitoring-app . -n monitoring --create-namespace
```

## Configuration

### Example values.yaml

```yaml
# Imagem
image:
  repository: ghcr.io/cloudscript-technology/k8s-monitoring-app
  pullPolicy: IfNotPresent
  tag: "" # usa appVersion do chart por padrão

# Configuração principal
config:
  environment: production
  port: 8080
  metrics:
    retentionDays: 30
    cleanupInterval: "0 2 * * *"
    collectionInterval: 60
  database:
    # Caminho do arquivo SQLite; monte um volume se desejar persistência
    path: "/data/k8s_monitoring.db"
  notifications:
    enabled: true
    dedupMinutes: 10
    slack:
      enabled: true
      webhook:
        # Defina url OU fromSecret
        url: ""
        fromSecret: "slack-webhook-url"
  oauth:
    google:
      redirectURL: "https://monitoring.example.com/auth/callback"
      allowedDomains: "example.com"
      # Defina clientID/clientSecret OU fromSecret
      clientID: ""
      clientSecret: ""
      fromSecret: "google-oauth-client-credentials"

# Service
service:
  type: ClusterIP
  # port: 8080 # opcional; padrão 8080

# Ingress
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: monitoring.example.com
      paths:
        - path: /
          pathType: Prefix
  tls: []

# RBAC
rbac:
  create: true

# Service Account
serviceAccount:
  create: true
  automount: true
  annotations: {}
  name: ""
  namespace: monitoring

# Pod
podAnnotations: {}
podLabels: {}
podSecurityContext: {}
securityContext: {}
resources: {}
nodeSelector: {}
tolerations: []
affinity: {}
```

## Kubernetes Secrets

### Secret para Slack Webhook

```bash
kubectl -n monitoring create secret generic slack-webhook-url \
  --from-literal=url="https://hooks.slack.com/services/XXXX/XXXX/XXXX"
```

### Secret para Google OAuth

```bash
kubectl -n monitoring create secret generic google-oauth-client-credentials \
  --from-literal=clientID="1234567890.apps.googleusercontent.com" \
  --from-literal=clientSecret="XXXXXXXXXXXXXXXXXXXXXXXX"
```

## Storage and Volumes

O aplicativo usa SQLite (`DB_PATH`). Para persistência, monte um PVC em um caminho (ex.: `/data`) e aponte `config.database.path` para esse local. Este chart não cria PVC automaticamente.

## Configuration Parameters

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Docker image repository | `ghcr.io/cloudscript-technology/k8s-monitoring-app` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag | `""` (usa `appVersion`) |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full chart name | `""` |

### Application Configuration (`config`)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.environment` | Ambiente da aplicação | `production` |
| `config.port` | Porta HTTP do container | `8080` |
| `config.metrics.retentionDays` | Retenção de métricas (dias) | `1` |
| `config.metrics.cleanupInterval` | Cron de limpeza | `0 2 * * *` |
| `config.metrics.collectionInterval` | Intervalo de coleta (s) | `5` |
| `config.database.path` | Caminho do arquivo SQLite | `""` |

### Notifications

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.notifications.enabled` | Habilitar notificações | `true` |
| `config.notifications.dedupMinutes` | Deduplicação (min) | `10` |
| `config.notifications.slack.enabled` | Habilitar Slack | `true` |
| `config.notifications.slack.webhook.url` | URL Webhook do Slack | `""` |
| `config.notifications.slack.webhook.fromSecret` | Secret com `url` | `""` |

### OAuth (Google)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.oauth.google.redirectURL` | URL de callback | `""` |
| `config.oauth.google.allowedDomains` | Domínios permitidos | `""` |
| `config.oauth.google.clientID` | Client ID | `""` |
| `config.oauth.google.clientSecret` | Client Secret | `""` |
| `config.oauth.google.fromSecret` | Secret com credenciais | `""` |

### Service Account & RBAC

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rbac.create` | Criar RBAC | `true` |
| `serviceAccount.create` | Criar ServiceAccount | `true` |
| `serviceAccount.automount` | Automount token | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `serviceAccount.namespace` | Service account namespace | `""` |

### Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Tipo do Service | `ClusterIP` |
| `service.port` | Porta do Service | `8080` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Habilitar Ingress | `false` |
| `ingress.className` | Classe do Ingress | `""` |
| `ingress.annotations` | Anotações | `{}` |
| `ingress.hosts[].host` | Host | `chart-example.local` |
| `ingress.hosts[].paths[].path` | Caminho | `/` |
| `ingress.hosts[].paths[].pathType` | Tipo | `Prefix` |
| `ingress.tls` | TLS | `[]` |

### Pod Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podAnnotations` | Pod annotations | `{}` |
| `podLabels` | Pod labels | `{}` |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |
| `resources` | Resource requests and limits | `{}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |

## Usage Examples

### Instalação com OAuth, Slack e Ingress

```yaml
config:
  environment: production
  metrics:
    retentionDays: 30
    cleanupInterval: "0 2 * * *"
    collectionInterval: 60
  database:
    path: "/data/k8s_monitoring.db"
  notifications:
    enabled: true
    dedupMinutes: 10
    slack:
      enabled: true
      webhook:
        fromSecret: "slack-webhook-url"
  oauth:
    google:
      redirectURL: "https://monitoring.example.com/auth/callback"
      allowedDomains: "example.com"
      fromSecret: "google-oauth-client-credentials"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: monitoring.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Acesso ao UI via port-forward

```bash
kubectl -n monitoring port-forward svc/k8s-monitoring-app 8080:8080
open http://localhost:8080
```

## Image Compatibility

- `image.repository`: `ghcr.io/cloudscript-technology/k8s-monitoring-app`
- `image.tag`: usa `.Chart.AppVersion` por padrão (ex.: `v0.0.1`)
- `image.pullPolicy`: `IfNotPresent`

## Notes

- Certifique‑se de ter o `metrics-server` funcional para métricas de CPU/memória.
- Ajuste `config.metrics.collectionInterval` conforme sua necessidade.
- Habilite Ingress para expor o UI externamente, ou use `kubectl port-forward` para acesso local.

