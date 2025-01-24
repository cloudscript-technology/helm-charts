# Helm Charts - Cloudscript

Bem-vindo ao repositório oficial de Helm Charts da **Cloudscript**! Este repositório centraliza todos os charts desenvolvidos pela empresa, fornecendo uma maneira fácil e padronizada de implantar nossas ferramentas em clusters Kubernetes.

## Estrutura do Repositório

Cada diretório neste repositório representa um Helm Chart independente. A estrutura geral segue o seguinte padrão:

```
├── agentscript/       # Chart para o AgentScript
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── README.md
├── another-tool/      # Chart para outra ferramenta
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── README.md
└── ...
```

## Requisitos

- Kubernetes 1.20+
- Helm 3.0+

## Uso Geral

### Adicionando o Repositório

Adicione o repositório de Helm Charts da Cloudscript ao seu ambiente local:
```bash
helm repo add cloudscript https://charts.cloudscript.com.br
helm repo update
```

### Instalando um Chart

Escolha o diretório correspondente à ferramenta desejada e instale o Chart:
```bash
helm install <release-name> cloudscript/<chart-name>
```
Substitua `<release-name>` pelo nome de sua escolha para a instalação e `<chart-name>` pelo nome do Chart que deseja instalar.

### Atualizando um Chart

Para aplicar atualizações a uma instalação existente:
```bash
helm upgrade <release-name> cloudscript/<chart-name> --values values.yaml
```

### Removendo um Chart

Para desinstalar um Chart:
```bash
helm uninstall <release-name>
```

## Contribuindo

Contribuições são bem-vindas! Siga as diretrizes abaixo para contribuir com este repositório:

1. Faça um fork deste repositório.
2. Crie uma branch para sua contribuição:
   ```bash
   git checkout -b minha-contribuicao
   ```
3. Faça suas alterações e commit:
   ```bash
   git commit -m "Descrição clara das alterações"
   ```
4. Envie sua branch:
   ```bash
   git push origin minha-contribuicao
   ```
5. Abra um Pull Request explicando sua contribuição.

## Suporte

Se você encontrar problemas ou tiver dúvidas, sinta-se à vontade para abrir uma **issue** neste repositório ou entrar em contato com nosso suporte através do site oficial da Cloudscript: [https://www.cloudscript.com.br](https://www.cloudscript.com.br).

## Licença

Todos os Helm Charts neste repositório estão sob a licença **MIT**. Consulte o arquivo `LICENSE` para mais detalhes.

---

Obrigado por usar os Helm Charts da Cloudscript! 🚀