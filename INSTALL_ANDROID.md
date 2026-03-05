# 📱 Joana para Android (Termux)

## Instalação Automática de 1 Linha

Execute no Termux:
```bash
curl -s https://raw.githubusercontent.com/rmserver03/joana/main/install_android.sh | bash
```

## 📋 Instalação Manual Passo a Passo

### 1. Instalar Termux
- Baixe da [Play Store](https://play.google.com/store/apps/details?id=com.termux)
- Ou do [F-Droid](https://f-droid.org/en/packages/com.termux/)

### 2. Executar no Termux:
```bash
# Atualizar sistema
pkg update && pkg upgrade

# Instalar dependências
pkg install -y golang git wget curl

# Clonar repositório
git clone https://github.com/rmserver03/joana.git
cd joana

# Compilar Joana
go build -o joana_android cmd/joana_simple/main.go

# Criar diretório de configuração
mkdir -p ~/.joana
```

### 3. Scripts de Gerenciamento
```bash
# Criar script de inicialização
cat > ~/.joana/start_joana.sh << 'EOF'
#!/bin/bash
cd ~/joana
nohup ./joana_android > ~/.joana/joana.log 2>&1 &
echo $! > ~/.joana/joana.pid
echo "Joana iniciada (PID: $(cat ~/.joana/joana.pid))"
EOF

chmod +x ~/.joana/start_joana.sh

# Criar script de parada
cat > ~/.joana/stop_joana.sh << 'EOF'
#!/bin/bash
if [ -f ~/.joana/joana.pid ]; then
    kill $(cat ~/.joana/joana.pid)
    rm ~/.joana/joana.pid
    echo "Joana parada"
else
    echo "Joana não está rodando"
fi
EOF

chmod +x ~/.joana/stop_joana.sh
```

## 🚀 Uso Rápido

### Iniciar Joana:
```bash
~/.joana/start_joana.sh
```

### Ver logs:
```bash
tail -f ~/.joana/joana.log
```

### Parar Joana:
```bash
~/.joana/stop_joana.sh
```

## 🔧 Configuração

### Token Telegram:
1. Obter token do [@BotFather](https://t.me/botfather)
2. Criar arquivo de configuração:
```bash
cat > ~/.joana/config.yaml << 'EOF'
telegram:
  token: "SEU_TOKEN_AQUI"
  enabled: true

server:
  port: 28793
  host: "0.0.0.0"
EOF
```

### Serviço Automático (Inicialização com Termux):
```bash
# Instalar termux-services
pkg install termux-services

# Criar serviço de inicialização
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/joana << 'EOF'
#!/data/data/com.termux/files/usr/bin/sh
sleep 10
$HOME/.joana/start_joana.sh
EOF

chmod +x ~/.termux/boot/joana

# Habilitar serviço
sv-enable joana
```

## 📊 Recursos Consumidos

| Recurso | Consumo | Status |
|---------|---------|--------|
| RAM | 48-100MB | ✅ Suficiente |
| CPU | <5% | ✅ Mínimo |
| Armazenamento | ~15MB | ✅ Negligível |
| Bateria | Impacto mínimo | ✅ Otimizado |

## 🚨 Solução de Problemas

### Joana não inicia:
```bash
# Verificar logs
cat ~/.joana/joana.log

# Verificar se compilou
ls -la ~/joana/joana_android

# Recompilar
cd ~/joana && go build -o joana_android cmd/joana_simple/main.go
```

### Termux suspende o processo:
1. **Configurar Termux para não otimizar bateria:**
   - Android Settings → Apps → Termux → Battery → Unrestricted
   
2. **Manter Termux ativo:**
```bash
# Instalar termux-wake-lock
pkg install termux-api

# Manter tela ligada
termux-wake-lock
```

### Sem conexão:
```bash
# Verificar internet
ping -c 3 google.com

# Verificar se porta está aberta
netstat -tuln | grep 28793
```

## 🔗 Links Úteis

- [Repositório GitHub](https://github.com/rmserver03/joana)
- [Termux Wiki](https://wiki.termux.com)
- [Documentação Go](https://golang.org/doc/)

## 📞 Suporte

Problemas? Execute:
```bash
# Diagnóstico completo
cd ~/joana && ./joana_android --diagnose
```

Ou abra uma issue no [GitHub](https://github.com/rmserver03/joana/issues).

---

**Nota:** Joana é ultra-leve e projetada especificamente para Android. Consome menos recursos que apps de mensagens comuns e pode rodar 24/7 com configuração adequada.