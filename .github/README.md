# GitHub Actions Workflows

Este diretório contém os workflows de CI/CD para publicação automática dos Helm charts.

## Workflows

### 1. Release Charts (`release.yaml`)

**Trigger:** Push para branch `main` com mudanças em qualquer chart

**O que faz:**
- Detecta charts modificados
- Executa `helm lint` em cada chart
- Executa `helm dependency build`
- Cria um package (.tgz) do chart
- Cria uma GitHub Release com o package
- Gera e atualiza o `index.yaml` no branch `gh-pages`
- Calcula SHA256 de cada package
- Atualiza/cria `artifacthub-pkg.yml` com metadados
- Copia READMEs para o branch `gh-pages`
- Sincroniza com o repositório `cloudscript-technology.github.io`

**Saídas:**
- GitHub Release criada automaticamente
- Tag do chart (`<chart-name>-<version>`)
- Chart package disponível em `https://cloudscript-technology.github.io/helm-charts`
- Metadados atualizados no Artifact Hub

### 2. Lint and Test Charts (`lint-test.yaml`)

**Trigger:**
- Pull Requests com mudanças em charts
- Push para `main` com mudanças em charts

**O que faz:**
- Lista charts modificados
- Executa `helm lint` nos charts modificados
- Valida `Chart.yaml` e `values.yaml`
- Cria um cluster Kubernetes local (kind)
- Instala e testa cada chart modificado
- Verifica se READMEs estão atualizados (via helm-docs)

**Resultado:**
- ✅ PR pode ser merged se todos os checks passarem
- ❌ PR bloqueado se houver erros de lint ou instalação

## Configuração

### `ct.yaml`

Arquivo de configuração do `chart-testing` (ct):
- Define branch alvo (`main`)
- Lista repositórios de dependências
- Configura timeout e validações

### Scripts

#### `scripts/prepare-release.sh`

Script para preparar um release localmente antes de fazer push:

```bash
./.github/scripts/prepare-release.sh deploy-apps
```

**O que o script faz:**
1. Executa `helm lint`
2. Executa `helm dependency build`
3. Empacota o chart
4. Calcula SHA256
5. Mostra próximos passos

## Como Fazer um Release

### Opção 1: Automático (Recomendado)

1. Faça suas mudanças no chart
2. Aumente a versão no `Chart.yaml`:
   ```yaml
   version: 0.2.0  # Nova versão
   ```
3. Commit e push para `main`:
   ```bash
   git add .
   git commit -m "feat(deploy-apps): add new feature"
   git push origin main
   ```
4. O workflow `release.yaml` detecta automaticamente e:
   - Cria uma release
   - Publica o chart
   - Atualiza o Artifact Hub

### Opção 2: Manual (Teste Local Primeiro)

1. Teste localmente:
   ```bash
   ./.github/scripts/prepare-release.sh deploy-apps
   ```
2. Se tudo OK, commit e push:
   ```bash
   git add .
   git commit -m "feat(deploy-apps): add new feature"
   git push origin main
   ```

## Versionamento

Seguimos [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Mudanças incompatíveis com versões anteriores
- **MINOR** (0.1.0): Nova funcionalidade compatível com versões anteriores
- **PATCH** (0.0.1): Bug fixes compatíveis com versões anteriores

### Exemplos de Commits

```bash
# Nova funcionalidade (incrementa MINOR)
git commit -m "feat(deploy-apps): add autoscaling support"

# Bug fix (incrementa PATCH)
git commit -m "fix(deploy-apps): correct service selector labels"

# Breaking change (incrementa MAJOR)
git commit -m "feat(deploy-apps)!: change values.yaml structure

BREAKING CHANGE: apps array structure has changed"

# Documentação (não gera release)
git commit -m "docs(deploy-apps): update README with examples"
```

## URLs Importantes

- **Chart Repository:** https://cloudscript-technology.github.io/helm-charts
- **GitHub Releases:** https://github.com/cloudscript-technology/helm-charts/releases
- **Artifact Hub:** https://artifacthub.io/packages/search?org=cloudscript

## Artifact Hub

Cada chart deve ter um arquivo `artifacthub-pkg.yml` na raiz do chart com metadados:

```yaml
version: 0.1.0
name: deploy-apps
displayName: Deploy Apps
description: Chart description
keywords:
  - kubernetes
  - helm
maintainers:
  - name: Jonathan Schmitt
    email: jonathan.schmitt@cloudscript.com.br
```

O workflow atualiza automaticamente:
- `version`
- `digest` (SHA256)
- `createdAt`

## Troubleshooting

### Release não foi criada

**Possíveis causas:**
1. Versão no `Chart.yaml` não foi incrementada
2. Chart já existe com mesma versão
3. Erro no `helm lint`

**Solução:**
- Verifique os logs do workflow no GitHub Actions
- Incremente a versão no `Chart.yaml`
- Execute `helm lint` localmente

### Chart não aparece no index.yaml

**Possíveis causas:**
1. Branch `gh-pages` não existe
2. Permissões incorretas

**Solução:**
- Verifique se o branch `gh-pages` existe
- Verifique permissões do `GITHUB_TOKEN` no workflow

### Testes falhando no PR

**Possíveis causas:**
1. Sintaxe YAML inválida
2. Values.yaml não compatível com templates
3. Dependencies não resolvidas

**Solução:**
```bash
# Teste localmente
helm lint ./deploy-apps
helm template test ./deploy-apps --debug
helm install test ./deploy-apps --dry-run --debug
```

## Permissões Necessárias

O workflow precisa das seguintes permissões:

```yaml
permissions:
  contents: write    # Para criar releases e tags
  packages: write    # Para publicar packages
```

Estas permissões já estão configuradas nos workflows.
