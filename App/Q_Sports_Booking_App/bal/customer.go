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

func GetCustomerLedger(c *gin.Context) {
	var req struct {
		CustomerID string `json:"customer_id"`
		Page       int    `json:"page"`  // New
		Limit      int    `json:"limit"` // New
	}

	// Default values
	if err := c.ShouldBindJSON(&req); err != nil {
		req.Page = 1
		req.Limit = 10
	}

	if req.Page <= 0 {
		req.Page = 1
	}
	if req.Limit <= 0 {
		req.Limit = 10
	}
	offset := (req.Page - 1) * req.Limit

	// 1. Get Total Count (For pagination UI)
	var totalCount int
	countQuery := `SELECT COUNT(*) FROM customer_ledger WHERE customer_id = $1`
	dal.DB.QueryRow(c.Request.Context(), countQuery, req.CustomerID).Scan(&totalCount)

	// 2. Fetch Paginated Data
	query := `
		SELECT 
			transaction_date, 
			COALESCE(weight, 0), 
			COALESCE(rate, 0), 
			COALESCE(debit_amount, 0), 
			COALESCE(credit_amount, 0), 
			COALESCE(running_balance, 0),
			COALESCE(remarks, '')
		FROM customer_ledger 
		WHERE customer_id = $1 
		ORDER BY transaction_date DESC
		LIMIT $2 OFFSET $3`

	rows, err := dal.DB.Query(c.Request.Context(), query, req.CustomerID, req.Limit, offset)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Ledger fetch failed"})
		return
	}
	defer rows.Close()

	ledger := []interface{}{}
	for rows.Next() {
		var date interface{}
		var remarks string
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

	// 3. Return data with pagination metadata
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    ledger,
		"pagination": gin.H{
			"total_records": totalCount,
			"current_page":  req.Page,
			"limit":         req.Limit,
			"total_pages":   (totalCount + req.Limit - 1) / req.Limit,
		},
	})
}
