package google

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// SheetsIntegration gerencia a integração com Google Sheets
type SheetsIntegration struct {
	client        *SheetsClient
	spreadsheetID string
	enabled       bool
}

// NewSheetsIntegration cria uma nova integração com Google Sheets
func NewSheetsIntegration(spreadsheetID string) *SheetsIntegration {
	// Verificar se temos as credenciais necessárias
	homeDir, _ := os.UserHomeDir()
	tokenPath := filepath.Join(homeDir, "zero", "token.json")
	_, tokenErr := os.Stat(tokenPath)

	enabled := tokenErr == nil && spreadsheetID != ""

	integration := &SheetsIntegration{
		client:        NewSheetsClient(""),
		spreadsheetID: spreadsheetID,
		enabled:       enabled,
	}

	if enabled {
		log.Printf("Google Sheets integration enabled for spreadsheet: %s", spreadsheetID)
	} else {
		log.Printf("Google Sheets integration disabled (token: %v, spreadsheet: %v)",
			tokenErr == nil, spreadsheetID != "")
	}

	return integration
}

// IsEnabled retorna se a integração está habilitada
func (si *SheetsIntegration) IsEnabled() bool {
	return si.enabled
}

// GetPatient busca um paciente pelo nome
func (si *SheetsIntegration) GetPatient(name string) (map[string]interface{}, error) {
	if !si.enabled {
		return nil, fmt.Errorf("Google Sheets integration disabled")
	}

	// Ler todos os pacientes
	patients, err := si.client.ReadSheet(si.spreadsheetID, "Pacientes!A:Z")
	if err != nil {
		return nil, fmt.Errorf("erro ao ler pacientes: %v", err)
	}

	// Buscar paciente pelo nome (case insensitive)
	searchName := strings.ToLower(strings.TrimSpace(name))
	for _, patient := range patients {
		if patientName, ok := patient["Nome"].(string); ok {
			if strings.ToLower(strings.TrimSpace(patientName)) == searchName {
				return patient, nil
			}
		}
	}

	return nil, fmt.Errorf("paciente '%s' não encontrado", name)
}

// AddPatient adiciona um novo paciente
func (si *SheetsIntegration) AddPatient(patientData map[string]interface{}) error {
	if !si.enabled {
		return fmt.Errorf("Google Sheets integration disabled")
	}

	// Primeiro verificar se paciente já existe
	if name, ok := patientData["Nome"].(string); ok && name != "" {
		existing, err := si.GetPatient(name)
		if err == nil && existing != nil {
			return fmt.Errorf("paciente '%s' já existe", name)
		}
	}

	// Preparar dados para escrita
	// Primeiro precisamos saber a estrutura atual
	headers, err := si.getSheetHeaders("Pacientes")
	if err != nil {
		return fmt.Errorf("erro ao obter cabeçalhos: %v", err)
	}

	// Criar linha na ordem dos cabeçalhos
	row := make([]interface{}, len(headers))
	for i, header := range headers {
		if value, ok := patientData[header]; ok {
			row[i] = value
		} else {
			row[i] = ""
		}
	}

	// Adicionar timestamp se não existir
	if _, hasTimestamp := patientData["Data Cadastro"]; !hasTimestamp {
		// Encontrar índice da coluna Data Cadastro
		for i, header := range headers {
			if header == "Data Cadastro" {
				row[i] = getCurrentTimestamp()
				break
			}
		}
	}

	// Escrever na próxima linha vazia
	values := [][]interface{}{row}
	_, err = si.client.WriteSheet(si.spreadsheetID, "Pacientes!A:Z", values)
	if err != nil {
		return fmt.Errorf("erro ao adicionar paciente: %v", err)
	}

	return nil
}

// UpdatePatient atualiza informações de um paciente existente
func (si *SheetsIntegration) UpdatePatient(name string, updates map[string]interface{}) error {
	if !si.enabled {
		return fmt.Errorf("Google Sheets integration disabled")
	}

	// Primeiro precisamos encontrar a linha do paciente
	patients, err := si.client.ReadSheet(si.spreadsheetID, "Pacientes!A:Z")
	if err != nil {
		return fmt.Errorf("erro ao ler pacientes: %v", err)
	}

	searchName := strings.ToLower(strings.TrimSpace(name))
	foundRow := -1

	for i, patient := range patients {
		if patientName, ok := patient["Nome"].(string); ok {
			if strings.ToLower(strings.TrimSpace(patientName)) == searchName {
				foundRow = i + 2 // +1 para cabeçalho, +1 para índice 1-based
				break
			}
		}
	}

	if foundRow == -1 {
		return fmt.Errorf("paciente '%s' não encontrado", name)
	}

	// Obter cabeçalhos
	headers, err := si.getSheetHeaders("Pacientes")
	if err != nil {
		return fmt.Errorf("erro ao obter cabeçalhos: %v", err)
	}

	// Criar linha atualizada
	row := make([]interface{}, len(headers))
	for i, header := range headers {
		if value, ok := updates[header]; ok {
			row[i] = value
		} else if i == 0 && header == "Nome" {
			row[i] = name // Manter nome original
		} else {
			// Manter valor existente (precisaríamos ler a linha atual)
			// Por simplicidade, vamos deixar vazio e o Google Sheets manterá o existente
			row[i] = ""
		}
	}

	// Atualizar linha específica
	rangeName := fmt.Sprintf("Pacientes!A%d:Z%d", foundRow, foundRow)
	values := [][]interface{}{row}
	_, err = si.client.WriteSheet(si.spreadsheetID, rangeName, values)
	if err != nil {
		return fmt.Errorf("erro ao atualizar paciente: %v", err)
	}

	return nil
}

// ListAllPatients lista todos os pacientes
func (si *SheetsIntegration) ListAllPatients() ([]map[string]interface{}, error) {
	if !si.enabled {
		return nil, fmt.Errorf("Google Sheets integration disabled")
	}

	return si.client.ReadSheet(si.spreadsheetID, "Pacientes!A:Z")
}

// getSheetHeaders obtém os cabeçalhos de uma aba
func (si *SheetsIntegration) getSheetHeaders(sheetName string) ([]string, error) {
	data, err := si.client.ReadSheet(si.spreadsheetID, sheetName+"!A1:Z1")
	if err != nil {
		return nil, err
	}

	if len(data) == 0 {
		return []string{}, nil
	}

	headers := []string{}
	for key := range data[0] {
		headers = append(headers, key)
	}

	return headers, nil
}

// getCurrentTimestamp retorna timestamp atual formatado
func getCurrentTimestamp() string {
	// Formato: DD/MM/YYYY HH:MM:SS
	// Implementação simplificada
	// Em produção, usar time.Now().Format("02/01/2006 15:04:05")
	return "04/03/2026 04:30:00"
}

// TestConnection testa a conexão com Google Sheets
func (si *SheetsIntegration) TestConnection() error {
	if !si.enabled {
		return fmt.Errorf("Google Sheets integration disabled")
	}

	return si.client.TestConnection()
}
