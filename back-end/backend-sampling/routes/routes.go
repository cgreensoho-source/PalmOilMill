package routes

import (
	"sampling/controllers"
	"sampling/middleware"

	"github.com/gofiber/fiber/v2"
)

func SetupRoutes(app *fiber.App) {
	// 1. Serve Static Files (Untuk akses foto sampling)
	app.Static("/upload", "./upload")

	// Base Group API v1
	api := app.Group("/api/v1")

	// ===============================
	// PUBLIC ROUTES (Tanpa Login)
	// ===============================
	auth := api.Group("/auth")
	authController := controllers.NewAuthController()
	auth.Post("/register", authController.Register)
	auth.Post("/login", authController.Login)

	// ===============================
	// PROTECTED ROUTES (Butuh Login)
	// ===============================
	protected := api.Group("", middleware.JWTMiddleware)

	// Inisialisasi Semua Controller
	sampleController := controllers.NewSampleController()
	stationController := controllers.NewStationController()
	qrController := controllers.NewQRController()
	syncController := controllers.NewSyncController()
	adminCtrl := controllers.NewAdminUserController()

	// --- Station Routes ---
	station := protected.Group("/stations")
	station.Get("", stationController.GetStations)
	station.Post("/scan", stationController.ScanQR)
	station.Post("/validate-gps", stationController.ValidateGPS) // Validasi Haversine

	// --- QR Code Routes ---
	qr := protected.Group("/qr")
	qr.Get("/:id", qrController.GenerateQR)
	qr.Get("/:id/data", qrController.GetQRData)

	// --- Sample & Documentation Routes ---
	sample := protected.Group("/samples")
	sample.Post("", sampleController.CreateSample) // Upload foto & data
	sample.Get("", sampleController.GetAllSamples) // List riwayat
	sample.Get("/:id", sampleController.GetSampleDetail)
	sample.Get("/:id/export", sampleController.ExportSamplePDF) // Cetak PDF

	// --- Image Access ---
	// Endpoint untuk ambil file fisik gambar
	api.Get("/images/:id", sampleController.GetImage)

	// --- Offline Sync Route ---
	protected.Post("/sync", syncController.SyncData) // Sinkronisasi data

	// ===============================
	// ADMIN ONLY ROUTES (High Security)
	// ===============================
	// Prefix /api/v1/admin
	adminOnly := protected.Group("/admin", middleware.AdminOnly)

	// CRUD User oleh Admin
	adminOnly.Put("/users/:id", adminCtrl.UpdateUserByAdmin)
	adminOnly.Delete("/users/:id", adminCtrl.DeleteUser)

	// Route ACC Sampel
	adminOnly.Put("/samples/:id/review", sampleController.ReviewSample) // PUT /api/v1/admin/samples/1/review

	// CRUD Stasiun oleh Admin (Create Station)
	// URL: POST /api/v1/admin/stations
	adminOnly.Post("/stations", stationController.CreateStation)

}
