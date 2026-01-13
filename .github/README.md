# GitHub Actions Workflows

Este diretório contém os workflows de CI/CD para publicação automática dos Helm charts.

## Workflows

### 1. Release Charts (`release.yaml`)

**Trigger:** Push para branch `main` com mudanças em qualquer chart

**O que faz:**
- Detecta automaticamente charts modificados
- Verifica se a versão no `Chart.yaml` foi incrementada
- Executa `helm lint` em cada chart modificado
- Cria um package (.tgz) do chart
- Calcula SHA256 de cada package
- Publica charts no repositório `cloudscript-technology/cloudscript-technology.github.io`
- Atualiza o `index.yaml` do repositório Helm
- Cria GitHub Release com o package anexado
- Copia READMEs de cada chart
- Cria metadata para Artifact Hub

**Saídas:**
- GitHub Release criada automaticamente no repositório `helm-charts`
- Tag do chart (`<chart-name>-<version>`)
- Chart package disponível em `https://cloudscript-technology.github.io`
- `index.yaml` atualizado no repositório público
- Metadados para Artifact Hub

**Importante:** O workflow só cria release se:
1. O chart teve mudanças no commit
2. A versão no `Chart.yaml` foi incrementada
3. A versão ainda não existe no repositório público

### 2. Lint and Test Charts (`lint-test.yaml`)

**Trigger:**
- Pull Requests com mudanças em charts
- Push para `main` com mudanças em charts

**O que faz:**
- Lista charts modificados usando `chart-testing` (ct)
- Executa `helm lint` nos charts modificados
- Valida `Chart.yaml` e `values.yaml`
- Cria um cluster Kubernetes local (kind)
- Instala e testa cada chart modificado
- Valida que o chart pode ser instalado com sucesso

**Resultado:**
- ✅ PR pode ser merged se todos os checks passarem
- ❌ PR bloqueado se houver erros de lint ou instalação

## Arquitetura de Publicação

```
┌─────────────────────────────────────┐
│  helm-charts (código-fonte)         │
│  ├── deploy-apps/                   │
│  ├── agent-script/                  │
│  └── dumpscript/                    │
└─────────────────────────────────────┘
              │
              │ CI/CD (release.yaml)
              │ - Detecta mudanças
              │ - Cria packages
              │ - Atualiza index.yaml
              ▼
┌─────────────────────────────────────┐
│  cloudscript-technology.github.io   │
│  └── helm-charts/                   │
│      ├── index.yaml                 │
│      ├── deploy-apps-0.1.0.tgz      │
│      ├── deploy-apps/               │
│      │   └── README.md              │
│      └── ...                        │
└─────────────────────────────────────┘
              │
              │ GitHub Pages
              ▼
  https://cloudscript-technology.github.io/
```

## Configuração

### `ct.yaml`

Arquivo de configuração do `chart-testing` (ct):
- Define branch alvo (`main`)
- Lista repositórios de dependências (ex: bitnami)
- Configura timeout e validações

### Scripts

#### `scripts/bump-version.sh`

Script para incrementar a versão de um chart:

```bash
./.github/scripts/bump-version.sh deploy-apps patch
```

**Argumentos:**
- Chart name (obrigatório)
- Version type: `major`, `minor`, ou `patch` (padrão: `patch`)

**O que o script faz:**
1. Lê a versão atual do `Chart.yaml`
2. Incrementa conforme o tipo especificado
3. Atualiza o `Chart.yaml`
4. Mostra os próximos passos

#### `scripts/prepare-release.sh`

Script para preparar um release localmente antes de fazer push:

```bash
./.github/scripts/prepare-release.sh deploy-apps
```

**O que o script faz:**
1. Executa `helm lint`
2. Executa `helm dependency build` (se necessário)
3. Empacota o chart
4. Calcula SHA256
5. Mostra próximos passos

## Como Fazer um Release

### Opção 1: Usando Makefile (Recomendado)

```bash
# 1. Teste localmente
make lint CHART=deploy-apps
make test CHART=deploy-apps

# 2. Incremente a versão
make bump CHART=deploy-apps TYPE=patch

# 3. Commit e push
git add .
git commit -m "feat(deploy-apps): add new feature"
git push origin main
```

### Opção 2: Manual

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
   - Cria uma release no repositório `helm-charts`
   - Publica o chart em `cloudscript-technology.github.io`
   - Atualiza o `index.yaml`

### Opção 3: Teste Local Completo

```bash
# 1. Prepare o release
./.github/scripts/prepare-release.sh deploy-apps

# 2. Teste com Kind (opcional)
kind create cluster --name helm-test
helm install test ./deploy-apps
kubectl get all
kind delete cluster --name helm-test

# 3. Commit e push
git add .
git commit -m "feat(deploy-apps): add new feature"
git push origin main
```

## Versionamento

Seguimos [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Mudanças incompatíveis com versões anteriores
- **MINOR** (0.1.0): Nova funcionalidade compatível com versões anteriores
- **PATCH** (0.0.1): Bug fixes compatíveis com versões anteriores

### Uso do Makefile

```bash
# PATCH: 0.1.0 -> 0.1.1
make bump CHART=deploy-apps TYPE=patch

# MINOR: 0.1.1 -> 0.2.0
make bump CHART=deploy-apps TYPE=minor

# MAJOR: 0.2.0 -> 1.0.0
make bump CHART=deploy-apps TYPE=major
```

### Convenção de Commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Nova funcionalidade (incrementa MINOR)
git commit -m "feat(deploy-apps): add autoscaling support"

# Bug fix (incrementa PATCH)
git commit -m "fix(deploy-apps): correct service selector labels"

# Breaking change (incrementa MAJOR)
git commit -m "feat(deploy-apps)!: change values.yaml structure

BREAKING CHANGE: apps array structure has changed"

# Documentação (não gera release automaticamente)
git commit -m "docs(deploy-apps): update README with examples"

# Chore (não gera release automaticamente)
git commit -m "chore(deploy-apps): update dependencies"
```

## Detecção Inteligente de Mudanças

O workflow `release.yaml` detecta automaticamente quais charts precisam ser publicados:

### Critérios para Release

Um chart será publicado SE e SOMENTE SE:

1. ✅ O chart teve **mudanças no commit** atual
2. ✅ A versão no `Chart.yaml` foi **incrementada**
3. ✅ O package `.tgz` com essa versão **não existe** no repositório público

### Exemplos

**Cenário 1: Chart modificado com versão nova**
```bash
# Modifica deploy-apps e incrementa versão
vim deploy-apps/values.yaml
make bump CHART=deploy-apps TYPE=patch
git commit -m "feat(deploy-apps): add feature"
git push
# ✅ Release será criado
```

**Cenário 2: Chart modificado mas versão não incrementada**
```bash
# Modifica deploy-apps mas NÃO incrementa versão
vim deploy-apps/values.yaml
git commit -m "fix(deploy-apps): fix bug"
git push
# ❌ Release NÃO será criado (warning nos logs)
```

**Cenário 3: Múltiplos charts modificados**
```bash
# Modifica 2 charts
make bump CHART=deploy-apps TYPE=minor
make bump CHART=agent-script TYPE=patch
git commit -m "chore: update multiple charts"
git push
# ✅ 2 releases serão criados (um para cada chart)
```

**Cenário 4: Versão já existe**
```bash
# Tenta recriar uma versão que já foi publicada
make bump CHART=deploy-apps TYPE=patch  # versão 0.1.1
git push
# Reverte e tenta publicar 0.1.1 novamente
# ❌ Release NÃO será criado (versão já existe)
```

## URLs Importantes

- **Chart Repository:** https://cloudscript-technology.github.io
- **Repository Index:** https://cloudscript-technology.github.io/index.yaml
- **GitHub Releases:** https://github.com/cloudscript-technology/helm-charts/releases
- **Source Code:** https://github.com/cloudscript-technology/helm-charts
- **Public Repo:** https://github.com/cloudscript-technology/cloudscript-technology.github.io
- **Artifact Hub:** https://artifacthub.io/packages/search?org=cloudscript

## Artifact Hub

O workflow cria automaticamente metadata para o Artifact Hub:

**Gerado automaticamente:**
- `<chart-name>-artifacthub.yml` no repositório público
- Contém: version, digest (SHA256), createdAt, maintainers, etc.

**Cada chart também pode ter `artifacthub-pkg.yml` na raiz** (opcional):
```yaml
# deploy-apps/artifacthub-pkg.yml
displayName: Deploy Apps
category: integration-delivery
keywords:
  - deployment
  - statefulset
  - cronjob
links:
  - name: Documentation
    url: https://github.com/cloudscript-technology/helm-charts/tree/main/deploy-apps
```

## Troubleshooting

### Release não foi criada

**Possíveis causas:**
1. Versão no `Chart.yaml` não foi incrementada
2. Chart já existe com mesma versão no repositório público
3. Erro no `helm lint`
4. Nenhuma mudança detectada no chart

**Solução:**
```bash
# Verifique os logs do workflow no GitHub Actions
# Teste localmente:
helm lint ./deploy-apps

# Incremente a versão:
make bump CHART=deploy-apps TYPE=patch

# Verifique versões existentes:
curl -s https://cloudscript-technology.github.io/index.yaml | grep deploy-apps -A 5
```

### Chart não aparece no index.yaml

**Possíveis causas:**
1. Repositório `cloudscript-technology.github.io` não é acessível
2. Permissões incorretas no `GITHUB_TOKEN`
3. Workflow falhou durante o push

**Solução:**
- Verifique os logs completos do workflow
- Verifique se o commit apareceu em `cloudscript-technology.github.io`
- Verifique permissões: Settings → Actions → General → Workflow permissions

### Testes falhando no PR

**Possíveis causas:**
1. Sintaxe YAML inválida
2. Values.yaml não compatível com templates
3. Dependencies não resolvidas

**Solução:**
```bash
# Teste localmente com Makefile
make lint CHART=deploy-apps
make test CHART=deploy-apps

# Ou teste manualmente
helm lint ./deploy-apps
helm template test ./deploy-apps --debug
helm install test ./deploy-apps --dry-run --debug

# Teste instalação real com Kind
kind create cluster --name test
helm install test ./deploy-apps -f deploy-apps/ci/test-values.yaml
kubectl get all
kind delete cluster --name test
```

### Erro: "fatal: invalid reference: origin/gh-pages"

**Causa:** Mensagem antiga, não deve mais ocorrer

**Contexto:** O workflow anterior usava branch `gh-pages`, mas agora publica diretamente em `cloudscript-technology.github.io`. Se você ver esse erro, o workflow antigo ainda está rodando.

**Solução:** Certifique-se de estar usando a versão mais recente do `release.yaml`

### Workflow detecta mudanças mas não cria release

**Causa:** A versão no `Chart.yaml` não foi incrementada

**O que acontece:**
```
Chart deploy-apps has changes
  Version 0.1.0 already exists, skipping
Will release: (nenhum chart listado)
```

**Solução:**
```bash
make bump CHART=deploy-apps TYPE=patch
git add deploy-apps/Chart.yaml
git commit --amend --no-edit
git push --force-with-lease
```

## Permissões Necessárias

O workflow precisa das seguintes permissões:

```yaml
permissions:
  contents: write    # Para criar releases, tags, e fazer push para outro repo
  packages: write    # Para publicar packages
```

**Importante:** O `GITHUB_TOKEN` precisa ter acesso ao repositório `cloudscript-technology/cloudscript-technology.github.io`. Por padrão, o token tem acesso apenas ao repositório atual.

### Se o workflow falhar com erro de permissão

Você pode precisar criar um **Personal Access Token (PAT)** com permissão `repo` e adicionar como secret:

1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Selecione escopo: `repo` (full control)
4. Copie o token
5. No repositório `helm-charts`:
   - Settings → Secrets and variables → Actions
   - New repository secret
   - Name: `PAT_TOKEN`
   - Value: (cole o token)
6. Atualize o workflow para usar `${{ secrets.PAT_TOKEN }}` ao invés de `${{ secrets.GITHUB_TOKEN }}`

## Comandos Úteis

```bash
# Ver todos os comandos disponíveis
make help

# Listar charts disponíveis
make list-charts

# Lint todos os charts
make lint-all

# Testar todos os charts
make test-all

# Executar todos os checks (pre-commit)
make pre-commit

# Limpar arquivos temporários
make clean
```

## Fluxo Completo de Contribuição

```bash
# 1. Clone e crie branch
git checkout -b feature/add-new-feature

# 2. Faça suas mudanças
vim deploy-apps/values.yaml

# 3. Teste localmente
make lint CHART=deploy-apps
make test CHART=deploy-apps

# 4. Commit e push
git add .
git commit -m "feat(deploy-apps): add new feature"
git push origin feature/add-new-feature

# 5. Crie Pull Request
# - O workflow lint-test.yaml vai rodar automaticamente
# - Aguarde aprovação

# 6. Merge para main
# - Após merge, incremente a versão
git checkout main
git pull

# 7. Incremente versão e faça release
make bump CHART=deploy-apps TYPE=minor
git add deploy-apps/Chart.yaml
git commit -m "chore(deploy-apps): bump version to 0.2.0"
git push origin main

# 8. O workflow release.yaml publica automaticamente
# - Aguarde alguns minutos
# - Verifique em: https://github.com/cloudscript-technology/helm-charts/releases
```
