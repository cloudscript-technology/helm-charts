# OpsScript Kubernetes Agent

The OpsScript Kubernetes Agent runs inside your Kubernetes cluster, collects data from the integrations you configure in [OpsScript](https://opsscript.io) (Elasticsearch, Kubernetes, Alertmanager webhooks) and ships it to the OpsScript platform, where alerts and tickets are created automatically.

The agent is provisioned from **OpsScript > Integrations > Kubernetes Agent**, which generates the `AGENT_ID` and `AGENT_TOKEN` used below. Integrations are configured in the OpsScript UI and hot-reloaded by the agent — no redeploy needed.

## Installing

Preferred: create the credentials Secret first, then install referencing it.

```bash
kubectl create namespace opsscript-agent
kubectl -n opsscript-agent create secret generic opsscript-agent-credentials \
  --from-literal=AGENT_ID=<id> --from-literal=AGENT_TOKEN=<token>

helm repo add cloudscript https://charts.cloudscript.com.br
helm install opsscript-agent cloudscript/opsscript-agent \
  --namespace opsscript-agent \
  --set credentials.existingSecret=opsscript-agent-credentials
```

Quick start alternative (token in values — avoid in GitOps repositories):

```bash
helm install opsscript-agent cloudscript/opsscript-agent \
  --namespace opsscript-agent --create-namespace \
  --set config.agentId=<id> \
  --set credentials.agentToken=<token>
```

## Values

| Key | Description | Default |
| --- | --- | --- |
| `replicaCount` | The agent is a singleton; keep at `1` (see values.yaml) | `1` |
| `image.repository` | Agent image | `public.ecr.aws/a3g9d1z6/opsscript-agent` |
| `image.tag` | Image tag | chart `appVersion` |
| `image.pullPolicy` | Pull policy | `IfNotPresent` |
| `config.agentServerUrl` | OpsScript agent server URL | `https://agent.opsscript.io` |
| `config.agentId` | Agent ID (optional when provided via `credentials.existingSecret`) | `""` |
| `config.logLevel` | `debug`/`info`/`warn`/`error` | `info` |
| `config.searchInterval` | Initial search window for pull collectors (seconds) | `60` |
| `config.reloadIntervalSeconds` | Config hot-reload interval (seconds, `0` disables) | `60` |
| `config.clusterName` | Optional cluster name reported with the heartbeat (`CLUSTER_NAME`); empty omits it | `""` |
| `terminationGracePeriodSeconds` | Seconds after SIGTERM before SIGKILL; covers the cron drain and shutdown event | `60` |
| `lifecycle.preStop.enabled` | Pause before SIGTERM (native `sleep` action, requires k8s >= 1.29) | `true` |
| `lifecycle.preStop.sleepSeconds` | preStop sleep duration; must be `< terminationGracePeriodSeconds` | `10` |
| `credentials.existingSecret` | **Preferred.** Existing Secret with keys `AGENT_TOKEN` (required) and `AGENT_ID` (optional) | `""` |
| `credentials.agentToken` | Alternative: chart creates the Secret from this value | `""` |
| `health.port` | Port of the always-on `/healthz` and `/readyz` endpoints | `8081` |
| `livenessProbe` / `readinessProbe` | Probes against the health endpoints (enabled by default) | see values.yaml |
| `webhooksServer.enabled` | Enable the push/webhook server (e.g. Alertmanager) | `false` |
| `webhooksServer.port` | Webhook server port | `8080` |
| `webhooksServer.alertmanagerPath` | Alertmanager endpoint path | `/webhooks/alertmanager` |
| `webhooksServer.service.*` | Service for the webhook server | `ClusterIP:8080` |
| `webhooksServer.ingress.*` | Ingress exposure (`className`, `hostname`, `path`, `tls`) | disabled |
| `webhooksServer.httpRoute.*` | Gateway API exposure (`parentRefs`, `hostnames`, `path`) | disabled |
| `extraEnv` / `extraEnvFrom` | Extra environment variables / sources (e.g. `ELASTIC_APM_*`) | `[]` |
| `serviceAccount.*` | ServiceAccount options | created |
| `rbac.create` | Create read-only ClusterRole/Binding for the Kubernetes collector | `true` |
| `rbac.extraRules` | Extra ClusterRole rules | `[]` |
| `podSecurityContext` / `securityContext` | Secure defaults: non-root, read-only rootfs, no capabilities | see values.yaml |
| `resources` | Resource requests/limits | `{}` |
| `priorityClassName`, `nodeSelector`, `tolerations`, `affinity`, `podAnnotations`, `podLabels` | Scheduling/metadata | — |

## Security notes

- RBAC is read-only and least-privilege: `nodes` and `pods` (get/list) plus `configmaps` restricted by name (`aws-auth`, `cluster-info`). The agent has **no access to Secret contents** in your cluster.
- The container runs as non-root with a read-only root filesystem and all capabilities dropped.
- One replica only: collections are checkpointed server-side and the deployment uses the `Recreate` strategy to avoid duplicate collection during updates.

## Graceful shutdown

On update, the `Recreate` strategy terminates the old pod before starting the new one. The agent handles `SIGTERM` cleanly: it drains in-flight cron jobs (bounded by `AGENT_CRON_STOP_TIMEOUT_SECONDS`, default 20s) and publishes a shutdown event before exiting. To keep this within the pod grace period:

- `terminationGracePeriodSeconds` defaults to `60`, leaving margin over the cron drain window plus the preStop sleep.
- `lifecycle.preStop` adds a short pause (default 10s) before `SIGTERM`, using the native `sleep` lifecycle action. This requires **Kubernetes >= 1.29**; the agent image is distroless/static and has no shell for an `exec`-based sleep. On clusters older than 1.29, set `lifecycle.preStop.enabled=false` (the grace period alone already covers the graceful drain).

`POD_NAME`, `POD_NAMESPACE` and `NODE_NAME` are injected via the downward API so the heartbeat can identify the running pod in the OpsScript fleet view; set `config.clusterName` to also report `CLUSTER_NAME`.
