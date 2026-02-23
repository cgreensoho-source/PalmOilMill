package routes

import (
	"sampling/controllers"
	"sampling/middleware"

	"github.com/gofiber/fiber/v2"
)

func SetupRoutes(app *fiber.App) {
	// 1. Serve Static Files
	app.Static("/upload", "./upload")

	api := app.Group("/api/v1")

	// --- Public Routes ---
	auth := api.Group("/auth")
	authController := controllers.NewAuthController()
	auth.Post("/register", authController.Register)
	auth.Post("/login", authController.Login)

	// --- Protected Routes (Login Required) ---
	protected := api.Group("", middleware.JWTMiddleware)

	// Inisialisasi Controller
	sampleController := controllers.NewSampleController()
	stationController := controllers.NewStationController()
	qrController := controllers.NewQRController()
	syncController := controllers.NewSyncController()
	adminCtrl := controllers.NewAdminUserController() // Pindah ke sini

	// Station routes
	station := protected.Group("/stations")
	station.Get("", stationController.GetStations)
	station.Post("/scan", stationController.ScanQR)

	// QR Code routes
	qr := protected.Group("/qr") // Dibedakan path-nya biar gak bentrok
	qr.Get("/:id", qrController.GenerateQR)
	qr.Get("/:id/data", qrController.GetQRData)

	// Sample & Log Sampling routes
	sample := protected.Group("/samples")
	sample.Post("", sampleController.CreateSample)
	sample.Get("", sampleController.GetAllSamples) // Log Server (Hanya Admin/Asisten di controller)
	sample.Get("/:id", sampleController.GetSampleDetail)

	// Image routes (Gak butuh login buat view file biasanya, atau sesuaikan kebutuhan)
	images := api.Group("/images")
	images.Get("/:id", sampleController.GetImage)

	// Sync routes
	protected.Post("/sync", syncController.SyncData)

	// --- Admin Only Routes (High Security) ---
	// PENTING: Gunakan middleware.AdminOnly buat bener-bener blokir user biasa
	adminOnly := protected.Group("/admin", middleware.AdminOnly)

	// CRUD User oleh Admin (Reset Password / Delete)
	adminOnly.Put("/users/:id", adminCtrl.UpdateUserByAdmin)
	adminOnly.Delete("/users/:id", adminCtrl.DeleteUser)

	api.Get("/samples/:id/print", sampleController.ExportSamplePDF)
}
