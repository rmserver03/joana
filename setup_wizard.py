#!/usr/bin/env python3
"""
Assistente Interativo de Configuração da Joana
Solicita informações do usuário e configura o ambiente automaticamente
"""

import os
import sys
import json
import subprocess
from pathlib import Path

# Cores para terminal
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

def print_header(text):
    """Imprime cabeçalho formatado"""
    print(f"\n{Colors.CYAN}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}{text:^60}{Colors.END}")
    print(f"{Colors.CYAN}{'='*60}{Colors.END}\n")

def print_success(text):
    """Imprime mensagem de sucesso"""
    print(f"{Colors.GREEN}✅ {text}{Colors.END}")

def print_warning(text):
    """Imprime mensagem de aviso"""
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.END}")

def print_error(text):
    """Imprime mensagem de erro"""
    print(f"{Colors.RED}❌ {text}{Colors.END}")

def print_info(text):
    """Imprime mensagem informativa"""
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.END}")

def ask_question(question, default=None, required=False):
    """Faz uma pergunta ao usuário"""
    while True:
        if default:
            prompt = f"{Colors.WHITE}{question} [{default}]: {Colors.END}"
        else:
            prompt = f"{Colors.WHITE}{question}: {Colors.END}"
        
        answer = input(prompt).strip()
        
        if not answer and default:
            return default
        elif not answer and required:
            print_error("Esta informação é obrigatória!")
            continue
        elif answer:
            return answer
        else:
            return ""

def ask_yes_no(question, default=True):
    """Pergunta sim/não"""
    default_text = "S/n" if default else "s/N"
    while True:
        answer = input(f"{Colors.WHITE}{question} [{default_text}]: {Colors.END}").strip().lower()
        
        if not answer:
            return default
        elif answer in ['s', 'sim', 'y', 'yes']:
            return True
        elif answer in ['n', 'não', 'no']:
            return False
        else:
            print_error("Responda com 's' ou 'n'")

def select_option(question, options):
    """Permite selecionar uma opção"""
    print(f"\n{Colors.WHITE}{question}{Colors.END}")
    for i, option in enumerate(options, 1):
        print(f"  {Colors.CYAN}{i}.{Colors.END} {option}")
    
    while True:
        try:
            choice = int(input(f"\n{Colors.WHITE}Escolha (1-{len(options)}): {Colors.END}"))
            if 1 <= choice <= len(options):
                return choice - 1
            else:
                print_error(f"Escolha inválida. Digite um número entre 1 e {len(options)}")
        except ValueError:
            print_error("Digite um número válido")

def detect_platform():
    """Detecta a plataforma atual"""
    if 'ANDROID_ROOT' in os.environ or 'TERMUX_VERSION' in os.environ:
        return "android"
    elif sys.platform == "linux":
        return "linux"
    elif sys.platform == "darwin":
        return "macos"
    elif sys.platform == "win32":
        return "windows"
    else:
        return "unknown"

def configure_llm_api():
    """Configura API de LLM"""
    print_header("CONFIGURAÇÃO DA API DE INTELIGÊNCIA ARTIFICIAL")
    
    print_info("A Joana precisa de uma API de LLM para funcionar.")
    print_info("Escolha seu provedor preferido:")
    
    providers = [
        "DeepSeek (recomendado - mais barato)",
        "OpenAI (GPT-4, GPT-3.5)",
        "Anthropic (Claude)",
        "Google (Gemini)",
        "Outro / Configurar depois"
    ]
    
    choice = select_option("Qual API você quer usar?", providers)
    
    config = {}
    
    if choice == 0:  # DeepSeek
        print_info("\nDeepSeek API:")
        print_info("1. Acesse: https://platform.deepseek.com/api_keys")
        print_info("2. Crie uma conta (se não tiver)")
        print_info("3. Gere uma API Key")
        
        api_key = ask_question("Digite sua DeepSeek API Key", required=True)
        config['DEEPSEEK_API_KEY'] = api_key
        config['LLM_PROVIDER'] = 'deepseek'
        
    elif choice == 1:  # OpenAI
        print_info("\nOpenAI API:")
        print_info("1. Acesse: https://platform.openai.com/api-keys")
        print_info("2. Crie uma conta (se não tiver)")
        print_info("3. Gere uma API Key")
        
        api_key = ask_question("Digite sua OpenAI API Key", required=True)
        config['OPENAI_API_KEY'] = api_key
        config['LLM_PROVIDER'] = 'openai'
        
    elif choice == 2:  # Anthropic
        print_info("\nAnthropic API:")
        print_info("1. Acesse: https://console.anthropic.com/")
        print_info("2. Crie uma conta (se não tiver)")
        print_info("3. Gere uma API Key")
        
        api_key = ask_question("Digite sua Anthropic API Key", required=True)
        config['ANTHROPIC_API_KEY'] = api_key
        config['LLM_PROVIDER'] = 'anthropic'
        
    elif choice == 3:  # Google
        print_info("\nGoogle Gemini API:")
        print_info("1. Acesse: https://makersuite.google.com/app/apikey")
        print_info("2. Crie uma conta (se não tiver)")
        print_info("3. Gere uma API Key")
        
        api_key = ask_question("Digite sua Google API Key", required=True)
        config['GOOGLE_API_KEY'] = api_key
        config['LLM_PROVIDER'] = 'google'
        
    else:  # Configurar depois
        print_warning("Você precisará configurar a API manualmente depois.")
        config['LLM_PROVIDER'] = 'none'
    
    return config

def configure_google_apis():
    """Configura APIs do Google (opcional)"""
    print_header("CONFIGURAÇÃO DAS APIS DO GOOGLE (OPCIONAL)")
    
    use_google = ask_yes_no("Deseja configurar integração com Google Sheets/Drive?", default=False)
    
    config = {}
    
    if use_google:
        print_info("\nGoogle Sheets/Drive:")
        print_info("1. Você precisará configurar OAuth 2.0")
        print_info("2. Siga o guia em docs/GOOGLE_SETUP.md")
        print_info("3. Ou configure manualmente depois")
        
        sheets_id = ask_question("ID da planilha do Google Sheets (deixe em branco para pular)")
        if sheets_id:
            config['GOOGLE_SHEETS_ID'] = sheets_id
            
        drive_folder = ask_question("ID da pasta do Google Drive (deixe em branco para pular)")
        if drive_folder:
            config['GOOGLE_DRIVE_FOLDER_ID'] = drive_folder
            
        print_info("\nPara OAuth 2.0 completo, execute depois:")
        print_info("python3 -m joana_google_sheets.auth_setup")
    
    return config

def configure_whatsapp():
    """Configura WhatsApp (opcional)"""
    print_header("CONFIGURAÇÃO DO WHATSAPP (OPCIONAL)")
    
    use_whatsapp = ask_yes_no("Deseja configurar integração com WhatsApp?", default=False)
    
    config = {}
    
    if use_whatsapp:
        print_info("\nWhatsApp (Evolution API ou similar):")
        print_info("1. Você precisará de uma instância do Evolution API")
        print_info("2. Ou outro serviço compatível")
        
        api_key = ask_question("API Key do WhatsApp")
        if api_key:
            config['WHATSAPP_API_KEY'] = api_key
            
        instance_id = ask_question("Instance ID do WhatsApp")
        if instance_id:
            config['WHATSAPP_INSTANCE_ID'] = instance_id
            
        print_warning("Certifique-se de que o serviço WhatsApp está rodando e acessível")
    
    return config

def configure_telegram():
    """Configura Telegram (opcional)"""
    print_header("CONFIGURAÇÃO DO TELEGRAM (OPCIONAL)")
    
    use_telegram = ask_yes_no("Deseja configurar integração com Telegram?", default=False)
    
    config = {}
    
    if use_telegram:
        print_info("\nTelegram Bot:")
        print_info("1. Converse com @BotFather no Telegram")
        print_info("2. Crie um novo bot com /newbot")
        print_info("3. Copie o token fornecido")
        
        bot_token = ask_question("Token do Bot do Telegram", required=True)
        config['TELEGRAM_BOT_TOKEN'] = bot_token
        
        chat_id = ask_question("Seu Chat ID do Telegram (deixe em branco para detectar automaticamente)")
        if chat_id:
            config['TELEGRAM_CHAT_ID'] = chat_id
            
        print_success("Bot do Telegram configurado!")
    
    return config

def configure_system_settings():
    """Configurações do sistema"""
    print_header("CONFIGURAÇÕES DO SISTEMA")
    
    config = {}
    
    # Fuso horário
    print_info("Fuso horário padrão: America/Sao_Paulo")
    change_tz = ask_yes_no("Deseja alterar o fuso horário?", default=False)
    
    if change_tz:
        tz = ask_question("Digite o fuso horário (ex: America/Sao_Paulo, Europe/London)")
        config['TZ'] = tz
    else:
        config['TZ'] = 'America/Sao_Paulo'
    
    # Nível de log
    log_levels = ['debug', 'info', 'warning', 'error']
    print_info("\nNível de log:")
    for i, level in enumerate(log_levels):
        print(f"  {i+1}. {level}")
    
    log_choice = select_option("Escolha o nível de log:", log_levels)
    config['LOG_LEVEL'] = log_levels[log_choice]
    
    # Diretório de dados
    default_data_dir = str(Path.home() / '.joana' / 'data')
    print_info(f"\nDiretório de dados padrão: {default_data_dir}")
    change_dir = ask_yes_no("Deseja alterar o diretório de dados?", default=False)
    
    if change_dir:
        data_dir = ask_question("Digite o caminho completo do diretório de dados")
        config['DATA_DIR'] = data_dir
    else:
        config['DATA_DIR'] = default_data_dir
    
    return config

def save_configuration(all_config):
    """Salva a configuração no arquivo .env"""
    env_path = Path.home() / '.joana' / '.env'
    
    # Ler template se existir
    template_path = Path.cwd() / '.env.template'
    if template_path.exists():
        with open(template_path, 'r') as f:
            template = f.read()
    else:
        # Template básico
        template = """# CONFIGURAÇÕES DA JOANA
# Gerado automaticamente pelo assistente de configuração

# LLM API
{DEEPSEEK_API_KEY}
{OPENAI_API_KEY}
{ANTHROPIC_API_KEY}
{GOOGLE_API_KEY}
LLM_PROVIDER={LLM_PROVIDER}

# Google APIs
GOOGLE_SHEETS_ID={GOOGLE_SHEETS_ID}
GOOGLE_DRIVE_FOLDER_ID={GOOGLE_DRIVE_FOLDER_ID}

# WhatsApp
WHATSAPP_API_KEY={WHATSAPP_API_KEY}
WHATSAPP_INSTANCE_ID={WHATSAPP_INSTANCE_ID}

# Telegram
TELEGRAM_BOT_TOKEN={TELEGRAM_BOT_TOKEN}
TELEGRAM_CHAT_ID={TELEGRAM_CHAT_ID}

# Configurações do sistema
LOG_LEVEL={LOG_LEVEL}
DATA_DIR={DATA_DIR}
TZ={TZ}
"""
    
    # Substituir valores
    for key, value in all_config.items():
        placeholder = f"{{{key}}}"
        if placeholder in template:
            template = template.replace(placeholder, value)
        else:
            # Adicionar se não existir no template
            template += f"\n{key}={value}"
    
    # Remover linhas vazias ou com apenas placeholders
    lines = template.split('\n')
    cleaned_lines = []
    for line in lines:
        if '{}' not in line and not line.strip().endswith('='):
            cleaned_lines.append(line)
    
    final_config = '\n'.join(cleaned_lines)
    
    # Garantir que diretório existe
    env_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Salvar arquivo
    with open(env_path, 'w') as f:
        f.write(final_config)
    
    # Configurar permissões (apenas Unix)
    if os.name != 'nt':
        os.chmod(env_path, 0o600)
    
    return env_path

def test_configuration():
    """Testa a configuração básica"""
    print_header("TESTANDO CONFIGURAÇÃO")
    
    tests_passed = 0
    total_tests = 3
    
    # Teste 1: Arquivo .env existe
    env_path = Path.home() / '.joana' / '.env'
    if env_path.exists():
        print_success(f"1. Arquivo .env criado: {env_path}")
        tests_passed += 1
    else:
        print_error("1. Arquivo .env não criado")
    
    # Teste 2: Diretórios criados
    data_dir = Path.home() / '.joana' / 'data'
    if data_dir.exists():
        print_success(f"2. Diretório de dados criado: {data_dir}")
        tests_passed += 1
    else:
        print_error("2. Diretório de dados não criado")
    
    # Teste 3: Executável da Joana
    joana_exe = Path.cwd() / 'joana'
    joana_android = Path.cwd() / 'joana_android'
    
    if joana_exe.exists() or joana_android.exists():
        print_success("3. Executável da Joana encontrado")
        tests_passed += 1
    else:
        print_error("3. Executável da Joana não encontrado")
        print_info("  Execute: go build -o joana cmd/joana/main.go")
    
    return tests_passed == total_tests

def show_next_steps():
    """Mostra próximos passos"""
    print_header("PRÓXIMOS PASSOS")
    
    platform = detect_platform()
    
    print_success("Configuração completa! 🎉")
    print_info("\nPara iniciar a Joana:")
    
    if platform == "android":
        print_info("  ./start_joana.sh")
        print_info("  OU")
        print_info("  ./joana_android")
    else:
        print_info("  ./start_joana.sh")
        print_info("  OU")
        print_info("  ./joana")
    
    print_info("\nPara verificar status:")
    print_info("  ./status_joana.sh")
    
    print_info("\nPara parar:")
    print_info("  ./stop_joana.sh")
    
    print_info("\nArquivo de configuração:")
    print_info(f"  {Path.home() / '.joana' / '.env'}")
    
    print_info("\nLogs:")
    print_info(f"  {Path.home() / '.joana' / 'logs'}")
    
    print_info("\nDocumentação:")
    print_info("  Consulte README.md para detalhes avançados")
    
    print_info("\nSuporte:")
    print_info("  Issues no GitHub: https://github.com/rmserver03/joana/issues")
    
    print(f"\n{Colors.GREEN}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.GREEN}{'JOANA CONFIGURADA COM SUCESSO!':^60}{Colors.END}")
    print(f"{Colors.GREEN}{'='*60}{Colors.END}\n")

def main():
    """Função principal"""
    try:
        print_header("ASSISTENTE DE CONFIGURAÇÃO DA JOANA")
        print_info("Este assistente vai guiá-lo na configuração da Joana.")
        print_info("Pressione Ctrl+C a qualquer momento para cancelar.\n")
        
        # Coletar todas as configurações
        all_config = {}
        
        # LLM API (obrigatória)
        llm_config = configure_llm_api()
        all_config.update(llm_config)
        
        # APIs opcionais
        if ask_yes_no("\nDeseja configurar integrações opcionais agora?", default=False):
            google_config = configure_google_apis()
            all_config.update(google_config)
            
            whatsapp_config = configure_whatsapp()
            all_config.update(whatsapp_config)
            
            telegram_config = configure_telegram()
            all_config.update(telegram_config)
        
        # Configurações do sistema
        system_config = configure_system_settings()
        all_config.update(system_config)
        
        # Salvar configuração
        print_header("SALVANDO CONFIGURAÇÃO")
        env_path = save_configuration(all_config)
        print_success(f"Configuração salva em: {env_path}")
        
        # Testar configuração
        if test_configuration():
            print_success("Todos os testes passaram!")
        else:
            print_warning("Alguns testes falharam. Verifique manualmente.")
        
        # Mostrar próximos passos
        show_next_steps()
        
    except KeyboardInterrupt:
        print("\n\n" + "="*60)
        print("Configuração cancelada pelo usuário.")
        print("="*60)
        sys.exit(0)
    except Exception as e:
        print_error(f"Erro durante a configuração: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()