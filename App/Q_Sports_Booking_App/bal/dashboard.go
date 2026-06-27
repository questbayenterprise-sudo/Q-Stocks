package bal

import (
	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-stocks-app/dal"
	"log"
	"net/http"
)

// Mapping to your React/Flutter expectations
type ShopAnalytics struct {
	TotalSales      float64       `json:"total_revenue"`  // Sum(orders.total_amount)
	TotalStockValue float64       `json:"total_bookings"` // Sum(stocks.current_qty)
	CustomerDues    float64       `json:"occupancy"`      // Sum(customers.current_balance)
	WeeklyTrend     []WeeklyTrend `json:"weekly_trend"`
}

type WeeklyTrend struct {
	Day   string `json:"day_name"`
	Count int    `json:"total_bookings"`
}

func GetShopAnalytics(c *gin.Context) {
	ctx := c.Request.Context()
	var stats ShopAnalytics
	stats.WeeklyTrend = []WeeklyTrend{}

	// 1. Fetch Totals using your specific tables
	// COALESCE ensures no 500 error if tables are empty
	query := `
		SELECT 
			(SELECT COALESCE(SUM(total_amount), 0) FROM orders) as total_sales,
			(SELECT COALESCE(SUM(current_qty), 0) FROM stocks) as stock_weight,
			(SELECT COALESCE(SUM(current_balance), 0) FROM customers) as total_dues
	`
	err := dal.DB.QueryRow(ctx, query).Scan(
		&stats.TotalSales,
		&stats.TotalStockValue,
		&stats.CustomerDues,
	)

	if err != nil {
		log.Printf("Error: %v", err)
		c.JSON(500, gin.H{"success": false, "message": "Database query failed"})
		return
	}

	// 2. Fetch Weekly Trend from 'orders' table
	trendQuery := `
		SELECT 
			TO_CHAR(d.day, 'Dy') AS day_name,
			COUNT(o.id)::int AS total_sales
		FROM (
			SELECT generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, '1 day')::date AS day
		) d
		LEFT JOIN orders o ON DATE(o.created_at) = d.day
		GROUP BY d.day
		ORDER BY d.day ASC;
	`
	rows, err := dal.DB.Query(ctx, trendQuery)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var t WeeklyTrend
			if err := rows.Scan(&t.Day, &t.Count); err == nil {
				stats.WeeklyTrend = append(stats.WeeklyTrend, t)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": stats})
}

func GetRecentSales(c *gin.Context) {
	var req struct {
		Limit int `json:"limit"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		req.Limit = 5
	}

	// Joining 'orders' with 'customers' table as per your schema
	query := `
		SELECT 
			o.id, 
			o.order_ref, 
			COALESCE(c.name, 'Walk-in') as customer_name, 
			o.total_amount, 
			o.status,
			TO_CHAR(o.created_at, 'YYYY-MM-DD HH24:MI') as created_at
		FROM orders o
		LEFT JOIN customers c ON o.customer_id = c.id
		ORDER BY o.created_at DESC
		LIMIT $1
	`
	rows, err := dal.DB.Query(c.Request.Context(), query, req.Limit)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "message": "Failed to fetch sales"})
		return
	}
	defer rows.Close()

	var sales []interface{}
	for rows.Next() {
		var id int
		var ref, name, status, date string
		var amt float64
		if err := rows.Scan(&id, &ref, &name, &amt, &status, &date); err == nil {
			sales = append(sales, gin.H{
				"id":          id,
				"booking_ref": ref,
				"user_name":   name,
				"price":       amt,
				"status":      status,
				"start_time":  date,
			})
		}
	}
	c.JSON(200, gin.H{"success": true, "data": sales})
}
