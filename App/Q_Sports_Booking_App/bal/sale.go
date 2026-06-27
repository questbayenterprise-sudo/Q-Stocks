package bal

import (
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-stocks-app/dal"
)

// --- Helper for Type-Safe JSON Parsing ---
// This handles cases where React sends "1" (string) and Go expects 1 (int)
func AnyToInt(val interface{}) int {
	switch v := val.(type) {
	case int:
		return v
	case float64:
		return int(v)
	case string:
		i, _ := strconv.Atoi(v)
		return i
	default:
		return 0
	}
}

// --- Request Structures ---

type SaleItemRequest struct {
	ProductID interface{} `json:"product_id"` // Flexible type
	Quantity  float64     `json:"quantity"`
	Price     float64     `json:"price"`
	Total     float64     `json:"total"`
}

type ProcessSaleRequest struct {
	CustomerID interface{}       `json:"customer_id"` // Flexible type
	ShopID     interface{}       `json:"shop_id"`     // Flexible type
	Total      float64           `json:"total_amount"`
	Paid       float64           `json:"paid_amount"`
	Status     string            `json:"status"` // 'COMPLETED' or 'DRAFT'
	Items      []SaleItemRequest `json:"items"`
}

// ============================================================
// PROCESS SALE (The Master Transaction)
// ============================================================
func ProcessSale(c *gin.Context) {
	var req ProcessSaleRequest
	ctx := c.Request.Context()

	// 1. Bind JSON (Flexible types prevent the "product_id" string vs int error)
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid JSON format: " + err.Error()})
		return
	}

	// 2. Start PostgreSQL Transaction
	tx, err := dal.DB.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Could not start transaction"})
		return
	}
	defer tx.Rollback(ctx)

	// 3. Prepare Master Data
	invoiceNo := fmt.Sprintf("INV-%d", time.Now().Unix())
	customerID := AnyToInt(req.CustomerID)
	shopID := AnyToInt(req.ShopID)
	balanceDue := req.Total - req.Paid

	// 4. Insert into 'orders' (Master Table)
	var orderID int
	queryOrder := `
			INSERT INTO orders (order_ref, shop_id, customer_id, total_amount, paid_amount, balance_due, status, created_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) 
			RETURNING id`

	err = tx.QueryRow(ctx, queryOrder, invoiceNo, shopID, customerID, req.Total, req.Paid, balanceDue, req.Status).Scan(&orderID)
	if err != nil {
		log.Printf("Order Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to create order master"})
		return
	}

	// 5. Process individual items (Detail Table)
	for _, item := range req.Items {
		pID := AnyToInt(item.ProductID)
		if pID == 0 {
			continue
		}

		// A. Insert into 'order_items'
		queryItem := `
				INSERT INTO order_items (order_id, product_id, weight, rate, sub_total)
				VALUES ($1, $2, $3, $4, $5)`
		_, err = tx.Exec(ctx, queryItem, orderID, pID, item.Quantity, item.Price, item.Total)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to save item details"})
			return
		}

		// B. Update Inventory (Deduct Stock)
		if req.Status == "COMPLETED" {
			queryStock := `
					UPDATE stocks 
					SET current_qty = current_qty - $1, updated_at = NOW()
					WHERE shop_id = $2 AND product_id = $3`
			_, err = tx.Exec(ctx, queryStock, item.Quantity, shopID, pID)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Inventory deduction failed"})
				return
			}
		}
	}

	// 6. Update Customer Ledger & Current Balance (Notebook Logic)
	// We skip this if CustomerID is 0 (Walk-in/Guest)
	if customerID > 0 {
		// Update current balance in customers table
		_, err = tx.Exec(ctx, `UPDATE customers SET current_balance = current_balance + $1 WHERE id = $2`, balanceDue, customerID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to update customer balance"})
			return
		}

		// Fetch the new updated balance to store it as a 'snapshot' in the ledger
		var newRunningBalance float64
		_ = tx.QueryRow(ctx, `SELECT current_balance FROM customers WHERE id = $1`, customerID).Scan(&newRunningBalance)

		// Insert the "Notebook" entry (Matches your handwritten sketch)
		queryLedger := `
				INSERT INTO customer_ledger (customer_id, shop_id, order_id, transaction_date, debit_amount, credit_amount, running_balance, remarks)
				VALUES ($1, $2, $3, NOW(), $4, $5, $6, $7)`

		remarks := fmt.Sprintf("Sale: %s", invoiceNo)
		_, err = tx.Exec(ctx, queryLedger, customerID, shopID, orderID, req.Total, req.Paid, newRunningBalance, remarks)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Ledger entry failed"})
			return
		}
	}

	// 7. Commit Transaction
	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Final database commit failed"})
		return
	}

	// 8. Return Success
	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Sale completed successfully",
		"invoice_no": invoiceNo,
		"order_id":   orderID,
	})
}
