package google

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// SheetsClient é o cliente HTTP para o microserviço Google Sheets
type SheetsClient struct {
	baseURL    string
	httpClient *http.Client
}

// NewSheetsClient cria um novo cliente Google Sheets
func NewSheetsClient(baseURL string) *SheetsClient {
	if baseURL == "" {
		baseURL = "http://localhost:28794"
	}

	return &SheetsClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 15 * time.Second,
		},
	}
}

// HealthCheck verifica se o microserviço está saudável
func (c *SheetsClient) HealthCheck() (bool, error) {
	resp, err := c.httpClient.Get(c.baseURL + "/api/health")
	if err != nil {
		return false, fmt.Errorf("erro ao verificar saúde do serviço: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return false, fmt.Errorf("serviço retornou status %d", resp.StatusCode)
	}

	return true, nil
}

// ReadSheet lê dados de uma planilha
func (c *SheetsClient) ReadSheet(spreadsheetID, rangeName string) ([]map[string]interface{}, error) {
	requestBody := map[string]string{
		"spreadsheet_id": spreadsheetID,
		"range":          rangeName,
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return nil, fmt.Errorf("erro ao serializar request: %v", err)
	}

	resp, err := c.httpClient.Post(
		c.baseURL+"/api/sheets/read",
		"application/json",
		bytes.NewBuffer(jsonBody),
	)
	if err != nil {
		return nil, fmt.Errorf("erro na requisição HTTP: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler resposta: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		var errorResp map[string]interface{}
		if err := json.Unmarshal(body, &errorResp); err == nil {
			if errMsg, ok := errorResp["error"].(string); ok {
				return nil, fmt.Errorf("erro do servidor: %s", errMsg)
			}
		}
		return nil, fmt.Errorf("status %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		Success   bool                     `json:"success"`
		Data      []map[string]interface{} `json:"data"`
		TotalRows int                      `json:"total_rows"`
		Error     string                   `json:"error,omitempty"`
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("erro ao decodificar resposta: %v", err)
	}

	if !result.Success {
		return nil, fmt.Errorf("serviço retornou erro: %s", result.Error)
	}

	return result.Data, nil
}

// WriteSheet escreve dados em uma planilha
func (c *SheetsClient) WriteSheet(spreadsheetID, rangeName string, values [][]interface{}) (map[string]interface{}, error) {
	requestBody := map[string]interface{}{
		"spreadsheet_id": spreadsheetID,
		"range":          rangeName,
		"values":         values,
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return nil, fmt.Errorf("erro ao serializar request: %v", err)
	}

	resp, err := c.httpClient.Post(
		c.baseURL+"/api/sheets/write",
		"application/json",
		bytes.NewBuffer(jsonBody),
	)
	if err != nil {
		return nil, fmt.Errorf("erro na requisição HTTP: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler resposta: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		var errorResp map[string]interface{}
		if err := json.Unmarshal(body, &errorResp); err == nil {
			if errMsg, ok := errorResp["error"].(string); ok {
				return nil, fmt.Errorf("erro do servidor: %s", errMsg)
			}
		}
		return nil, fmt.Errorf("status %d: %s", resp.StatusCode, string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("erro ao decodificar resposta: %v", err)
	}

	if success, ok := result["success"].(bool); !ok || !success {
		return nil, fmt.Errorf("escrita falhou: %v", result)
	}

	return result, nil
}

// ListSheets lista todas as abas de uma planilha
func (c *SheetsClient) ListSheets(spreadsheetID string) ([]map[string]interface{}, error) {
	requestBody := map[string]string{
		"spreadsheet_id": spreadsheetID,
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return nil, fmt.Errorf("erro ao serializar request: %v", err)
	}

	resp, err := c.httpClient.Post(
		c.baseURL+"/api/sheets/sheets",
		"application/json",
		bytes.NewBuffer(jsonBody),
	)
	if err != nil {
		return nil, fmt.Errorf("erro na requisição HTTP: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler resposta: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		var errorResp map[string]interface{}
		if err := json.Unmarshal(body, &errorResp); err == nil {
			if errMsg, ok := errorResp["error"].(string); ok {
				return nil, fmt.Errorf("erro do servidor: %s", errMsg)
			}
		}
		return nil, fmt.Errorf("status %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		Success          bool                     `json:"success"`
		Sheets           []map[string]interface{} `json:"sheets"`
		SpreadsheetTitle string                   `json:"spreadsheet_title"`
		Error            string                   `json:"error,omitempty"`
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("erro ao decodificar resposta: %v", err)
	}

	if !result.Success {
		return nil, fmt.Errorf("serviço retornou erro: %s", result.Error)
	}

	return result.Sheets, nil
}

// TestConnection testa a conexão com o microserviço
func (c *SheetsClient) TestConnection() error {
	healthy, err := c.HealthCheck()
	if err != nil {
		return fmt.Errorf("falha no health check: %v", err)
	}

	if !healthy {
		return fmt.Errorf("serviço reportou não saudável")
	}

	return nil
}
