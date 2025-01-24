# AgentScript Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/cloudscript)](https://artifacthub.io/packages/search?repo=cloudscript)

O **AgentScript** é uma ferramenta desenvolvida pela Cloudscript que atua como um agente dentro do cluster Kubernetes do cliente. Ele coleta informações relevantes para gerar alertas personalizados e criar chamados automaticamente na plataforma **OpsScript**.

Este Helm Chart facilita a implantação do AgentScript, incluindo recursos essenciais como Deployment, Horizontal Pod Autoscaler (HPA) e ServiceAccount com permissões específicas para monitoramento do cluster.

## Instalação

### Pré-requisitos
- Kubernetes 1.27+
- Helm 3.0+

### Comando de Instalação
```bash
helm repo add cloudscript https://charts.cloudscript.com.br
helm repo update
helm install agent-script cloudscript/agent-script
```

Substitua `agents-cript` pelo nome desejado para sua instalação.

## Configuração

O comportamento do AgentScript pode ser personalizado via o arquivo `values.yaml`. Abaixo está a lista de valores configuráveis e suas descrições:

### Configuração Básica

| Parâmetro               | Descrição                                             | Valor Padrão                              |
|-------------------------|-------------------------------------------------------|-------------------------------------------|
| `replicaCount`         | Número de réplicas do deployment.                    | `1`                                       |
| `image.repository`     | Imagem Docker do AgentScript.                        | `jonathanschmittcs/cloudscript` |
| `image.pullPolicy`     | Política de pull da imagem.                          | `IfNotPresent`                            |
| `image.tag`            | Tag da imagem Docker.                                | `Chart appVersion`                        |
| `imagePullSecrets`     | Segredos para autenticação em registries privados.   | `[]`                                      |
| `envFromSecret.enabled`| Habilitar uso de secret para configurar variáveis.    | `false`                                   |
| `envFromSecret.secretName`| Nome do Secret com variáveis de ambiente.         | `""`                                      |
| `config.agentServerUrl`| URL do servidor do AgentScript.                      | `""`                                      |
| `config.agentId`       | Identificador único do agente.                       | `""`                                      |
| `config.agentToken`    | Token de autenticação do agente.                     | `""`                                      |

### ServiceAccount

| Parâmetro               | Descrição                                             | Valor Padrão                              |
|-------------------------|-------------------------------------------------------|-------------------------------------------|
| `serviceAccount.create`| Criar ServiceAccount automaticamente.                | `true`                                    |
| `serviceAccount.automount`| Automount de tokens de ServiceAccount.             | `true`                                    |
| `serviceAccount.annotations`| Anotações para a ServiceAccount.                  | `{}`                                      |
| `serviceAccount.name`  | Nome personalizado da ServiceAccount.                | `""`                                      |

### Autoscaling (HPA)

| Parâmetro                          | Descrição                                  | Valor Padrão |
|------------------------------------|--------------------------------------------|--------------|
| `autoscaling.enabled`             | Habilitar o autoscaling horizontal.        | `false`      |
| `autoscaling.minReplicas`         | Número mínimo de réplicas.                 | `1`          |
| `autoscaling.maxReplicas`         | Número máximo de réplicas.                 | `100`        |
| `autoscaling.targetCPUUtilizationPercentage` | Utilização alvo de CPU para escalonamento. | `80`         |

### Segurança e Recursos

| Parâmetro               | Descrição                                             | Valor Padrão |
|-------------------------|-------------------------------------------------------|--------------|
| `podSecurityContext`   | Contexto de segurança para os Pods.                  | `{}`         |
| `securityContext`      | Contexto de segurança para os containers.            | `{}`         |
| `resources`            | Configurações de recursos dos containers.            | `{}`         |

### Node Affinity e Tolerations

| Parâmetro               | Descrição                                             | Valor Padrão |
|-------------------------|-------------------------------------------------------|--------------|
| `nodeSelector`         | Seleção de nós para os Pods.                         | `{}`         |
| `tolerations`          | Tolerations para os Pods.                            | `[]`         |
| `affinity`             | Regras de afinidade para os Pods.                    | `{}`         |

## Atualização

Para atualizar o Chart após modificações nos valores, execute:
```bash
helm upgrade agent-script cloudscript/agent-script --values values.yaml
```

## Remoção

Para remover o deployment do AgentScript:
```bash
helm uninstall agent-script
```
Isso irá excluir todos os recursos criados pelo Chart.

## Notas Adicionais

- Certifique-se de configurar as permissões adequadas para a ServiceAccount, especialmente se `serviceAccount.create` estiver desabilitado.
- Para ambientes de produção, recomendamos configurar os recursos (`resources`) adequadamente para garantir estabilidade e performance.

Para mais informações, visite [Cloudscript Documentation](https://docs.cloudscript.com.br).

