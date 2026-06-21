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

	// 2. Universal Middleware (CORS & Security)
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

	// 3. API Routes Group (Mobile & Web Data)
	api := router.Group("/api")
	{
		api.POST("/SignIn", bal.SignIn)
		api.POST("/Verify_OTP", bal.Verify_OTP)
		api.POST("/Send_OTP", bal.Send_OTP)
		api.POST("/Get_UserProfile", bal.Get_UserProfile)
		api.POST("/Update_Cususer", bal.Update_Cususer)

		// API Health Check
		api.GET("/status", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"status": "ok",
				"scope":  "api",
				"app":    "q-stocks-app",
				"time":   time.Now().Format(time.RFC3339),
			})
		})
	}

	// 4. Global Health Check (Root Level)
	router.GET("/status", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"scope":  "global",
			"app":    "q-stocks-app",
		})
	})

	// 5. Serve React Static Files
	// Note: Path adjusted to "../../Web/dist" based on your provided directory structure
	distPath := "../../Web/dist"

	// Serve the static assets (js, css, images)
	router.Static("/assets", distPath+"/assets")
	router.StaticFile("/favicon.ico", distPath+"/favicon.ico")
	router.StaticFile("/logo.png", distPath+"/logo.png")
	
	// Serve the main entry point
	router.StaticFile("/", distPath+"/index.html")

	// 6. SPA Handler (The "404 to index.html" logic)
	// Redirects all non-API web traffic back to the React index.html for React Router to handle
	router.NoRoute(func(c *gin.Context) {
		path := c.Request.URL.Path
		if !strings.HasPrefix(path, "/api") {
			c.File(distPath + "/index.html")
		} else {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "API endpoint not found"})
		}
	})

	// 7. Start Server
	port := ":5000"
	fmt.Printf("🚀 Q-Stocks Server running on http://localhost%s\n", port)
	if err := router.Run(port); err != nil {
		log.Fatalf("❌ Server failed to start: %v", err)
	}
}