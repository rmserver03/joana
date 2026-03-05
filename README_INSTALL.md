# 📱 INSTALAÇÃO AUTOMATIZADA DA JOANA

Sistema de instalação "one-click" para Android/Termux, Linux e Windows/WSL.

## 🚀 INSTALAÇÃO RÁPIDA (ONE-CLICK)

### Para Android/Termux:
```bash
# Baixe e execute o instalador
curl -sL https://raw.githubusercontent.com/rmserver03/joana/main/install_joana.sh | bash
```

### Para Linux/macOS:
```bash
# Baixe, torne executável e execute
wget https://raw.githubusercontent.com/rmserver03/joana/main/install_joana.sh
chmod +x install_joana.sh
./install_joana.sh
```

### Para Windows (WSL ou Git Bash):
```bash
# No WSL ou Git Bash
curl -sL https://raw.githubusercontent.com/rmserver03/joana/main/install_joana.sh | bash
```

## 📋 O QUE O INSTALADOR FAZ AUTOMATICAMENTE

1. **🔍 Detecta seu sistema operacional** (Android/Termux, Linux, macOS, Windows)
2. **📦 Instala todas as dependências** necessárias:
   - Git, Python, Go, Node.js, SQLite
   - Bibliotecas específicas para cada plataforma
3. **📥 Clona/atualiza o repositório** da Joana
4. **🔧 Instala dependências** Go e Python
5. **⚙️ Compila a Joana** para sua plataforma
6. **🏗️ Configura o ambiente** (~/.joana/)
7. **🎮 Executa assistente interativo** para configuração
8. **🚀 Cria scripts de serviço** (start/stop/status)
9. **✅ Mostra resumo completo** da instalação

## 🛠️ INSTALAÇÃO MANUAL (SE NECESSÁRIO)

### 1. Pré-requisitos mínimos:
```bash
# Android/Termux
pkg install git python golang nodejs-lts sqlite

# Ubuntu/Debian
sudo apt install git python3 python3-pip golang-go nodejs npm sqlite3

# Fedora/CentOS
sudo dnf install git python3 python3-pip golang nodejs npm sqlite

# macOS (com Homebrew)
brew install git python go node sqlite
```

### 2. Clonar repositório:
```bash
git clone https://github.com/rmserver03/joana.git
cd joana
```

### 3. Executar instalador:
```bash
chmod +x install_joana.sh
./install_joana.sh
```

## 🎮 ASSISTENTE INTERATIVO

Após a instalação, o **assistente interativo** vai guiá-lo:

1. **🤖 Configuração da API de LLM** (DeepSeek, OpenAI, Anthropic, Google)
2. **📊 Integração Google** (Sheets, Drive - opcional)
3. **💬 WhatsApp** (Evolution API - opcional)
4. **📱 Telegram** (Bot - opcional)
5. **⚙️ Configurações do sistema** (fuso horário, logs, etc.)

O assistente cria automaticamente o arquivo `~/.joana/.env` com todas as configurações.

## 🔧 CONFIGURAÇÃO PÓS-INSTALAÇÃO

### Arquivo de configuração:
```bash
# Localização
~/.joana/.env

# Editar manualmente
nano ~/.joana/.env

# Template disponível
cp .env.template ~/.joana/.env
```

### Scripts de serviço criados:
- `start_joana.sh` - Inicia a Joana
- `stop_joana.sh` - Para a Joana
- `status_joana.sh` - Verifica status

### Iniciar a Joana:
```bash
# Método 1: Usando script
./start_joana.sh

# Método 2: Direto (Android/Termux)
./joana_android

# Método 3: Direto (Linux/macOS)
./joana
```

## 📁 ESTRUTURA CRIADA

```
~/.joana/
├── .env              # Configurações (NUNCA compartilhar)
├── config/           # Configurações adicionais
├── data/             # Dados da Joana
│   ├── memory/       # Memória persistente
│   ├── sessions/     # Sessões de conversa
│   └── cache/        # Cache do sistema
├── logs/             # Logs do sistema
└── google_token.json # Token Google OAuth (se configurado)
```

## 🔄 ATUALIZAÇÃO

Para atualizar a Joana para a versão mais recente:

```bash
cd ~/joana
git pull origin main
./install_joana.sh  # Re-executar instalador
```

## 🐛 SOLUÇÃO DE PROBLEMAS

### Erro: "Command not found"
```bash
# Verificar se dependências estão instaladas
which git python3 go node

# Instalar manualmente se faltar
# (veja seção "Pré-requisitos mínimos")
```

### Erro: "Permission denied"
```bash
# Tornar scripts executáveis
chmod +x *.sh

# Executar com sudo se necessário (Linux/macOS)
sudo ./install_joana.sh
```

### Erro: "Git clone failed"
```bash
# Verificar conexão com GitHub
curl -I https://github.com

# Tentar com SSH
git clone git@github.com:rmserver03/joana.git
```

### Erro: "Go build failed"
```bash
# Configurar Go para Android/Termux
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=arm64

# Tentar compilar versão simplificada
CGO_ENABLED=0 go build -o joana_android cmd/joana_simple/main.go
```

## 📞 SUPORTE

1. **Issues no GitHub**: https://github.com/rmserver03/joana/issues
2. **Documentação completa**: Consulte `docs/` directory
3. **Script de diagnóstico**: `./diagnose.sh` (se disponível)

## 🎉 PARABÉNS!

Sua Joana está instalada e configurada. Para começar:

```bash
./start_joana.sh
```

E converse com sua assistente inteligente! 🚀

---

**Nota**: Este sistema de instalação foi projetado para ser:
- ✅ **Totalmente automático** - one-click install
- ✅ **Multiplataforma** - Android, Linux, macOS, Windows
- ✅ **Interativo** - assistente guia a configuração
- ✅ **Robusto** - verifica e corrige problemas
- ✅ **Fácil de atualizar** - git pull + re-executar

Problemas? Consulte a seção "Solução de Problemas" ou abra uma issue no GitHub.