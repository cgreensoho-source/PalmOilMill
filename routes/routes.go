package routes

import (
	"sampling/controllers"
	"sampling/middleware"

	"github.com/gofiber/fiber/v2"
)

func SetupRoutes(app *fiber.App) {
	api := app.Group("/api/v1")

	// Auth routes
	auth := api.Group("/auth")
	authController := controllers.NewAuthController()
	auth.Post("/register", authController.Register)
	auth.Post("/login", authController.Login)

	// Protected routes
	protected := api.Group("", middleware.JWTMiddleware)

	// Station routes
	station := protected.Group("/stations")
	stationController := controllers.NewStationController()
	station.Get("", stationController.GetStations)
	station.Post("/scan", stationController.ScanQR)

	// QR Code routes (protected)
	qr := protected.Group("/stations")
	qrController := controllers.NewQRController()
	qr.Get("/:id/qr", qrController.GenerateQR)
	qr.Get("/:id", qrController.GetStationWithQR)
	qr.Get("/:id/qr-data", qrController.GetQRData)

	// Sample routes
	sample := protected.Group("/samples")
	sampleController := controllers.NewSampleController()
	sample.Post("", sampleController.CreateSample)
	sample.Get("", sampleController.GetAllSamples)
	sample.Get("/:id", sampleController.GetSampleDetail)

	// Image routes (public - serve uploaded images)
	images := api.Group("/images")
	images.Get("/:id", sampleController.GetImage)

	// Sync routes
	sync := protected.Group("/sync")
	syncController := controllers.NewSyncController()
	sync.Post("", syncController.SyncData)
}
