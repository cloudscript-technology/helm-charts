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
| `mcp.enabled` | When the command channel operates: `"auto"` (opens itself when the agent's config carries an MCP server), `false` (off), `true` (always on) | `"auto"` |
| `mcp.secretNamespaces` | Namespaces where the agent may read MCP tokens (`get` only, never `list`/`watch`). Empty = the release namespace | `[]` |
| `mcp.waitSeconds` | How long the server holds an empty poll open; keep below the idle timeout of anything between agent and platform | `25` |
| `mcp.concurrency` | How many commands the agent executes at once | `4` |
| `inventory.namespaces` | Allowlist of namespaces the agent may read workloads/PVCs from. Empty disables the inventory collector | `[]` |
| `inventory.clusterWide` | Opt-in: cluster-wide read instead of per-namespace, ignores `inventory.namespaces` | `false` |
| `inventory.metricsInterval` | Metrics sampling interval (`AGENT_METRICS_INTERVAL`); floor `1m` | `5m` |
| `inventory.prometheusUrl` | Override Prometheus URL instead of autodiscovery | `""` |
| `podSecurityContext` / `securityContext` | Secure defaults: non-root, read-only rootfs, no capabilities | see values.yaml |
| `resources` | Resource requests/limits | `{}` |
| `priorityClassName`, `nodeSelector`, `tolerations`, `affinity`, `podAnnotations`, `podLabels` | Scheduling/metadata | — |

## Security notes

- RBAC is read-only and least-privilege: `nodes` and `pods` (get/list) plus `configmaps` restricted by name (`aws-auth`, `cluster-info`).
- The agent has **no access to Secret contents**, with one opt-in exception: enabling [MCP via agent](#mcp-via-agent-optional-off-by-default) grants `get` on Secrets in the namespaces you list — never `list` or `watch` (so it cannot enumerate them), never cluster-wide. With `mcp.enabled: false` no Secret permission exists at all.
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

## MCP via agent (optional, off by default)

Lets the OpsScript AI use an MCP server that is reachable **only from inside this cluster** — the case when exposing it to the internet is not acceptable.

Instead of the platform calling the MCP server over the internet, it enqueues the call; this agent long-polls for work, executes it locally, and returns only the result.

```yaml
mcp:
  secretNamespaces:
    - observability      # onde estão os Secrets com os tokens dos MCP
```

**Não há o que ligar.** Em `"auto"` (padrão) o agente abre o canal sozinho quando a configuração que ele busca do OpsScript traz algum MCP server, e o fecha quando não há mais nenhum — sem redeploy. Registrar o servidor na tela basta.

`mcp.enabled: false` desliga de vez: é a decisão do dono do cluster e vence o que estiver configurado na plataforma. `true` mantém o canal aberto mesmo sem MCP, para tipos de comando que não dependem dele.

The MCP server's URL is **not** configured here: it is registered in OpsScript (Integrations > MCP Servers, "Pelo agente") and delivered to the agent as part of its configuration. The agent only ever calls servers present in that configuration, so nothing on the platform side can point it at an arbitrary address inside your network.

**About the token.** It stays in your cluster. The agent reads the Secret when it makes the call and uses the value as a request header; it is never sent to OpsScript, never stored there, and never appears in the command result or in the agent logs.

**About the permission.**

```
Role (never ClusterRole), one per namespace in mcp.secretNamespaces
  verb: get      — no list, no watch, so the agent cannot enumerate what is there
```

**Namespaces, not Secret names, on purpose.** One agent serves many MCP servers, each with its own credential, and the set changes whenever someone registers a server in OpsScript. Pinning names with `resourceNames` would mean a chart deploy — a GitOps PR and a sync — for every new credential, which defeats the self-service the UI offers.

The trade-off is explicit: inside a listed namespace the agent can read any Secret **whose name it is told** (it cannot list them). Point `mcp.secretNamespaces` at a namespace dedicated to MCP tokens, so the reach equals what the agent would need anyway — and do not list a namespace that also holds unrelated credentials. When a stricter, name-pinned grant is required, leave `mcp.secretNamespaces` empty and use `rbac.extraRules`.

You can verify it yourself after installing:

```bash
SA=system:serviceaccount:<release-namespace>:opsscript-agent
kubectl auth can-i get secret/mcp-token -n observability --as=$SA   # yes
kubectl auth can-i list secrets          -n observability --as=$SA   # no  (cannot enumerate)
kubectl auth can-i get secrets           -n kube-system   --as=$SA   # no
```

With `mcp.enabled: false` no `Role` is rendered at all.

**Requires agent v1.1.0 or newer** — the version that announces the `command.poll` and `mcp.call` capabilities in its heartbeat. OpsScript checks for the capabilities (not the version string, which is free-form) and refuses to save the MCP server otherwise, naming the agent and the reason.

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
