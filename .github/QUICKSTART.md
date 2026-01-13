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

### Configurar Permissões para Repositório Público

O workflow precisa fazer push para o repositório `cloudscript-technology.github.io`.

**Opção 1: Usar GITHUB_TOKEN (Padrão)**

O workflow já está configurado para usar `GITHUB_TOKEN`. Por padrão, esse token tem acesso apenas ao repositório atual.

Para permitir acesso a outros repositórios da organização:
1. Vá em **Settings** → **Actions** → **General**
2. Em **Workflow permissions**, certifique-se de ter:
   - ✅ Read and write permissions

**Opção 2: Usar Personal Access Token (PAT)**

Se o `GITHUB_TOKEN` não tiver permissões suficientes:

1. Crie um PAT:
   - GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate new token (classic)
   - Selecione escopo: `repo` (full control)
   - Copie o token

2. Adicione como secret:
   - No repositório `helm-charts`
   - Settings → Secrets and variables → Actions
   - New repository secret
   - Name: `PAT_TOKEN`
   - Value: (cole o token)

3. Atualize o workflow `release.yaml`:
   ```yaml
   - name: Checkout cloudscript-technology.github.io repository
     uses: actions/checkout@v4
     with:
       repository: cloudscript-technology/cloudscript-technology.github.io
       token: ${{ secrets.PAT_TOKEN }}  # Altere de GITHUB_TOKEN para PAT_TOKEN
       path: gh-pages-repo
   ```

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

### 2. Repositório Público

Vá para: https://github.com/cloudscript-technology/cloudscript-technology.github.io

Verifique:
- ✅ Commit novo no repositório
- ✅ Diretório `helm-charts/` atualizado
- ✅ Arquivo `index.yaml` atualizado
- ✅ Package `.tgz` do chart presente

### 3. GitHub Pages

Após alguns minutos:
- ✅ Chart disponível em: https://cloudscript-technology.github.io

Verifique o index:
```bash
curl https://cloudscript-technology.github.io/index.yaml
```

### 4. Teste de Instalação

```bash
# Adicione o repositório
helm repo add cloudscript https://cloudscript-technology.github.io
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

**Causa 3:** Nenhuma mudança detectada no chart

**Verificar:**
```bash
# Veja o log do workflow
# Procure por: "Chart deploy-apps has changes"
# Se não aparecer, o git diff não detectou mudanças
```

### Erro de permissões

**Causa:** GitHub Actions sem permissões para push no repositório público

**Mensagens de erro típicas:**
```
remote: Permission to cloudscript-technology/cloudscript-technology.github.io.git denied
fatal: unable to access 'https://github.com/cloudscript-technology/cloudscript-technology.github.io/':
```

**Solução:**
1. Verifique se o `GITHUB_TOKEN` tem permissões:
   - Settings → Actions → General
   - Workflow permissions → Read and write permissions

2. Se não funcionar, crie um PAT (veja seção "Configurar Permissões" acima)

### Chart não aparece no repositório

**Causa 1:** Workflow falhou antes de fazer push

**Solução:**
- Verifique os logs completos do workflow
- Procure por erros nas etapas:
  - "Package and publish charts"
  - "Commit and push to public repository"

**Causa 2:** GitHub Pages não está habilitado

**Solução:**
1. No repositório `cloudscript-technology.github.io`
2. Settings → Pages
3. Source: Deploy from a branch
4. Branch: `main` (ou branch que você está usando)

### Workflow detecta mudanças mas não cria release

**Causa:** Versão não foi incrementada ou já existe

**O que você vê nos logs:**
```
Chart deploy-apps has changes
  Version 0.1.0 already exists, skipping
Will release: (nenhum chart)
```

**Solução:**
```bash
# Incremente a versão
make bump CHART=deploy-apps TYPE=patch

# Commit
git add deploy-apps/Chart.yaml
git commit -m "chore(deploy-apps): bump version to 0.1.1"
git push origin main
```

### Erro: helm lint falhou

**Causa:** Chart tem erros de sintaxe ou validação

**Solução:**
```bash
# Teste localmente
make lint CHART=deploy-apps

# Veja os erros detalhados
helm lint ./deploy-apps

# Corrija os erros e tente novamente
```

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

# O workflow detectará automaticamente ambos os charts
# e criará 2 releases separadas
```

### Verificar se Versão Existe no Repositório Público

```bash
# Via curl
curl -s https://cloudscript-technology.github.io/index.yaml | grep deploy-apps -A 10

# Via helm
helm repo add cloudscript https://cloudscript-technology.github.io
helm search repo cloudscript/deploy-apps --versions
```

### Testar Localmente com Valores Reais

```bash
# Use os valores de CI para testar
helm install test ./deploy-apps -f deploy-apps/ci/test-values.yaml --dry-run --debug

# Ou crie seus próprios valores de teste
cat > test-values.yaml <<EOF
apps:
  - name: test-app
    enabled: true
    type: deployment
    image:
      repository: nginx
      tag: latest
EOF

helm install test ./deploy-apps -f test-values.yaml --dry-run --debug
```

## 🎯 Checklist de Release

- [ ] Mudanças testadas localmente (`make test CHART=deploy-apps`)
- [ ] Chart passa no lint (`make lint CHART=deploy-apps`)
- [ ] Versão incrementada (`make bump CHART=deploy-apps TYPE=patch`)
- [ ] Commit message segue convenção
- [ ] README atualizado (se necessário)
- [ ] Breaking changes documentados (se aplicável)
- [ ] Push para main
- [ ] Workflow executou com sucesso
- [ ] Release criada no GitHub
- [ ] Chart disponível no repositório público
- [ ] Teste de instalação funciona

## 🆘 Ajuda

- 📖 Leia a documentação completa: [.github/README.md](./.README.md)
- 🐛 Abra uma issue: https://github.com/cloudscript-technology/helm-charts/issues
- 📧 Contato: jonathan.schmitt@cloudscript.com.br

## 🔗 Links Úteis

- **Chart Repository:** https://cloudscript-technology.github.io
- **Source Code:** https://github.com/cloudscript-technology/helm-charts
- **Public Repo:** https://github.com/cloudscript-technology/cloudscript-technology.github.io
- **Releases:** https://github.com/cloudscript-technology/helm-charts/releases
- **Workflows:** https://github.com/cloudscript-technology/helm-charts/actions
