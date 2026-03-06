# Joana - Sistema Cognitivo para Android

Sistema de assistente cognitivo autônomo que roda 100% no Android via Termux.

## 🚀 Instalação Rápida

No Termux (Android), execute:

```bash
# Baixar script de instalação
curl -O https://raw.githubusercontent.com/rmserver03/joana/main/joana_install_android.sh

# Tornar executável
chmod +x joana_install_android.sh

# Executar instalação
./joana_install_android.sh
```

O script guiará você através de toda a configuração interativamente.

## 📋 Requisitos

- Android 8.0+
- Termux (da Play Store ou F-Droid)
- Conexão com internet
- 500MB de espaço livre

## 🔧 Funcionalidades

### ✅ Sistema Completo
- **Assistente cognitivo** com raciocínio estratificado
- **Memória persistente** em SQLite
- **Integração Telegram** (bot completo)
- **Suporte a múltiplos LLMs** (DeepSeek, OpenAI, Anthropic, local)
- **Google Sheets** (opcional, para CRM)
- **Interface web** (opcional, localhost:8080)

### 🧠 Capacidades Cognitivas
- Raciocínio em 5 camadas simultâneas
- Memória estratificada (trabalho, episódica, semântica, procedural)
- Aprendizado contínuo sobre o usuário
- Antecipação de necessidades
- Modos operacionais adaptativos

### 📱 Otimizado para Android
- Baixo consumo de recursos
- Execução em background
- Início automático com Termux
- Widgets para controle rápido
- Logs detalhados para diagnóstico

## 🛠️ Comandos Básicos

### No Termux:
```bash
# Iniciar Joana
./start_joana.sh

# Parar Joana  
./stop_joana.sh

# Verificar status
./joana_status.sh

# Ver logs
tail -f ~/.joana/logs/joana_console.log
```

### No Telegram (com o bot):
```
#rm status       # Verificar status do sistema
#rm help         # Ajuda completa
#rm config       # Ver configuração
#rm memory       # Gerenciar memória
#rm update       # Atualizar sistema
```

## ⚙️ Configuração

O script de instalação configura automaticamente:

1. **Telegram Bot** - Token e ID do chat
2. **API LLM** - Escolha do provedor (DeepSeek recomendado)
3. **Memória** - Banco SQLite local
4. **Logs** - Sistema de logs estruturado
5. **Segurança** - Prefixo `#rm` para comandos admin

Arquivos de configuração em `~/.joana/`:
- `config.yaml` - Configuração principal
- `joana.db` - Banco de dados SQLite
- `logs/` - Logs do sistema

## 🔄 Atualização

Para atualizar para a versão mais recente:

```bash
cd ~/joana
git pull origin main
go build -o joana ./cmd/joana/
./stop_joana.sh
./start_joana.sh
```

## 🐛 Solução de Problemas

### Problema: "Comando não encontrado"
**Solução:** Execute `pkg update && pkg upgrade` no Termux

### Problema: Bot Telegram não responde
**Solução:**
1. Verifique se o token está correto em `~/.joana/config.yaml`
2. Execute `./joana_status.sh` para verificar se está rodando
3. Verifique logs: `tail -f ~/.joana/logs/joana_console.log`

### Problema: Sem conexão com API LLM
**Solução:**
1. Verifique sua conexão com internet
2. Confirme que a API key está correta
3. Para DeepSeek: obtenha API key gratuita em https://platform.deepseek.com

### Problema: Alto consumo de bateria
**Solução:**
1. Configure para não iniciar automaticamente
2. Use `./stop_joana.sh` quando não estiver usando
3. Limite a frequência de verificações no `config.yaml`

## 📊 Estrutura do Projeto

```
~/joana/                    # Código fonte
├── cmd/joana/             # Executável principal
├── internal/              # Módulos internos
│   ├── channels/          # Telegram, WhatsApp
│   ├── core/              # Motor cognitivo
│   ├── memory/            # Gerenciador de memória
│   └── orchestrator/      # Orquestrador central
├── pkg/types/             # Tipos e estruturas
└── test/                  # Testes

~/.joana/                  # Configuração do usuário
├── config.yaml           # Configuração YAML
├── joana.db             # Banco SQLite
└── logs/                # Logs do sistema
```

## 🔒 Segurança

- **Prefixos de comando:** Apenas mensagens com `#rm` são processadas como comandos
- **IDs de administrador:** Configurável no `config.yaml`
- **Tokens:** Nunca expostos em logs ou mensagens
- **Dados locais:** Tudo armazenado no dispositivo, sem nuvem

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs em `~/.joana/logs/`
2. Consulte este README
3. Abra uma issue no GitHub

## 📄 Licença

MIT License - Veja LICENSE para detalhes.

---

**Desenvolvido com ❤️ pelo Sistema Cognitivo Zero**  
*Protocolo Zero Erros garantido*