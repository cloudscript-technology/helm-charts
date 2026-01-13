# deploy-apps

Helm chart flexível para deploy de múltiplas aplicações (Deployment, StatefulSet, CronJob, Job) com suporte a External Secrets Operator.

## Características

- **Multi-aplicação**: Deploy múltiplas aplicações em um único chart
- **Workload Types**: Suporte para Deployment, StatefulSet, CronJob e Job
- **External Secrets**: Integração com External Secrets Operator para gerenciamento seguro de secrets
- **Native Secrets**: Suporte também para secrets nativos do Kubernetes
- **RBAC Flexível**: ServiceAccount e RBAC global ou per-app
- **Probes**: Configuração completa de liveness, readiness e startup probes
- **Networking**: Service e Ingress configuráveis por aplicação
- **Persistence**: Suporte a PersistentVolumeClaims e volumeClaimTemplates
- **Autoscaling**: HorizontalPodAutoscaler para Deployments e StatefulSets

## Pré-requisitos

- Kubernetes >= 1.27
- Helm 3.x
- External Secrets Operator (opcional, apenas se usar external secrets)

## Instalação

### Adicionar o repositório Helm

```bash
helm repo add cloudscript https://charts.cloudscript.com.br
helm repo update
```

### Instalar o chart

```bash
helm install my-apps cloudscript/deploy-apps -f values.yaml
```

### Instalar de um arquivo local

```bash
helm install my-apps ./deploy-apps -f values.yaml
```

## Estrutura de Configuração

O chart usa uma estrutura baseada em array para definir múltiplas aplicações:

```yaml
apps:
  - name: app-name
    enabled: true
    type: deployment  # deployment, statefulset, cronjob, job
    # ... configurações específicas da aplicação
```

## Exemplos

### Exemplo 1: Deployment Simples com Ingress

```yaml
apps:
  - name: web-app
    enabled: true
    type: deployment
    replicaCount: 2

    image:
      repository: nginx
      tag: "1.21"
      pullPolicy: IfNotPresent

    ports:
      - name: http
        containerPort: 80
        protocol: TCP

    service:
      enabled: true
      type: ClusterIP
      ports:
        - name: http
          port: 80
          targetPort: http

    ingress:
      enabled: true
      className: nginx
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
      hosts:
        - host: myapp.example.com
          paths:
            - path: /
              pathType: Prefix
              portName: http
      tls:
        - secretName: myapp-tls
          hosts:
            - myapp.example.com

    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi

    livenessProbe:
      httpGet:
        path: /healthz
        port: http
      initialDelaySeconds: 30
      periodSeconds: 10

    readinessProbe:
      httpGet:
        path: /ready
        port: http
      initialDelaySeconds: 5
      periodSeconds: 10
```

### Exemplo 2: CronJob com External Secrets

```yaml
apps:
  - name: backup-job
    enabled: true
    type: cronjob
    schedule: "0 2 * * *"  # Todo dia às 2h da manhã

    successfulJobsHistoryLimit: 3
    failedJobsHistoryLimit: 1
    concurrencyPolicy: Forbid

    image:
      repository: backup-tool
      tag: latest

    command: ["/bin/sh"]
    args:
      - "-c"
      - |
        echo "Starting backup..."
        # Comandos de backup aqui
        echo "Backup completed"

    secrets:
      external:
        enabled: true
        items:
          - name: aws-credentials
            secretStoreRef:
              name: aws-secret-store
              kind: SecretStore
            refreshInterval: 1h
            data:
              - secretKey: AWS_ACCESS_KEY_ID
                remoteRef:
                  key: prod/backup/aws
                  property: accessKeyId
              - secretKey: AWS_SECRET_ACCESS_KEY
                remoteRef:
                  key: prod/backup/aws
                  property: secretAccessKey

    envFrom:
      - secretRef:
          name: my-apps-backup-job-aws-credentials

    resources:
      limits:
        cpu: 1000m
        memory: 1Gi
      requests:
        cpu: 500m
        memory: 512Mi
```

### Exemplo 3: StatefulSet com Persistence

```yaml
apps:
  - name: database
    enabled: true
    type: statefulset
    replicaCount: 3

    image:
      repository: postgres
      tag: "14-alpine"

    serviceName: database-headless
    podManagementPolicy: OrderedReady

    ports:
      - name: postgresql
        containerPort: 5432
        protocol: TCP

    env:
      - name: POSTGRES_DB
        value: mydb
      - name: PGDATA
        value: /var/lib/postgresql/data/pgdata

    secrets:
      native:
        enabled: true
        items:
          - name: db-creds
            type: Opaque
            stringData:
              POSTGRES_USER: admin
              POSTGRES_PASSWORD: changeme

    envFrom:
      - secretRef:
          name: my-apps-database-db-creds

    livenessProbe:
      exec:
        command:
          - /bin/sh
          - -c
          - pg_isready -U postgres
      initialDelaySeconds: 30
      periodSeconds: 10

    readinessProbe:
      exec:
        command:
          - /bin/sh
          - -c
          - pg_isready -U postgres
      initialDelaySeconds: 5
      periodSeconds: 10

    service:
      enabled: true
      type: ClusterIP
      clusterIP: None  # Headless service
      ports:
        - name: postgresql
          port: 5432
          targetPort: postgresql

    volumeClaimTemplates:
      - metadata:
          name: data
        spec:
          accessModes:
            - ReadWriteOnce
          storageClassName: fast-ssd
          resources:
            requests:
              storage: 50Gi

    volumeMounts:
      - name: data
        mountPath: /var/lib/postgresql/data

    resources:
      limits:
        cpu: 2000m
        memory: 4Gi
      requests:
        cpu: 1000m
        memory: 2Gi
```

### Exemplo 4: Multi-App (Deployment + CronJob)

```yaml
apps:
  # Frontend Application with Autoscaling
  - name: frontend
    enabled: true
    type: deployment
    # NÃO definir replicaCount quando autoscaling está habilitado

    image:
      repository: mycompany/frontend
      tag: v1.2.3

    ports:
      - name: http
        containerPort: 3000

    # Resources são necessários para HPA funcionar
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi

    service:
      enabled: true
      ports:
        - name: http
          port: 80
          targetPort: 3000

    ingress:
      enabled: true
      className: nginx
      hosts:
        - host: app.example.com
          paths:
            - path: /
              pathType: Prefix

    # Autoscaling habilitado
    autoscaling:
      enabled: true
      minReplicas: 3
      maxReplicas: 10
      targetCPUUtilizationPercentage: 70
      targetMemoryUtilizationPercentage: 80

  # Background Job
  - name: data-sync
    enabled: true
    type: cronjob
    schedule: "*/30 * * * *"  # A cada 30 minutos

    image:
      repository: mycompany/data-sync
      tag: v1.0.0

    command: ["python"]
    args: ["sync_data.py"]

    secrets:
      external:
        enabled: true
        items:
          - name: api-keys
            secretStoreRef:
              name: aws-secret-store
            data:
              - secretKey: API_KEY
                remoteRef:
                  key: prod/api/keys
                  property: key

    resources:
      limits:
        cpu: 500m
        memory: 512Mi
```

## Configuração de Secrets

### External Secrets Operator

Para usar External Secrets, primeiro crie um SecretStore ou ClusterSecretStore:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secret-store
  namespace: default
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: aws-credentials
            key: access-key-id
          secretAccessKeySecretRef:
            name: aws-credentials
            key: secret-access-key
```

Então configure no values.yaml:

```yaml
apps:
  - name: myapp
    secrets:
      external:
        enabled: true
        items:
          - name: app-secrets
            secretStoreRef:
              name: aws-secret-store
              kind: SecretStore
            data:
              - secretKey: DB_PASSWORD
                remoteRef:
                  key: prod/myapp/database
                  property: password
```

### Native Secrets

Para secrets nativos:

```yaml
apps:
  - name: myapp
    secrets:
      native:
        enabled: true
        items:
          - name: app-secrets
            type: Opaque
            stringData:
              DB_HOST: postgres.example.com
              DB_USER: myuser
              DB_PASSWORD: mypassword
```

### Referência a Secrets Existentes

```yaml
apps:
  - name: myapp
    secrets:
      existing:
        - name: existing-secret-name
    envFrom:
      - secretRef:
          name: existing-secret-name
```

## Labels Customizadas

O chart suporta dois tipos de labels customizadas por aplicação:

### App Labels (aplicadas a TODOS os recursos)

Labels definidas em `apps[].labels` são aplicadas a **todos os recursos** da aplicação (Deployment, Service, Ingress, PVC, ServiceAccount, etc.):

```yaml
apps:
  - name: myapp
    labels:
      team: platform
      cost-center: engineering
      environment: production
```

Essas labels aparecerão em:
- Deployment/StatefulSet/CronJob/Job metadata
- Service metadata
- Ingress metadata
- PVC metadata
- Pod labels (além das podLabels)

### Pod Labels (aplicadas APENAS aos pods)

Labels definidas em `apps[].podLabels` são aplicadas **apenas aos pods**:

```yaml
apps:
  - name: myapp
    podLabels:
      version: v1.2.3
      release: stable
      commit-sha: abc123
```

Essas labels aparecem apenas nas labels dos pods, úteis para:
- Versionamento específico do pod
- Informações de build/release
- Labels que não fazem sentido em Services ou Ingress

### Exemplo Completo

```yaml
apps:
  - name: myapp
    # Labels em todos os recursos
    labels:
      team: platform
      cost-center: engineering

    # Labels apenas nos pods
    podLabels:
      version: v1.2.3
      git-commit: abc123
```

## RBAC

### RBAC Global (Compartilhado)

```yaml
serviceAccount:
  create: true
  name: my-apps-sa

rbac:
  create: true
  useClusterRole: true
  rules:
    - apiGroups: [""]
      resources: ["pods"]
      verbs: ["get", "list", "watch"]
```

### RBAC Per-App

```yaml
apps:
  - name: myapp
    serviceAccount:
      create: true
      name: myapp-sa
    rbac:
      create: true
      useClusterRole: false
      rules:
        - apiGroups: [""]
          resources: ["configmaps"]
          verbs: ["get", "list"]
```

## Autoscaling

O chart suporta HorizontalPodAutoscaler (HPA) para Deployments e StatefulSets.

### Autoscaling Básico

```yaml
apps:
  - name: myapp
    type: deployment

    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 10
      targetCPUUtilizationPercentage: 70
      targetMemoryUtilizationPercentage: 80
```

### Autoscaling com Métricas Customizadas

```yaml
apps:
  - name: myapp
    type: deployment

    autoscaling:
      enabled: true
      minReplicas: 3
      maxReplicas: 50

      # Métricas padrão
      targetCPUUtilizationPercentage: 70

      # Métricas customizadas
      customMetrics:
        - type: Pods
          pods:
            metric:
              name: http_requests_per_second
            target:
              type: AverageValue
              averageValue: "1000"

        - type: External
          external:
            metric:
              name: sqs_queue_length
              selector:
                matchLabels:
                  queue: my-queue
            target:
              type: Value
              value: "100"
```

### Autoscaling com Políticas de Comportamento

Controle fino sobre como o HPA escala para cima e para baixo:

```yaml
apps:
  - name: myapp
    type: deployment

    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 20
      targetCPUUtilizationPercentage: 70

      behavior:
        # Políticas de scale down (mais conservador)
        scaleDown:
          stabilizationWindowSeconds: 300  # Espera 5 min antes de reduzir
          policies:
            - type: Percent
              value: 50        # Reduz no máximo 50% dos pods
              periodSeconds: 15
            - type: Pods
              value: 2         # Ou no máximo 2 pods
              periodSeconds: 60
          selectPolicy: Min    # Usa a política mais conservadora

        # Políticas de scale up (mais agressivo)
        scaleUp:
          stabilizationWindowSeconds: 0    # Escala imediatamente
          policies:
            - type: Percent
              value: 100       # Dobra o número de pods
              periodSeconds: 15
            - type: Pods
              value: 4         # Ou adiciona 4 pods
              periodSeconds: 15
          selectPolicy: Max    # Usa a política mais agressiva
```

### Importante sobre Autoscaling

1. **Desabilite replicaCount fixo**: Quando `autoscaling.enabled: true`, o HPA gerencia as réplicas automaticamente
2. **Métricas necessárias**: Para usar CPU/Memory metrics, é necessário ter Metrics Server instalado no cluster
3. **Apenas para Deployment/StatefulSet**: CronJob e Job não suportam autoscaling
4. **Custom Metrics**: Requer adaptadores de métricas (ex: Prometheus Adapter, Datadog, etc.)

## Valores Configuráveis

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `image.repository` | Repository da imagem global | `""` |
| `image.tag` | Tag da imagem global | `""` |
| `image.pullPolicy` | Pull policy global | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets globais | `[]` |
| `serviceAccount.create` | Criar ServiceAccount global | `true` |
| `rbac.create` | Criar RBAC global | `false` |
| `apps` | Array de aplicações | `[]` |

### Parâmetros por Aplicação

| Parâmetro | Descrição | Obrigatório |
|-----------|-----------|-------------|
| `apps[].name` | Nome da aplicação | Sim |
| `apps[].enabled` | Habilitar aplicação | Sim |
| `apps[].type` | Tipo: deployment/statefulset/cronjob/job | Sim |
| `apps[].image.repository` | Repository da imagem | Não |
| `apps[].image.tag` | Tag da imagem | Não |
| `apps[].replicaCount` | Número de réplicas | Não (padrão: 1) |
| `apps[].ports` | Portas do container | Não |
| `apps[].env` | Variáveis de ambiente | Não |
| `apps[].service.enabled` | Criar Service | Não (auto para deployment/statefulset) |
| `apps[].ingress.enabled` | Criar Ingress | Não (padrão: false) |
| `apps[].autoscaling.enabled` | Habilitar HPA | Não (padrão: false) |
| `apps[].autoscaling.minReplicas` | Réplicas mínimas | Não (padrão: 1) |
| `apps[].autoscaling.maxReplicas` | Réplicas máximas | Não (padrão: 10) |
| `apps[].autoscaling.targetCPUUtilizationPercentage` | Target CPU % | Não |
| `apps[].autoscaling.targetMemoryUtilizationPercentage` | Target Memory % | Não |
| `apps[].autoscaling.behavior` | Políticas de scaling | Não |
| `apps[].labels` | Labels em todos os recursos | Não |
| `apps[].podLabels` | Labels apenas nos pods | Não |

Para lista completa, veja [values.yaml](values.yaml).

## Desinstalação

```bash
helm uninstall my-apps
```

## Troubleshooting

### Ver recursos criados

```bash
kubectl get all -l app.kubernetes.io/instance=my-apps
```

### Ver logs de uma aplicação

```bash
kubectl logs -l deploy-apps/app-name=myapp --tail=100
```

### Verificar External Secrets

```bash
kubectl get externalsecrets
kubectl describe externalsecret my-apps-myapp-credentials
```

### Debug do template

```bash
helm template my-apps ./deploy-apps -f values.yaml --debug
```

## Contribuindo

Contribuições são bem-vindas! Por favor, abra uma issue ou pull request.

## Licença

Apache-2.0

## Maintainers

- Jonathan Schmitt <jonathan.schmitt@cloudscript.com.br>

## Links

- [Cloudscript](https://cloudscript.com.br)
- [External Secrets Operator](https://external-secrets.io)
