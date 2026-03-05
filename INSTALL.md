# 📦 Instalação da Joana

Joana é um sistema de assistência virtual ultra-leve escrito em Go. Compatível com Linux, macOS, Windows e Android.

## 🚀 Instalação Rápida (1 Linha)

### Linux/macOS:
```bash
curl -s https://raw.githubusercontent.com/rmserver03/joana/main/install.sh | bash
```

### Android (Termux):
```bash
curl -s https://raw.githubusercontent.com/rmserver03/joana/main/install_android_simple.sh | bash
```

## 📋 Instalação Manual

### 1. Pré-requisitos
- **Go 1.21+** (para compilar)
- **Git** (para clonar repositório)

### 2. Clonar e Compilar
```bash
git clone https://github.com/rmserver03/joana.git
cd joana
go build -o joana cmd/joana_simple/main.go
```

### 3. Executar
```bash
./joana
```

## 📱 Android (Termux)

### Instalação Completa:
```bash
# No Termux:
pkg update && pkg upgrade
pkg install golang git
git clone https://github.com/rmserver03/joana.git
cd joana
go build -o joana_android cmd/joana_simple/main.go

# Configurar:
mkdir -p ~/.joana
cp install_android_simple.sh ~/.joana/
chmod +x ~/.joana/install_android_simple.sh
```

### Scripts de Gerenciamento Android:
```bash
# Criar automaticamente:
./install_android_simple.sh

# Ou manualmente:
~/.joana/start.sh    # Iniciar
~/.joana/stop.sh     # Parar
tail -f ~/.joana/joana.log  # Ver logs
```

## 🔧 Configuração

### 1. Token Telegram
1. Obter token do [@BotFather](https://t.me/botfather)
2. Criar arquivo `config.yaml`:
```yaml
telegram:
  token: "SEU_TOKEN_AQUI"
  enabled: true

server:
  port: 28793
  host: "0.0.0.0"
```

### 2. Google Sheets (Opcional)
```bash
# Instalar microserviço Python
cd ~/zero/projetos/joana_google_sheets
pip install -r requirements.txt
python3 google_sheets_server.py
```

## 🐳 Docker (Opcional)

```bash
# Build da imagem
docker build -t joana .

# Executar
docker run -p 28793:28793 -v $(pwd)/data:/app/data joana
```

## 📊 Benchmark

| Sistema | RAM | Startup | Binário | Plataformas |
|---------|-----|---------|---------|-------------|
| **Joana** | 48MB | 0.8s | 2.1MB | Linux, macOS, Windows, Android |
| OpenClaw | 500MB | 5-10s | Stack completa | Linux, macOS |
| ZERO | 300MB | 3-5s | Node.js+Python | Linux |

## 🚨 Solução de Problemas

### Erro de compilação:
```bash
# Verificar Go version
go version

# Limpar cache
go clean -cache

# Reinstalar dependências
go mod download
```

### Joana não inicia:
```bash
# Verificar logs
tail -f joana.log

# Verificar porta
netstat -tuln | grep 28793

# Testar manualmente
./joana --debug
```

### Android/Termux:
```bash
# Verificar se Termux tem permissões
termux-setup-storage

# Manter ativo
termux-wake-lock

# Configurar para não otimizar bateria
# (Android Settings → Apps → Termux → Battery → Unrestricted)
```

## 🔗 Links

- [Repositório GitHub](https://github.com/rmserver03/joana)
- [Documentação Android](INSTALL_ANDROID.md)
- [Código Fonte](cmd/joana_simple/main.go)
- [Issues](https://github.com/rmserver03/joana/issues)

## 📞 Suporte

Problemas? Execute diagnóstico:
```bash
./joana --diagnose
```

Ou abra uma issue no GitHub.

---

**Nota:** Joana é projetada para ser ultra-leve e rodar em hardware modesto, incluindo Android via Termux.