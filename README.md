# Helm Charts - Cloudscript

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/cloudscript)](https://artifacthub.io/packages/search?repo=cloudscript)
[![Release Charts](https://github.com/cloudscript-technology/helm-charts/actions/workflows/release.yaml/badge.svg)](https://github.com/cloudscript-technology/helm-charts/actions/workflows/release.yaml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Welcome to the official **Cloudscript** Helm Charts repository! This repository centralizes all Helm Charts developed by Cloudscript, providing an easy and standardized way to deploy our tools and applications on Kubernetes clusters.

## 📦 Available Charts

| Chart | Description | Version | App Version |
|-------|-------------|---------|-------------|
| [agent-script](./agent-script) | Agent Script for Kubernetes automation | See Chart.yaml | See Chart.yaml |
| [deploy-apps](./deploy-apps) | Multi-app deployment (Deployment, StatefulSet, CronJob, Job) with External Secrets support | 0.1.0 | 1.0.0 |
| [dumpscript](./dumpscript) | Database backup automation with multiple schedulers | See Chart.yaml | See Chart.yaml |
| [k8s-monitoring-app](./k8s-monitoring-app) | Kubernetes cluster monitoring application | See Chart.yaml | See Chart.yaml |

## 🚀 Quick Start

### Adding the Repository

Add the Cloudscript Helm Charts repository:

```bash
helm repo add cloudscript https://cloudscript-technology.github.io/helm-charts
helm repo update
```

### Installing a Chart

Install a chart with default values:

```bash
helm install my-release cloudscript/<chart-name>
```

With custom values:

```bash
helm install my-release cloudscript/<chart-name> -f values.yaml
```

### Examples

#### Deploy-Apps Chart (Multi-Application)

```bash
# Create a values file
cat > my-values.yaml <<EOF
apps:
  - name: web-app
    enabled: true
    type: deployment
    image:
      repository: nginx
      tag: "1.21"
    service:
      enabled: true
      ports:
        - name: http
          port: 80
          targetPort: 80
    ingress:
      enabled: true
      hosts:
        - host: myapp.example.com
          paths:
            - path: /
              pathType: Prefix
EOF

# Install
helm install my-apps cloudscript/deploy-apps -f my-values.yaml
```

#### Agent-Script Chart

```bash
helm install agent cloudscript/agent-script \
  --set config.agentServerUrl=https://server.example.com \
  --set config.agentId=my-agent \
  --set config.agentToken=secret-token
```

### Upgrading a Release

```bash
helm upgrade my-release cloudscript/<chart-name> -f values.yaml
```

### Uninstalling

```bash
helm uninstall my-release
```

## 📋 Requirements

- **Kubernetes:** >= 1.27.0
- **Helm:** >= 3.0

### Optional Dependencies

Some charts may require:
- **External Secrets Operator** (for deploy-apps with external secrets)
- **Metrics Server** (for HPA in deploy-apps)
- **Ingress Controller** (for Ingress resources)

## 🏗️ Repository Structure

```
.
├── .github/
│   ├── workflows/          # GitHub Actions CI/CD
│   │   ├── release.yaml    # Automated chart releases
│   │   └── lint-test.yaml  # Chart validation and testing
│   ├── scripts/            # Helper scripts
│   └── README.md           # CI/CD documentation
├── agent-script/           # Chart: Agent Script
├── deploy-apps/            # Chart: Multi-app deployment
├── dumpscript/             # Chart: Database backups
├── k8s-monitoring-app/     # Chart: K8s monitoring
├── CONTRIBUTING.md         # Contribution guidelines
└── README.md              # This file
```

## 🔄 Automated Releases

This repository uses GitHub Actions for automated chart releases:

### When is a release created?

A new release is automatically created when:
1. Changes are pushed to `main` branch
2. A chart's `version` in `Chart.yaml` is incremented
3. The version doesn't already exist in the public repository
4. All CI checks pass (lint, test, install)

### What happens during release?

1. 🔍 **Detection:** Automatically detects which charts changed
2. 🧪 **Validation:** Chart is linted with `helm lint`
3. 📦 **Packaging:** Chart is packaged as `.tgz`
4. 🔐 **Checksums:** SHA256 is calculated
5. 🏷️ **Tagging:** Git tag is created (`<chart-name>-<version>`)
6. 📤 **Publishing:** Chart is published to `cloudscript-technology.github.io`
7. 📊 **Indexing:** `index.yaml` is updated
8. 📝 **Metadata:** Artifact Hub metadata is generated
9. 📋 **Release:** GitHub Release is created with package attached

### Making a Release

#### Option 1: Using Makefile (Recommended)

```bash
# 1. Make your changes
vim deploy-apps/values.yaml

# 2. Test locally
make lint CHART=deploy-apps
make test CHART=deploy-apps

# 3. Increment version
make bump CHART=deploy-apps TYPE=patch

# 4. Commit and push
git add .
git commit -m "feat(deploy-apps): add new feature"
git push origin main
```

#### Option 2: Manual

1. Make your changes to a chart
2. Increment version in `Chart.yaml`:
   ```yaml
   version: 0.2.0  # Increment this
   ```
3. Commit and push to `main`:
   ```bash
   git add .
   git commit -m "feat(chart-name): add new feature"
   git push origin main
   ```
4. GitHub Actions will automatically:
   - Create a GitHub Release in this repository
   - Publish the chart to `cloudscript-technology.github.io`
   - Update the Helm repository index

### Repository Architecture

```
helm-charts (source)           →   cloudscript-technology.github.io (public)
├── deploy-apps/                   └── helm-charts/
│   ├── Chart.yaml                     ├── index.yaml
│   ├── values.yaml                    ├── deploy-apps-0.1.0.tgz
│   └── templates/                     ├── deploy-apps-artifacthub.yml
└── ...                                └── ...
```

See [.github/README.md](./.github/README.md) and [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

## 🧪 Testing Charts Locally

### Lint a Chart

```bash
helm lint ./chart-name
```

### Render Templates

```bash
helm template test-release ./chart-name --debug
```

### Dry-Run Install

```bash
helm install test-release ./chart-name --dry-run --debug
```

### Install in Kind Cluster

```bash
# Create cluster
kind create cluster --name test

# Install chart
helm install test ./chart-name

# Verify
kubectl get all

# Cleanup
kind delete cluster --name test
```

## 🤝 Contributing

We welcome contributions! Please read our [CONTRIBUTING.md](./CONTRIBUTING.md) for:

- 📝 Chart structure guidelines
- 🔢 Versioning strategy (Semantic Versioning)
- ✅ PR checklist
- 🧪 Testing requirements
- 💬 Commit message conventions

### Quick Contribution Guide

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes and test locally
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   ```bash
   git commit -m "feat(chart-name): add new feature"
   ```
5. Push and open a Pull Request

## 📚 Documentation

Each chart has its own detailed README:

- [agent-script/README.md](./agent-script/README.md)
- [deploy-apps/README.md](./deploy-apps/README.md)
- [dumpscript/README.md](./dumpscript/README.md)
- [k8s-monitoring-app/README.md](./k8s-monitoring-app/README.md)

## 🔗 Useful Links

- **Chart Repository:** https://cloudscript-technology.github.io/helm-charts
- **Artifact Hub:** https://artifacthub.io/packages/search?org=cloudscript
- **GitHub Releases:** https://github.com/cloudscript-technology/helm-charts/releases
- **Cloudscript Website:** https://cloudscript.com.br

## 💬 Support

Need help?

- 📖 Check chart-specific README files
- 🐛 [Open an Issue](https://github.com/cloudscript-technology/helm-charts/issues)
- 📧 Contact: jonathan.schmitt@cloudscript.com.br

## 📄 License

All Helm Charts in this repository are licensed under [Apache-2.0](https://opensource.org/licenses/Apache-2.0).

---

**Developed with ❤️ by Cloudscript**