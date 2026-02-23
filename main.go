package main

import (
	"log"
	"sampling/config"
	"sampling/routes"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

func main() {
	app := fiber.New()

	// Middleware
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
	}))

	// Inisialisasi Database
	config.ConnectDatabase()

	// Setup Routes
	routes.SetupRoutes(app)

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("Backend Sampling API Running...")
	})

	log.Fatal(app.Listen(":3000"))
}
