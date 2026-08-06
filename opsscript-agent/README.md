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
| `config.clusterName` | Cluster name (`CLUSTER_NAME`) used in the heartbeat and as the cluster name in the OpsScript inventory (agent >= v1.0.4); empty falls back to autodetection | `""` |
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
| `alertmanagerIntegration.enabled` | Let the agent manage `PrometheusRule`/`AlertmanagerConfig` objects, confined to `targetNamespace` | `false` |
| `alertmanagerIntegration.targetNamespace` | Namespace where the agent may create/update/patch/delete `PrometheusRule`/`AlertmanagerConfig` | `monitoring` |
| `inventory.namespaces` | Allowlist of namespaces the agent may read workloads/PVCs from. Empty disables the inventory collector | `[]` |
| `inventory.clusterWide` | Opt-in: cluster-wide read instead of per-namespace, ignores `inventory.namespaces` | `false` |
| `inventory.metricsInterval` | Metrics sampling interval (`AGENT_METRICS_INTERVAL`); floor `1m` | `5m` |
| `inventory.prometheusUrl` | Override Prometheus URL instead of autodiscovery | `""` |
| `podSecurityContext` / `securityContext` | Secure defaults: non-root, read-only rootfs, no capabilities | see values.yaml |
| `resources` | Resource requests/limits | `{}` |
| `priorityClassName`, `nodeSelector`, `tolerations`, `affinity`, `podAnnotations`, `podLabels` | Scheduling/metadata | — |

## Security notes

- RBAC is read-only and least-privilege: `nodes` and `pods` (get/list) plus `configmaps` restricted by name (`aws-auth`, `cluster-info`). The agent has **no access to Secret contents** in your cluster.
- The container runs as non-root with a read-only root filesystem and all capabilities dropped.
- One replica only: collections are checkpointed server-side and the deployment uses the `Recreate` strategy to avoid duplicate collection during updates.

## Alertmanager integration (optional, off by default)

Lets the agent read Prometheus Operator CRs cluster-wide and manage (create/update/patch/delete) `PrometheusRule` and `AlertmanagerConfig` objects — but only inside **one namespace you choose**. This is used by the OpsScript UI to let you review and approve alert rules/routes suggested for your cluster; the agent never applies anything without your approval upstream.

> **Required Alertmanager settings (kube-prometheus-stack):** the managed
> `AlertmanagerConfig` (the OpsScript delivery route) is only honored if your
> Alertmanager selects it AND does not scope it to a single namespace:
>
> ```yaml
> alertmanager:
>   alertmanagerSpec:
>     alertmanagerConfigSelector:
>       matchLabels:
>         app.kubernetes.io/managed-by: opsscript-agent
>     # Default (OnNamespace) injects a namespace=<target> matcher into the
>     # route — alerts fired for workloads in OTHER namespaces would never
>     # reach OpsScript. "None" lets the route receive alerts cluster-wide.
>     alertmanagerConfigMatcherStrategy:
>       type: None
> ```

```yaml
alertmanagerIntegration:
  enabled: true
  targetNamespace: monitoring   # the only namespace the agent may write to
```

- Enabling it adds `monitoring.coreos.com` `get/list/watch` on `prometheusrules`, `alertmanagerconfigs`, `prometheuses`, `alertmanagers` to the existing cluster-wide `ClusterRole`, plus a `Role`/`RoleBinding` in `targetNamespace` granting `create/update/patch/delete` on `prometheusrules` and `alertmanagerconfigs` only.
- **The agent never reads or writes the `Secret` backing Alertmanager** (`alertmanager.yaml`), or any other Secret, regardless of this setting.
- Default is `false`: no extra RBAC is rendered until you opt in.

## Workload/PVC inventory (optional, off by default)

Lets the agent read workload objects (`Deployments`, `StatefulSets`, `DaemonSets`, `ReplicaSets`, `CronJobs`, `Jobs`, `Pods`, `PersistentVolumeClaims`, `HorizontalPodAutoscalers`) beyond the cluster/node inventory the agent always collects. **You control the blast radius**: list only the namespaces you want the agent to see.

```yaml
inventory:
  namespaces: ["default", "checkout", "payments"]  # empty = collector disabled
  clusterWide: false          # opt-in: ignore the allowlist, grant read on the whole cluster
  metricsInterval: "5m"       # sampling interval; floor is 1m
  prometheusUrl: ""           # leave empty for autodiscovery
```

- Non-empty `inventory.namespaces` renders a `Role`/`RoleBinding` **per listed namespace** with `get/list` on the resources above — no cluster-wide grant.
- `inventory.clusterWide: true` renders a single `ClusterRole`/`ClusterRoleBinding` instead, granting the same `get/list` access across the whole cluster; it **ignores** `inventory.namespaces`. Use only when you explicitly want full-cluster read access.
- Environment variables `INVENTORY_NAMESPACES` (comma-joined), `AGENT_METRICS_INTERVAL` and `PROMETHEUS_URL` are only set on the container when the corresponding value is non-empty.
- As with every other collector in this chart, **no Secret is ever read**.

## Graceful shutdown

On update, the `Recreate` strategy terminates the old pod before starting the new one. The agent handles `SIGTERM` cleanly: it drains in-flight cron jobs (bounded by `AGENT_CRON_STOP_TIMEOUT_SECONDS`, default 20s) and publishes a shutdown event before exiting. To keep this within the pod grace period:

- `terminationGracePeriodSeconds` defaults to `60`, leaving margin over the cron drain window plus the preStop sleep.
- `lifecycle.preStop` adds a short pause (default 10s) before `SIGTERM`, using the native `sleep` lifecycle action. This requires **Kubernetes >= 1.29**; the agent image is distroless/static and has no shell for an `exec`-based sleep. On clusters older than 1.29, set `lifecycle.preStop.enabled=false` (the grace period alone already covers the graceful drain).

`POD_NAME`, `POD_NAMESPACE` and `NODE_NAME` are injected via the downward API so the heartbeat can identify the running pod in the OpsScript fleet view; set `config.clusterName` to also report `CLUSTER_NAME`. Since agent v1.0.4, `CLUSTER_NAME` is also authoritative for the cluster name shown in the OpsScript inventory — without it the agent autodetects a name from node labels/providerID, which can degrade to an instance-id on spot nodes.
