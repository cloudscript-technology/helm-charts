# Helm Charts - Cloudscript

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/cloudscript)](https://artifacthub.io/packages/search?repo=cloudscript)

Welcome to the official **Cloudscript** Helm Charts repository! This repository centralizes all Helm Charts developed by the company, providing an easy and standardized way to deploy our tools on Kubernetes clusters.

## Repository Structure

Each directory in this repository represents an independent Helm Chart. The general structure follows this pattern:

```
├── agentscript/       # Chart for AgentScript
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── README.md
├── another-tool/      # Chart for another tool
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── README.md
└── ...
```

## Requirements

- Kubernetes 1.20+
- Helm 3.0+

## General Usage

### Adding the Repository

Add the Cloudscript Helm Charts repository to your local environment:
```bash
helm repo add cloudscript https://charts.cloudscript.com.br
helm repo update
```

### Installing a Chart

Choose the directory corresponding to the desired tool and install the Chart:
```bash
helm install <release-name> cloudscript/<chart-name>
```
Replace `<release-name>` with your chosen name for the installation and `<chart-name>` with the name of the Chart you want to install.

### Updating a Chart

To apply updates to an existing installation:
```bash
helm upgrade <release-name> cloudscript/<chart-name> --values values.yaml
```

### Removing a Chart

To uninstall a Chart:
```bash
helm uninstall <release-name>
```

## Contributing

Contributions are welcome! Follow the guidelines below to contribute to this repository:

1. Fork this repository.
2. Create a branch for your contribution:
   ```bash
   git checkout -b my-contribution
   ```
3. Make your changes and commit:
   ```bash
   git commit -m "Clear description of changes"
   ```
4. Push your branch:
   ```bash
   git push origin my-contribution
   ```
5. Open a Pull Request explaining your contribution.

## Support

If you encounter issues or have questions, feel free to open an **issue** in this repository or contact our support team via the official Cloudscript website: [https://www.cloudscript.com.br](https://www.cloudscript.com.br).

## License

All Helm Charts in this repository are licensed under the **MIT** license. Refer to the `LICENSE` file for more details.

---

Thank you for using Cloudscript Helm Charts! 🚀