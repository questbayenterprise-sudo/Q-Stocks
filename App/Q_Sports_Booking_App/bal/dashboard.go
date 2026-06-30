package bal

import (
	"github.com/gin-gonic/gin"
	dal "github.com/qsports/q-stocks-app/dal"
	"log"
	"net/http"
)
type ShopAnalytics struct {
	TodaySales      float64       `json:"today_sales"`    // Today only
	WeeklySales     float64       `json:"weekly_sales"`   // Last 7 days
	MonthlySales    float64       `json:"monthly_sales"`  // Last 30 days
	TotalStockValue float64       `json:"total_stock"`    // Matches React "Stock (kg)"
	CustomerDues    float64       `json:"total_pending"`  // Matches React "Pending Dues"
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

	// SQL Logic:
	// We use FILTER (WHERE ...) to get sums for specific time periods in one query
	query := `
		SELECT 
			COALESCE(SUM(total_amount) FILTER (WHERE created_at >= CURRENT_DATE), 0) as today_sales,
			COALESCE(SUM(total_amount) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'), 0) as weekly_sales,
			COALESCE(SUM(total_amount) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'), 0) as monthly_sales,
			(SELECT COALESCE(SUM(current_qty), 0) FROM stocks) as stock_weight,
			(SELECT COALESCE(SUM(current_balance), 0) FROM customers) as total_dues
		FROM orders
	`
	
	err := dal.DB.QueryRow(ctx, query).Scan(
		&stats.TodaySales,
		&stats.WeeklySales,
		&stats.MonthlySales,
		&stats.TotalStockValue,
		&stats.CustomerDues,
	)

	if err != nil {
		log.Printf("Error fetching analytics: %v", err)
		c.JSON(500, gin.H{"success": false, "message": "Database query failed"})
		return
	}

	// 3. Fetch Weekly Trend (Keep this as is, it's already correct for the chart)
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
