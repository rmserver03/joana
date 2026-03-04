# ANÁLISE DE REFERÊNCIAS - Joana

**Data:** 26/02/2026 04:15 UTC
**Status:** Análise em andamento (2/4 frameworks analisados)

## 📋 FRAMEWORKS ANALISADOS

### 1. NANOBOT (Go) - ✅ ANALISADO
**Repositório:** https://github.com/nanobot-ai/nanobot
**Linguagem:** Go
**Tamanho:** ~150 arquivos .go
**Arquitetura:** Config-driven agent system

#### PADRÕES ARQUITETURAIS (EXTRAIR)
1. **Config-first:** Agents, Skills, Tasks definidos como Markdown + YAML front matter
2. **Composição hierárquica:** Tasks → Skills → Tools
3. **Determinismo:** Stepwise execution com replay
4. **Segurança:** Allowlists, approvals, scoped permissions
5. **Portabilidade:** Projetos podem embarcar seus próprios agent packs
6. **Estrutura de pacotes:**
   - `pkg/agents/` - Definições de agentes
   - `pkg/llm/` - Integração com modelos
   - `pkg/tools/` - Sistema de ferramentas
   - `pkg/runtime/` - Execução de tasks
   - `pkg/config/` - Carregamento de configuração

#### PADRÕES PARA EVITAR
- Complexidade excessiva em validação de schemas
- Dependência pesada de YAML front matter

#### RELEVÂNCIA PARA JOANA
- **Alta:** Go como linguagem, arquitetura modular
- **Média:** Sistema config-driven (Joana será mais código-driven)

### 2. OPENCLAW (Node.js) - ✅ ANALISADO
**Repositório:** Clonado localmente
**Linguagem:** TypeScript/Node.js
**Tamanho:** ~1856 arquivos apenas no gateway
**Arquitetura:** Gateway WebSocket como plano de controle único

#### PADRÕES ARQUITETURAIS (EXTRAIR)
1. **Gateway WebSocket:** Plano de controle centralizado
2. **Sistema de autenticação/autorização:** Robust
3. **Abstração de canais uniforme:** Telegram, WhatsApp, etc.
4. **Sistema de skills modular:** Skills como plugins
5. **Arquitetura de eventos:** Pub/sub para comunicação interna
6. **Sistema de memória:** Estratificada (trabalho, episódica, etc.)

#### PADRÕES PARA EVITAR
- **Complexidade excessiva:** Muito código para funcionalidade básica
- **Alto consumo de RAM:** 500MB+ em operação
- **Startup lento:** 30+ segundos
- **Dependência pesada do Node.js:** Overhead significativo

#### RELEVÂNCIA PARA JOANA
- **Alta:** Padrões arquiteturais maduros
- **Baixa:** Implementação específica (muito complexa)

### 3. PICOCLAW (Go) - ❌ NÃO ENCONTRADO
**Status:** Repositório não localizado
**Suposição:** Versão minimalista do OpenClaw em Go

#### PADRÕES ESPERADOS (INFERIDOS)
1. Go como linguagem
2. Arquitetura minimalista
3. Performance otimizada
4. Binário único auto-contido

### 4. KIMI CLAW (Python) - ❌ NÃO ENCONTRADO
**Status:** Repositório não localizado
**Suposição:** Framework Python para agentes

## 🎯 PADRÕES ARQUITETURAIS PARA JOANA

### DOS FRAMEWORKS EXISTENTES (EXTRAIR)
1. **Nanobot:** Config-driven, Go, modular, segurança
2. **OpenClaw:** Gateway centralizado, canais uniformes, skills modulares
3. **PicoClaw (inferido):** Minimalismo, performance
4. **Kimi Claw (inferido):** Python, possivelmente simples

### DO BLUEPRINT J.A.R.V.I.S. (IMPLEMENTAR)
1. **5 camadas cognitivas:** Decodificação, decomposição, simulação, síntese, monitoramento
2. **6 modos operacionais:** Padrão, autônomo, crise, pesquisa, aprendizado, fundo
3. **Memória estratificada:** 5 camadas (trabalho, episódica, semântica, procedural, do operador)
4. **Comunicação J.A.R.V.I.S.:** Conclusão-primeiro, antecipação contextual, humor sutil
5. **Ética:** Hierarquia de prioridades inviolável

## 🏗️ ARQUITETURA PROPOSTA PARA JOANA

### CAMADA 1: CORE (Go)
- **Reasoning Engine:** 5 camadas cognitivas
- **Memory System:** 5 camadas estratificadas
- **Mode Manager:** 6 modos operacionais
- **Security Layer:** Hierarquia de prioridades, sanitização

### CAMADA 2: ORCHESTRATION
- **Task Orchestrator:** Gerencia execução de tasks
- **Tool Registry:** Sistema de ferramentas modular
- **Provider Registry:** Integração com LLMs (local/remoto)

### CAMADA 3: CHANNELS
- **Channel Abstraction:** Interface uniforme para Telegram, WhatsApp, etc.
- **Message Router:** Roteamento inteligente de mensagens
- **Session Manager:** Gerencia sessões por usuário/grupo

### CAMADA 4: INTEGRATION
- **API Gateway:** REST/WebSocket para integração externa
- **Plugin System:** Skills como plugins Go
- **Data Connectors:** SQLite, arquivos, APIs externas

## 📊 METAS DE PERFORMANCE
1. **RAM:** <100MB (vs 500MB+ do OpenClaw)
2. **Startup:** <2s (vs 30s+ do OpenClaw)
3. **Binário:** Único, auto-contido, cross-platform
4. **Concorrência:** 100+ conexões simultâneas
5. **Latência:** <100ms para respostas simples

## 🔄 FLUXO DE PROCESSAMENTO
```
Mensagem → Channel → Message Router → Session Manager → 
Mode Manager → Reasoning Engine (5 camadas) → 
Memory System → Tool Registry → Response → Channel
```

## 🚀 PRÓXIMOS PASSOS
1. **Completar análise:** Ler código core do Nanobot e OpenClaw
2. **Definir arquitetura detalhada:** Especificar interfaces e pacotes
3. **Implementar protótipo:** Core + Telegram channel
4. **Testar performance:** Validar metas <100MB RAM, <2s startup
5. **Iterar:** Refinar baseado em testes

## 📝 DECISÕES CRÍTICAS
1. **Linguagem:** Go mantida (performance, binário único)
2. **Configuração:** Híbrida (código + configuração simples)
3. **Complexidade:** Menor que OpenClaw, maior que Nanobot
4. **Extensibilidade:** Plugin system para skills
5. **Segurança:** Herdar padrões ZERO-J.A.R.V.I.S.

---
**Próxima ação:** Criar `DECISOES_ARQUITETURA.md` com especificações técnicas detalhadas.