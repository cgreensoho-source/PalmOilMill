package config

import (
	"fmt"
	"log"
	"os"

	"sampling/models" // sesuaikan dengan module di go.mod

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() {

	// ===============================
	// LOAD ENV
	// ===============================
	if err := godotenv.Load(); err != nil {
		log.Println(".env tidak ditemukan, menggunakan system env")
	}

	// ===============================
	// DATABASE CONFIG
	// ===============================
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=%s",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_SSLMODE"),
		os.Getenv("DB_TIMEZONE"),
	)

	database, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("❌ Gagal koneksi database: %v", err)
	}

	fmt.Println("✅ Database Connected")

	DB = database

	// ===============================
	// 🔥 URUTAN MIGRASI (SUPER PENTING)
	// ===============================
	// Parent table HARUS duluan

	// ===============================
	// SAFE MIGRATION (STEP BY STEP)
	// ===============================

	if err := DB.AutoMigrate(&models.Role{}); err != nil {
		log.Fatal("Role migrate gagal:", err)
	}

	if err := DB.AutoMigrate(&models.User{}); err != nil {
		log.Fatal("User migrate gagal:", err)
	}

	if err := DB.AutoMigrate(&models.Station{}); err != nil {
		log.Fatal("Station migrate gagal:", err)
	}

	if err := DB.AutoMigrate(&models.UserRole{}); err != nil {
		log.Fatal("UserRole migrate gagal:", err)
	}

	if err := DB.AutoMigrate(&models.Sample{}); err != nil {
		log.Fatal("Sample migrate gagal:", err)
	}

	if err := DB.AutoMigrate(&models.Image{}); err != nil {
		log.Fatal("Image migrate gagal:", err)
	}

	// ===============================
	// SEED DATA
	// ===============================
	seedInitialData(DB)

	fmt.Println("✅ Database siap digunakan!")
}

func seedInitialData(db *gorm.DB) {

	// ===============================
	// SEED ROLES
	// ===============================
	roles := []models.Role{
		{RoleName: "admin"},
		{RoleName: "operator"},
	}

	for _, role := range roles {
		var existing models.Role

		err := db.Where("role_name = ?", role.RoleName).
			First(&existing).Error

		if err == gorm.ErrRecordNotFound {
			db.Create(&role)
			log.Printf("✅ Role '%s' created", role.RoleName)
		}
	}

	// ===============================
	// SEED STATIONS
	// ===============================
	stations := []models.Station{
		{StationName: "Station A", Coordinate: "-6.2088,106.8456"},
		{StationName: "Station B", Coordinate: "-6.2146,106.8451"},
		{StationName: "Station C", Coordinate: "-6.2200,106.8500"},
	}

	for _, station := range stations {
		var existing models.Station

		err := db.Where("station_name = ?", station.StationName).
			First(&existing).Error

		if err == gorm.ErrRecordNotFound {
			db.Create(&station)
			log.Printf("✅ Station '%s' created", station.StationName)
		}
	}

	// ===============================
	// SEED ADMIN USER
	// ===============================
	var adminRole models.Role
	db.Where("role_name = ?", "admin").First(&adminRole)

	adminUser := models.User{
		Nip:      "123456789",
		Username: "admin",
		Password: "$2a$10$hashedpassword", // nanti hash beneran
		Gender:   "M",
	}

	var existingUser models.User

	err := db.Where("username = ?", adminUser.Username).
		First(&existingUser).Error

	if err == gorm.ErrRecordNotFound {

		db.Create(&adminUser)

		userRole := models.UserRole{
			UserID: adminUser.UserID,
			RoleID: adminRole.RoleID,
		}

		db.Create(&userRole)

		log.Printf("✅ Admin user '%s' created", adminUser.Username)
	}
}
