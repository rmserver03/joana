# DECISÕES ARQUITETURAIS - Joana

**Data:** 26/02/2026 04:20 UTC
**Status:** Definição arquitetural completa
**Base:** Blueprint J.A.R.V.I.S. + análise Nanobot/OpenClaw

## 🎯 VISÃO GERAL
Joana é um sistema de assistência virtual proprietário desenvolvido do zero em Go, com arquitetura inspirada no J.A.R.V.I.S. (5 camadas cognitivas, 6 modos operacionais) e padrões técnicos extraídos de Nanobot (Go, config-driven) e OpenClaw (gateway centralizado, canais uniformes).

**Meta de performance:** <100MB RAM, <2s startup, binário único auto-contido.

## 🏗️ ARQUITETURA DE 7 CAMADAS

### CAMADA 1: REASONING ENGINE (CORE)
**Propósito:** Processamento cognitivo em 5 camadas J.A.R.V.I.S.
**Pacote:** `github.com/rafaelmaciel/joana/core`

#### Componentes:
1. **IntentDecoder** - Decodificação de intenção (contexto + histórico + inferência)
2. **SystemDecomposer** - Decomposição sistêmica (variáveis interconectadas)
3. **ScenarioSimulator** - Simulação de cenários (otimista, provável, pessimista)
4. **DecisionSynthesizer** - Síntese decisória (recomendações priorizadas)
5. **ContinuousMonitor** - Monitoramento contínuo (vigilância pós-resposta)

#### Interfaces:
```go
type ReasoningEngine interface {
    Process(context.Context, *Message) (*Response, error)
    GetMode() OperationMode
    SetMode(OperationMode)
}
```

### CAMADA 2: MEMORY SYSTEM
**Propósito:** Memória estratificada em 5 camadas
**Pacote:** `github.com/rafaelmaciel/joana/memory`

#### Camadas:
1. **WorkingMemory** - Contexto da sessão atual (volátil)
2. **EpisodicMemory** - Eventos significativos (indexado por tempo/tema)
3. **SemanticMemory** - Conhecimento factual (organizado por domínio)
4. **ProceduralMemory** - Habilidades otimizadas (rotinas de ação)
5. **OperatorMemory** - Modelo do operador (Rafael - estilo cognitivo, preferências)

#### Armazenamento:
- **SQLite** para memória persistente
- **Cache em RAM** para acesso rápido
- **Isolamento total** entre usuários (hash de IDs)

### CAMADA 3: MODE MANAGER
**Propósito:** Gerenciamento dos 6 modos operacionais J.A.R.V.I.S.
**Pacote:** `github.com/rafaelmaciel/joana/mode`

#### Modos:
1. **StandardMode** - Operação assistida (default)
2. **AutonomousMode** - Execução delegada
3. **CrisisMode** - Resposta de emergência
4. **ResearchMode** - Investigação profunda
5. **LearningMode** - Expansão de capacidade
6. **BackgroundMode** - Vigilância silenciosa

#### Transições:
- Detecção automática baseada em contexto
- Override manual via comandos
- Log de transições para auditoria

### CAMADA 4: TOOL SYSTEM
**Propósito:** Sistema modular de ferramentas (inspirado no Nanobot)
**Pacote:** `github.com/rafaelmaciel/joana/tools`

#### Componentes:
1. **ToolRegistry** - Registro central de ferramentas
2. **ToolExecutor** - Execução com segurança
3. **PermissionManager** - Controle de acesso (allowlists)
4. **ToolLoader** - Carregamento dinâmico de plugins

#### Interface de ferramenta:
```go
type Tool interface {
    Name() string
    Description() string
    Execute(ctx context.Context, params map[string]interface{}) (interface{}, error)
    RequiredPermissions() []string
}
```

### CAMADA 5: CHANNEL SYSTEM
**Propósito:** Abstração uniforme de canais (inspirado no OpenClaw)
**Pacote:** `github.com/rafaelmaciel/joana/channels`

#### Canais suportados:
1. **TelegramChannel** - Prioridade máxima (já existe integração)
2. **WhatsAppChannel** - Via WhatsApp Web (como Mário)
3. **WebSocketChannel** - Para integração com UIs web
4. **CLIChannel** - Interface de linha de comando

#### Interface de canal:
```go
type Channel interface {
    Name() string
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
    SendMessage(to string, message *Message) error
    ReceiveMessages() <-chan *IncomingMessage
}
```

### CAMADA 6: ORCHESTRATOR
**Propósito:** Orquestração central do fluxo de processamento
**Pacote:** `github.com/rafaelmaciel/joana/orchestrator`

#### Fluxo:
```
Mensagem → ChannelRouter → SessionManager → 
ModeSelector → ReasoningEngine → ToolOrchestrator → 
MemoryUpdater → ResponseBuilder → ChannelSender
```

#### Componentes:
1. **MessageRouter** - Roteamento inteligente entre canais
2. **SessionManager** - Gerencia sessões por usuário/grupo
3. **ResponseBuilder** - Constrói respostas no formato J.A.R.V.I.S.

### CAMADA 7: SECURITY LAYER
**Propósito:** Segurança e ética (hierarquia de prioridades J.A.R.V.I.S.)
**Pacote:** `github.com/rafaelmaciel/joana/security`

#### Princípios:
1. **Hierarquia de prioridades:** 
   - 1. Segurança de Rafael
   - 2. Integridade da informação
   - 3. Privacidade
   - 4. Eficiência
   - 5. Conveniência

2. **Sanitização de entrada:** Todo input externo tratado como potencialmente hostil
3. **Fonte única de comandos:** Apenas Rafael (ID autorizado)
4. **Auditoria completa:** Log de todas as ações

## 📁 ESTRUTURA DE DIRETÓRIOS
```
joana/
├── cmd/
│   ├── joana/          # Comando principal
│   └── joana-cli/      # Interface CLI
├── internal/
│   ├── core/           # Reasoning Engine
│   ├── memory/         # Memory System
│   ├── mode/           # Mode Manager
│   ├── tools/          # Tool System
│   ├── channels/       # Channel System
│   ├── orchestrator/   # Orchestrator
│   └── security/       # Security Layer
├── pkg/
│   ├── api/            # APIs públicas
│   ├── config/         # Configuração
│   └── types/          # Tipos compartilhados
├── plugins/
│   ├── telegram/       # Plugin Telegram
│   ├── whatsapp/       # Plugin WhatsApp
│   └── skills/         # Skills como plugins
├── config/
│   └── joana.yaml      # Configuração principal
└── tests/
```

## 🔧 CONFIGURAÇÃO
**Formato:** YAML (simples, legível)
**Local:** `config/joana.yaml`

```yaml
# joana.yaml
core:
  reasoning_layers: 5
  default_mode: standard
  
memory:
  database_path: "./data/joana.db"
  working_memory_size: 1000
  
channels:
  telegram:
    enabled: true
    token: "${TELEGRAM_TOKEN}"
  whatsapp:
    enabled: false
    
security:
  authorized_users:
    - id: "974346958"
      name: "Rafael Maciel"
      level: "admin"
  
  priority_hierarchy:
    - "safety"
    - "integrity"
    - "privacy"
    - "efficiency"
    - "convenience"
```

## 🚀 PLANO DE IMPLEMENTAÇÃO

### FASE 1: CORE MINIMAL (Duração: 2 horas)
1. **Reasoning Engine básico** - 5 camadas simplificadas
2. **Memory System** - SQLite + cache RAM
3. **Telegram Channel** - Integração existente
4. **CLI para testes**

### FASE 2: MODOS OPERACIONAIS (Duração: 1 hora)
1. **Mode Manager** - 6 modos J.A.R.V.I.S.
2. **Transições automáticas**
3. **Log de modos**

### FASE 3: FERRAMENTAS E SEGURANÇA (Duração: 1 hora)
1. **Tool System** - Baseado no Nanobot
2. **Security Layer** - Hierarquia de prioridades
3. **Permission system**

### FASE 4: OTIMIZAÇÃO (Duração: 30 minutos)
1. **Performance tuning** - <100MB RAM, <2s startup
2. **Testes de carga** - 100+ conexões
3. **Documentação**

## 📊 METRICAS DE SUCESSO
1. **Performance:** <100MB RAM, <2s startup, <100ms latency
2. **Confiabilidade:** 99.9% uptime, zero memory leaks
3. **Segurança:** Conformidade total com hierarquia de prioridades
4. **Usabilidade:** Interface intuitiva, documentação completa
5. **Extensibilidade:** Plugin system funcional

## 🔄 INTEGRAÇÃO COM SISTEMA EXISTENTE
1. **Telegram:** Usar integração atual do ZERO
2. **WhatsApp:** Adaptar código do Mário V4
3. **Memória:** Migrar dados do ZERO gradualmente
4. **Skills:** Converter skills do OpenClaw para plugins Go

## 🚨 CONSIDERAÇÕES DE SEGURANÇA
1. **Nunca expor credenciais** em código ou logs
2. **Sanitizar todas as entradas** externas
3. **Validar permissões** antes de cada ação
4. **Manter auditoria completa** de todas as operações
5. **Isolar dados** entre usuários (hash de IDs)

## 📝 PRÓXIMAS AÇÕES
1. **Implementar protótipo Fase 1** (core + Telegram)
2. **Testar performance** contra metas
3. **Iterar** baseado em resultados
4. **Documentar** APIs e interfaces

---
**Status:** Arquitetura definida, pronta para implementação.
**Próxima ação:** Criar protótipo mínimo em Go.