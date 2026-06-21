package bal

import (
	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-stocks-app/dal"
)

// ============================================================
// 1. INCOME / PAYMENT LOGIC
// ============================================================

// GetIncomeHistory - Fetches all customer payments
func GetIncomeHistory(c *gin.Context) {
	query := `
		SELECT l.id, c.name, l.credit_amount, l.transaction_date, COALESCE(l.remarks, '')
		FROM customer_ledger l
		JOIN customers c ON l.customer_id = c.id
		WHERE l.credit_amount > 0
		ORDER BY l.transaction_date DESC`

	rows, err := dal.DB.Query(c.Request.Context(), query)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": err.Error()})
		return
	}
	defer rows.Close()

	results := []gin.H{}
	for rows.Next() {
		var id int
		var name, date, rem string
		var amt float64
		rows.Scan(&id, &name, &amt, &date, &rem)
		results = append(results, gin.H{
			"id":               id,
			"customer_name":    name,
			"amount":           amt,
			"transaction_date": date,
			"remarks":          rem,
		})
	}
	c.JSON(200, gin.H{"success": true, "data": results})
}

// SaveIncome - Records a payment and reduces customer balance
func SaveIncome(c *gin.Context) {
	var req struct {
		CustomerID int     `json:"customer_id"`
		ShopID     int     `json:"shop_id"`
		Amount     float64 `json:"amount"`
		Remarks    string  `json:"remarks"`
	}
	c.ShouldBindJSON(&req)
	ctx := c.Request.Context()

	tx, _ := dal.DB.Begin(ctx)
	defer tx.Rollback(ctx)

	// 1. Reduce Customer Balance
	_, err := tx.Exec(ctx, `UPDATE customers SET current_balance = current_balance - $1 WHERE id = $2`, req.Amount, req.CustomerID)

	// 2. Get New Balance for Snapshot
	var newBal float64
	tx.QueryRow(ctx, `SELECT current_balance FROM customers WHERE id = $1`, req.CustomerID).Scan(&newBal)

	// 3. Insert into Ledger
	query := `INSERT INTO customer_ledger (customer_id, shop_id, debit_amount, credit_amount, running_balance, remarks, transaction_date)
	          VALUES ($1, $2, 0, $3, $4, $5, NOW())`
	_, err = tx.Exec(ctx, query, req.CustomerID, req.ShopID, req.Amount, newBal, req.Remarks)

	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Save failed"})
		return
	}

	tx.Commit(ctx)
	c.JSON(200, gin.H{"success": true})
}

// ============================================================
// 2. STOCK MANAGEMENT LOGIC
// ============================================================

func GetStocks(c *gin.Context) {
	// Joining stocks with products and shops to show the full status
	query := `
		SELECT s.id, p.name, sh.name as shop_name, p.uom, s.current_qty, s.min_stock_lvl, s.product_id, s.shop_id
		FROM stocks s
		JOIN products p ON s.product_id = p.id
		JOIN shops sh ON s.shop_id = sh.id
		ORDER BY sh.name ASC, p.name ASC`

	rows, _ := dal.DB.Query(c.Request.Context(), query)
	defer rows.Close()

	results := []gin.H{}
	for rows.Next() {
		var id, pid, sid int
		var pName, sName, uom string
		var qty, min float64
		rows.Scan(&id, &pName, &sName, &uom, &qty, &min, &pid, &sid)
		results = append(results, gin.H{
			"id":            id,
			"product_name":  pName,
			"shop_name":     sName,
			"uom":           uom,
			"current_qty":   qty,
			"min_stock_lvl": min,
			"product_id":    pid,
			"shop_id":       sid,
		})
	}
	c.JSON(200, gin.H{"success": true, "data": results})
}

func UpdateStock(c *gin.Context) {
	var req struct {
		ShopID    int     `json:"shop_id"`
		ProductID int     `json:"product_id"`
		Quantity  float64 `json:"quantity"`
		MinLevel  float64 `json:"min_level"`
	}
	c.ShouldBindJSON(&req)

	query := `
		INSERT INTO stocks (shop_id, product_id, current_qty, min_stock_lvl, updated_at)
		VALUES ($1, $2, $3, $4, NOW())
		ON CONFLICT (shop_id, product_id) 
		DO UPDATE SET current_qty = EXCLUDED.current_qty, min_stock_lvl = EXCLUDED.min_stock_lvl, updated_at = NOW()`

	_, err := dal.DB.Exec(c.Request.Context(), query, req.ShopID, req.ProductID, req.Quantity, req.MinLevel)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": err.Error()})
		return
	}
	c.JSON(200, gin.H{"success": true})
}
