# Quick Start Guide - GitHub Actions CI/CD

Este guia rápido mostra como começar a usar o sistema de CI/CD configurado para os Helm charts.

## 🚀 Primeiro Release

### 1. Teste localmente

```bash
# Lint do chart
make lint CHART=deploy-apps

# Testa renderização
make test CHART=deploy-apps

# Ou testa tudo
make pre-commit
```

### 2. Incremente a versão

```bash
# Usando o Makefile
make bump CHART=deploy-apps TYPE=patch

# Ou manualmente no Chart.yaml
# version: 0.1.0 -> 0.1.1
```

### 3. Commit e Push

```bash
git add .
git commit -m "feat(deploy-apps): add new feature"
git push origin main
```

### 4. Acompanhe o Workflow

Vá para: https://github.com/cloudscript-technology/helm-charts/actions

Você verá o workflow `Release Charts` em execução.

## 📋 Comandos Rápidos

```bash
# Ver todos os comandos disponíveis
make help

# Listar charts
make list-charts

# Lint todos os charts
make lint-all

# Preparar release (testa localmente antes de push)
make prepare-release CHART=deploy-apps
```

## 🔧 Configuração Inicial do GitHub

### Habilitar GitHub Actions

1. Vá em **Settings** → **Actions** → **General**
2. Em **Workflow permissions**, selecione:
   - ✅ Read and write permissions
   - ✅ Allow GitHub Actions to create and approve pull requests
3. Clique em **Save**

### Configurar GitHub Pages

1. Vá em **Settings** → **Pages**
2. Em **Source**, selecione:
   - **Deploy from a branch**
   - **Branch:** `gh-pages`
   - **Folder:** `/ (root)`
3. Clique em **Save**

**Nota:** O branch `gh-pages` será criado automaticamente no primeiro release.

## 📦 Estrutura de Versionamento

Usamos [Semantic Versioning](https://semver.org/):

- **PATCH** (0.0.X): Bug fixes
  ```bash
  make bump CHART=deploy-apps TYPE=patch
  # 0.1.0 -> 0.1.1
  ```

- **MINOR** (0.X.0): Nova funcionalidade compatível
  ```bash
  make bump CHART=deploy-apps TYPE=minor
  # 0.1.1 -> 0.2.0
  ```

- **MAJOR** (X.0.0): Breaking changes
  ```bash
  make bump CHART=deploy-apps TYPE=major
  # 0.2.0 -> 1.0.0
  ```

## 📝 Convenção de Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Nova funcionalidade
git commit -m "feat(deploy-apps): add autoscaling support"

# Bug fix
git commit -m "fix(deploy-apps): correct service selector"

# Breaking change
git commit -m "feat(deploy-apps)!: change values structure

BREAKING CHANGE: values.yaml structure has changed"

# Documentação
git commit -m "docs(deploy-apps): update README"

# Chore (não gera release)
git commit -m "chore(deploy-apps): update dependencies"
```

## 🧪 Testando Antes de Push

### Opção 1: Makefile

```bash
# Testa tudo
make pre-commit
```

### Opção 2: Manual

```bash
# Lint
helm lint ./deploy-apps

# Template
helm template test ./deploy-apps --debug

# Dry-run
helm install test ./deploy-apps --dry-run --debug
```

### Opção 3: Com Kind (Kubernetes local)

```bash
# Criar cluster
kind create cluster --name helm-test

# Instalar chart
helm install test ./deploy-apps -f deploy-apps/ci/test-values.yaml

# Ver recursos
kubectl get all

# Limpar
kind delete cluster --name helm-test
```

## 🔍 Verificando o Release

### 1. GitHub Release

Vá para: https://github.com/cloudscript-technology/helm-charts/releases

Você deve ver:
- ✅ Nova release criada
- ✅ Tag no formato `<chart-name>-<version>`
- ✅ Chart package (`.tgz`) anexado

### 2. GitHub Pages

Após alguns minutos:
- ✅ Branch `gh-pages` atualizado
- ✅ Chart disponível em: https://cloudscript-technology.github.io/helm-charts

### 3. Teste de Instalação

```bash
# Adicione o repositório
helm repo add cloudscript https://cloudscript-technology.github.io/helm-charts
helm repo update

# Procure o chart
helm search repo cloudscript/deploy-apps

# Instale
helm install my-release cloudscript/deploy-apps
```

## 🐛 Troubleshooting

### Workflow não executou

**Causa:** Path patterns não correspondem

**Solução:**
- Verifique se mudanças foram feitas em arquivos dentro do chart
- Path patterns em `release.yaml`:
  ```yaml
  paths:
    - 'deploy-apps/**'  # Deve corresponder ao diretório
  ```

### Release não foi criada

**Causa 1:** Versão não foi incrementada

**Solução:**
```bash
make bump CHART=deploy-apps TYPE=patch
```

**Causa 2:** Chart já existe com mesma versão

**Solução:**
```bash
# Verifique releases existentes
gh release list

# Incremente a versão
make bump CHART=deploy-apps TYPE=patch
```

### Erro de permissões

**Causa:** GitHub Actions sem permissões

**Solução:**
1. Settings → Actions → General
2. Workflow permissions → Read and write permissions
3. ✅ Allow GitHub Actions to create and approve pull requests

### Chart não aparece no repositório

**Causa:** Branch gh-pages não configurado

**Solução:**
1. Aguarde o primeiro workflow completar (cria o branch)
2. Settings → Pages → Selecione `gh-pages` branch
3. Aguarde alguns minutos para propagar

## 📚 Documentação Completa

- [.github/README.md](./.README.md) - Documentação completa do CI/CD
- [../CONTRIBUTING.md](../CONTRIBUTING.md) - Guia de contribuição
- [../README.md](../README.md) - README principal

## 💡 Dicas

### Preparar Release Localmente

```bash
# Prepara e mostra o que será enviado
make prepare-release CHART=deploy-apps

# Output mostra:
# - Versão do chart
# - SHA256 do package
# - Próximos passos
```

### Ver Mudanças Antes de Commitar

```bash
git status
git diff
```

### Fazer Release de Múltiplos Charts

```bash
# Incremente cada um
make bump CHART=deploy-apps TYPE=minor
make bump CHART=agent-script TYPE=patch

# Commit todos juntos
git add .
git commit -m "chore: release multiple charts"
git push origin main
```

## 🎯 Checklist de Release

- [ ] Mudanças testadas localmente (`make test`)
- [ ] Chart passa no lint (`make lint`)
- [ ] Versão incrementada (`make bump`)
- [ ] Commit message segue convenção
- [ ] README atualizado (se necessário)
- [ ] Breaking changes documentados (se aplicável)
- [ ] Push para main
- [ ] Workflow executou com sucesso
- [ ] Release criada no GitHub
- [ ] Chart disponível no repositório

## 🆘 Ajuda

- 📖 Leia a documentação completa: [.github/README.md](./.README.md)
- 🐛 Abra uma issue: https://github.com/cloudscript-technology/helm-charts/issues
- 📧 Contato: jonathan.schmitt@cloudscript.com.br
