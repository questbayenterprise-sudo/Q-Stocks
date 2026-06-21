package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"

	bal "github.com/qsports/q-stocks-app/bal"
	dal "github.com/qsports/q-stocks-app/dal"
)

func main() {
	// 1. Initialize Database
	err := dal.ConnectPostgres()
	if err != nil {
		log.Fatal("❌ Database connection failed: ", err)
	}
	fmt.Println("✅ Successfully connected to q_stocks_db")

	router := gin.Default()

	// 2. Universal Middleware (CORS & Security) - MUST BE FIRST
	router.Use(func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		// Allow React Dev (5173) and same-origin requests
		if origin == "http://localhost:5173" || origin == "" {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
		}

		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		// Handle Preflight (OPTIONS)
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	})

	// 3. Serve Physical Uploads Folder
	// Now that CORS is applied, the browser can fetch these files safely
	router.Static("/uploads", "./uploads")

	// 4. API Routes Group
	api := router.Group("/api")
	{
		api.POST("/SignIn", bal.SignIn)
		api.POST("/Verify_OTP", bal.Verify_OTP)
		api.POST("/Get_UserProfile", bal.Get_UserProfile)
		api.POST("/Update_Cususer", bal.Update_Cususer)
		api.POST("/GetShopAnalytics", bal.GetShopAnalytics)
		api.POST("/GetRecentSales", bal.GetRecentSales)
		api.POST("/Shop_overall_list", bal.Shop_overall_list)
		api.POST("/SaveShop", bal.SaveShop)
		api.POST("/ProcessSale", bal.ProcessSale)

		api.POST("/DeleteShop", bal.DeleteShop)
		api.POST("/GetProducts", bal.GetProducts)
		api.POST("/SaveProduct", bal.SaveProduct)
		api.POST("/DeleteProduct", bal.DeleteProduct)
		api.GET("/GetAllCustomers", bal.GetAllCustomers)
		api.POST("/CreateCustomer", bal.CreateCustomer)
		api.POST("/GetCustomerLedger", bal.GetCustomerLedger)
		api.GET("/status", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"status": "ok",
				"scope":  "api",
				"app":    "q-stocks-app",
				"time":   time.Now().Format(time.RFC3339),
			})
		})
	}

	// 5. Global Health Check
	router.GET("/status", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"scope":  "global",
			"app":    "q-stocks-app",
		})
	})

	// 6. Serve React Static Files
	distPath := "../../Web/dist"
	router.Static("/assets", distPath+"/assets")
	router.StaticFile("/favicon.ico", distPath+"/favicon.ico")
	router.StaticFile("/logo.png", distPath+"/logo.png")
	router.StaticFile("/", distPath+"/index.html")

	// 7. SPA Handler (The Logic Fix)
	router.NoRoute(func(c *gin.Context) {
		path := c.Request.URL.Path

		// If the request is for an API or an Upload but reached here, it means the file is truly missing.
		// We return a 404 JSON instead of index.html so images don't "soft fail".
		if strings.HasPrefix(path, "/api") || strings.HasPrefix(path, "/uploads") {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Resource not found"})
			return
		}

		// Otherwise, serve index.html for React Router to handle
		c.File(distPath + "/index.html")
	})

	// 8. Start Server
	port := ":5000"
	fmt.Printf("🚀 Q-Stocks Server running on http://localhost%s\n", port)
	if err := router.Run(port); err != nil {
		log.Fatalf("❌ Server failed to start: %v", err)
	}
}
