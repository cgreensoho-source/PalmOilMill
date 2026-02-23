package main

import (
	"log"
	"sampling/config"
	"sampling/routes"

	// 1. IMPORT DOCS (WAJIB: pake underscore agar init() dijalankan)
	_ "sampling/docs"

	// 2. IMPORT SWAGGER FIBER
	"github.com/gofiber/swagger"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

// @title                       API Sistem Sampling Digital
// @version                     1.0
// @description                 Dokumentasi API untuk pengumpulan sampel lapangan, validasi GPS, dan sinkronisasi data offline.
// @termsOfService              http://swagger.io/terms/

// @contact.name                Tim Dev Kompetisi
// @contact.url                 http://www.yourdomain.com

// @host                        localhost:3000
// @BasePath                    /api/v1

// @securityDefinitions.apikey  BearerAuth
// @in                          header
// @name                        Authorization
// @description                 Masukkan token dengan format: Bearer <your_token>

func main() {
	// Inisialisasi Fiber
	app := fiber.New(fiber.Config{
		AppName: "Sampling Digital API v1.0",
	})

	// ===============================
	// MIDDLEWARE
	// ===============================
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
	}))

	// ===============================
	// DATABASE CONNECTION
	// ===============================
	config.ConnectDatabase()

	// ===============================
	// STATIC FILES (Untuk akses foto upload)
	// ===============================
	app.Static("/upload", "./upload")

	// ===============================
	// SWAGGER ROUTE
	// ===============================
	// Route untuk dokumentasi API
	app.Get("/swagger/*", swagger.HandlerDefault)

	// ===============================
	// SETUP API ROUTES
	// ===============================
	routes.SetupRoutes(app)

	// Default Landing Page
	app.Get("/", func(c *fiber.Ctx) error {
		return c.Status(200).JSON(fiber.Map{
			"message": "Backend Sampling API is running",
			"docs":    "/swagger/index.html",
		})
	})

	// Start Server
	log.Fatal(app.Listen(":3000"))
}
