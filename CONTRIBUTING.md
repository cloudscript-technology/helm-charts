# Contributing to Cloudscript Helm Charts

Obrigado por contribuir com os Helm charts da Cloudscript! Este guia ajudará você a preparar e submeter suas contribuições.

## Antes de Começar

1. Fork o repositório
2. Clone seu fork localmente
3. Crie uma branch para suas mudanças

```bash
git clone https://github.com/SEU-USUARIO/helm-charts.git
cd helm-charts
git checkout -b feature/minha-feature
```

## Estrutura de um Chart

Cada chart deve seguir esta estrutura:

```
chart-name/
├── Chart.yaml              # Metadados do chart
├── values.yaml             # Valores padrão
├── values.schema.json      # Schema de validação
├── README.md               # Documentação
├── .helmignore            # Arquivos a ignorar
├── artifacthub-pkg.yml    # Metadados do Artifact Hub
└── templates/
    ├── _helpers.tpl       # Template helpers
    ├── NOTES.txt          # Notas pós-instalação
    └── *.yaml             # Templates dos recursos
```

## Checklist para Contribuições

### 1. Chart.yaml

Certifique-se de que o `Chart.yaml` contém:

```yaml
apiVersion: v2
name: chart-name
description: Descrição clara do chart
type: application
version: 0.1.0              # Versão do chart (semantic versioning)
appVersion: "1.0.0"         # Versão da aplicação
kubeVersion: ">= 1.27.0-0"  # Versão mínima do Kubernetes
home: https://cloudscript.com.br
keywords:
  - kubernetes
  - helm
maintainers:
  - name: Seu Nome
    email: seu.email@cloudscript.com.br
```

### 2. values.yaml

- Use comentários para documentar cada campo
- Forneça valores padrão sensatos
- Agrupe configurações relacionadas
- Use snake_case ou camelCase consistentemente

```yaml
# Exemplo de boa documentação
image:
  # Repository da imagem Docker
  repository: nginx
  # Pull policy (Always, IfNotPresent, Never)
  pullPolicy: IfNotPresent
  # Tag da imagem (padrão: Chart.AppVersion)
  tag: ""
```

### 3. values.schema.json

Adicione validação para parâmetros críticos:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["image"],
  "properties": {
    "image": {
      "type": "object",
      "required": ["repository"],
      "properties": {
        "repository": {
          "type": "string",
          "minLength": 1
        }
      }
    }
  }
}
```

### 4. README.md

O README deve incluir:

- Descrição do chart
- Características principais
- Pré-requisitos
- Instruções de instalação
- Exemplos de configuração
- Tabela de parâmetros
- Troubleshooting

### 5. Templates

**Boas práticas:**

- Use `_helpers.tpl` para lógica reutilizável
- Sempre use labels recomendados do Kubernetes
- Suporte customização através de values
- Valide entradas críticas
- Use `{{- if }}` para recursos opcionais
- Documente templates complexos

**Labels padrão:**

```yaml
labels:
  helm.sh/chart: {{ include "chart.chart" . }}
  app.kubernetes.io/name: {{ include "chart.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
```

### 6. Testes

Antes de submeter, execute:

```bash
# Lint do chart
helm lint ./chart-name

# Validar renderização
helm template test ./chart-name --debug

# Dry-run install
helm install test ./chart-name --dry-run --debug

# Testar com values customizados
helm template test ./chart-name -f test-values.yaml
```

## Versionamento

Seguimos [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Mudanças incompatíveis
  - Remoção de campos do values.yaml
  - Mudança de estrutura de templates
  - Alteração de comportamento padrão

- **MINOR** (0.1.0): Nova funcionalidade compatível
  - Novos recursos opcionais
  - Novos templates
  - Novos campos no values.yaml

- **PATCH** (0.0.1): Bug fixes
  - Correções de bugs
  - Melhorias de documentação
  - Ajustes de valores padrão

### Quando Incrementar a Versão

**Sempre incremente a versão quando:**
- Modificar qualquer arquivo `.yaml` em `templates/`
- Modificar `Chart.yaml` (exceto descrição)
- Modificar `values.yaml` com mudanças que afetam comportamento
- Adicionar ou remover dependências

**Não precisa incrementar para:**
- Mudanças apenas no `README.md`
- Mudanças em comentários no `values.yaml`
- Melhorias em `NOTES.txt`

## Processo de Pull Request

### 1. Prepare seu PR

```bash
# Certifique-se de estar atualizado com main
git fetch upstream
git rebase upstream/main

# Teste localmente
helm lint ./chart-name
helm template test ./chart-name

# Commit suas mudanças
git add .
git commit -m "feat(chart-name): adiciona nova funcionalidade"
git push origin feature/minha-feature
```

### 2. Mensagens de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Nova funcionalidade
feat(chart-name): adiciona suporte a autoscaling

# Bug fix
fix(chart-name): corrige selector do service

# Breaking change
feat(chart-name)!: muda estrutura do values.yaml

BREAKING CHANGE: Campo 'image' agora é um objeto

# Documentação
docs(chart-name): atualiza README com exemplos

# Testes
test(chart-name): adiciona testes de integração

# Refactoring
refactor(chart-name): melhora estrutura de templates
```

### 3. Descrição do PR

Inclua no PR:

- **O que mudou:** Descrição clara das mudanças
- **Por que:** Motivação e contexto
- **Como testar:** Passos para validar as mudanças
- **Breaking changes:** Se aplicável
- **Screenshots:** Se mudanças visuais (NOTES.txt, etc.)

**Template:**

```markdown
## Descrição

Adiciona suporte a HorizontalPodAutoscaler para o chart deploy-apps.

## Motivação

Permitir que usuários configurem autoscaling facilmente sem criar recursos separados.

## Mudanças

- Adiciona template `hpa.yaml`
- Adiciona seção `autoscaling` no values.yaml
- Atualiza README com exemplos de autoscaling
- Adiciona testes para HPA

## Como testar

```bash
helm template test ./deploy-apps -f test-values.yaml
kubectl apply -f output.yaml --dry-run=client
```

## Checklist

- [x] Chart.yaml versão incrementada
- [x] README.md atualizado
- [x] helm lint passou
- [x] helm template funciona
- [x] Testes adicionados
- [x] Breaking changes documentados (se aplicável)
```

## CI/CD

Os seguintes checks são executados automaticamente:

### Em Pull Requests

1. **Lint Charts** - `helm lint` em charts modificados
2. **Validate Templates** - `helm template` para validar renderização
3. **Install Charts** - Instala em cluster kind para validar
4. **Check README** - Verifica se README está atualizado

### Em Push para Main

1. Todos os checks acima
2. **Create Release** - Cria release automática se versão mudou
3. **Publish Chart** - Publica no repositório Helm
4. **Update Index** - Atualiza index.yaml
5. **Update Artifact Hub** - Sincroniza metadados

## Dependências

Se seu chart tem dependências:

### Chart.yaml

```yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

### Atualizar dependências

```bash
helm dependency update ./chart-name
```

Isso cria `Chart.lock` e baixa charts em `charts/`.

**Importante:** Sempre commit `Chart.lock` mas **não** commit `charts/` directory.

### .helmignore

Adicione ao `.helmignore`:

```
charts/
*.tgz
```

## Testes Avançados

### Com Kind (Kubernetes in Docker)

```bash
# Criar cluster
kind create cluster --name helm-test

# Instalar chart
helm install test ./chart-name

# Verificar recursos
kubectl get all

# Limpar
kind delete cluster --name helm-test
```

### Com values diferentes

Crie arquivos de teste:

```bash
# test-values/minimal.yaml
image:
  repository: nginx
  tag: latest

# test-values/full.yaml
image:
  repository: nginx
  tag: latest
replicaCount: 3
autoscaling:
  enabled: true
  maxReplicas: 10
```

Teste com cada um:

```bash
helm template test ./chart-name -f test-values/minimal.yaml
helm template test ./chart-name -f test-values/full.yaml
```

## Debugging

### Ver template renderizado

```bash
helm template test ./chart-name --debug
```

### Ver valores computados

```bash
helm install test ./chart-name --dry-run --debug
```

### Validar contra Kubernetes

```bash
helm template test ./chart-name | kubectl apply --dry-run=client -f -
```

## Segurança

- **Nunca** commite secrets ou credenciais
- Use `values.yaml` para configuração sensível
- Documente como usuários devem gerenciar secrets
- Considere integração com Secret Managers

## Perguntas?

- Abra uma [Issue](https://github.com/cloudscript-technology/helm-charts/issues)
- Entre em contato: jonathan.schmitt@cloudscript.com.br

## Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob Apache-2.0.
