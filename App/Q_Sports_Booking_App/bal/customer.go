package bal

import (
	"net/http"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-stocks-app/dal"
)

type Customer struct {
	ID             int     `json:"id"`
	Name           string  `json:"name"`
	Phone          string  `json:"phone"`
	CurrentBalance float64 `json:"current_balance"`
}

// GetAllCustomers returns active customers
func GetAllCustomers(c *gin.Context) {
	query := `SELECT id, name, COALESCE(phone, ''), current_balance 
	          FROM customers WHERE is_active = true ORDER BY name ASC`

	rows, err := dal.DB.Query(c.Request.Context(), query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": err.Error()})
		return
	}
	defer rows.Close()

	customers := []Customer{}
	for rows.Next() {
		var cust Customer
		rows.Scan(&cust.ID, &cust.Name, &cust.Phone, &cust.CurrentBalance)
		customers = append(customers, cust)
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": customers})
}

// CreateCustomer handles adding new customers
func CreateCustomer(c *gin.Context) {
	var cust Customer
	if err := c.ShouldBindJSON(&cust); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid input"})
		return
	}

	query := `INSERT INTO customers (name, phone, current_balance, is_active) 
	          VALUES ($1, $2, 0, true) RETURNING id`

	var lastID int
	err := dal.DB.QueryRow(c.Request.Context(), query, cust.Name, cust.Phone).Scan(&lastID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Save failed"})
		return
	}
	cust.ID = lastID
	c.JSON(http.StatusOK, gin.H{"success": true, "data": cust})
}

// GetCustomerLedger replicates the "Notebook" view logic
func GetCustomerLedger(c *gin.Context) {
	var req struct {
		CustomerID string `json:"customer_id"`
	}
	c.ShouldBindJSON(&req)

	query := `
		SELECT 
			transaction_date, 
			weight, 
			rate, 
			debit_amount, 
			credit_amount, 
			running_balance,
			COALESCE(remarks, '')
		FROM customer_ledger 
		WHERE customer_id = $1 
		ORDER BY transaction_date DESC`

	rows, err := dal.DB.Query(c.Request.Context(), query, req.CustomerID)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Ledger fetch failed"})
		return
	}
	defer rows.Close()

	var ledger []interface{}
	for rows.Next() {
		var date, remarks string
		var w, r, d, c, bal float64
		rows.Scan(&date, &w, &r, &d, &c, &bal, &remarks)
		ledger = append(ledger, gin.H{
			"transaction_date": date,
			"weight":           w,
			"rate":             r,
			"debit_amount":     d,
			"credit_amount":    c,
			"running_balance":  bal,
			"remarks":          remarks,
		})
	}
	c.JSON(200, gin.H{"success": true, "data": ledger})
}
