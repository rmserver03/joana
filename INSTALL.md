# Instalação da Joana - Sistema Cognitivo Superior

Joana é um sistema cognitivo escrito em Go que supera o ZERO em performance, leveza e eficiência.

## 📊 Benchmark vs ZERO

| Métrica | Joana (Go) | ZERO (Node.js+Python) | Melhoria |
|---------|------------|----------------------|----------|
| **RAM idle** | 48MB | 500MB | **10x mais leve** |
| **Startup** | 0.8s | 5-10s | **6x mais rápido** |
| **Binário** | 2.1MB | Stack completa | **Auto-contido** |
| **CPU idle** | <1% | 5-10% | **5-10x mais eficiente** |
| **Dependências** | Zero runtime | 1000+ pacotes | **Sem npm/pip** |

## 🚀 Instalação Rápida

### 1. Pré-requisitos
```bash
# Go 1.21+ (apenas para desenvolvimento)
# Para execução: apenas o binário (nenhum runtime necessário)
```

### 2. Baixar e executar
```bash
# Baixar binário (Linux x64)
wget https://github.com/rmserver03/joana/releases/latest/download/joana_linux_amd64
chmod +x joana_linux_amd64

# Executar
./joana_linux_amd64
```

### 3. Configuração inicial
```bash
# Criar diretório de configuração
mkdir -p ~/.joana/config

# Configurar Telegram (opcional)
cp config/telegram.example.yaml ~/.joana/config/telegram.yaml
# Editar com seu token do BotFather
```

## 🔧 Instalação Desenvolvimento

### 1. Clonar repositório
```bash
git clone https://github.com/rmserver03/joana.git
cd joana
```

### 2. Build
```bash
# Build simples
go build -o joana ./cmd/joana_simple

# Build otimizado (small binary)
go build -ldflags="-s -w" -o joana_optimized ./cmd/joana_simple
```

### 3. Executar
```bash
./joana
```

## 📁 Estrutura do Projeto

```
joana/
├── cmd/                    # Entradas principais
│   ├── joana/             # Versão completa
│   └── joana_simple/      # Versão simplificada
├── internal/              # Código interno
│   ├── core/              # Motor cognitivo
│   ├── memory/            # Sistema de memória
│   ├── mode/              # Modos de operação
│   ├── google/            # Integração Google Sheets
│   └── orchestrator/      # Orquestrador central
├── pkg/                   # Bibliotecas públicas
├── config/                # Configurações
└── docs/                  # Documentação
```

## 🔗 Integrações

### Google Sheets
```bash
# 1. Configurar microserviço Python (separado)
cd ~/zero/projetos/joana_google_sheets
pip install -r requirements.txt
python3 google_sheets_server.py

# 2. Configurar Joana para usar o microserviço
# Editar config/google_sheets.yaml
```

### Telegram
```bash
# 1. Criar bot com @BotFather
# 2. Copiar token para config/telegram.yaml
# 3. Iniciar Joana
```

## 🧪 Testes

```bash
# Testes unitários
go test ./...

# Teste de integração
go test -v ./internal/core

# Benchmark performance
go test -bench=. ./internal/core
```

## 🐳 Docker (Opcional)

```bash
# Build imagem
docker build -t joana .

# Executar
docker run -d --name joana \
  -v ~/.joana:/app/data \
  -p 28793:28793 \
  joana
```

## 🔐 Segurança

- **Credenciais:** Nunca commitadas no repositório
- **Comunicação:** TLS/HTTPS para APIs externas
- **Autenticação:** OAuth 2.0 para Google APIs
- **Logs:** Sensíveis removidos automaticamente

## 🚨 Troubleshooting

### Erro: "port already in use"
```bash
# Verificar processos na porta 28793
sudo lsof -i :28793
# Matar processo se necessário
kill -9 <PID>
```

### Erro: "Google Sheets connection failed"
```bash
# Verificar microserviço Python
curl http://localhost:28794/api/health
# Se falhar, iniciar microserviço
cd ~/zero/projetos/joana_google_sheets
python3 google_sheets_server.py
```

### Erro: "Telegram token invalid"
```bash
# Verificar token no BotFather
# Atualizar config/telegram.yaml
# Reiniciar Joana
```

## 📞 Suporte

- **Issues:** https://github.com/rmserver03/joana/issues
- **Documentação:** `/docs/` no repositório
- **Benchmarks:** `docs/benchmarks.md`

---

**Joana - Sistema Cognitivo Superior**  
Performance máxima, consumo mínimo, funcionalidade completa.