package config

import (
	"fmt"
	"log"
	"os"

	"sampling/models" // Sesuaikan dengan nama module go.mod Anda

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() {
	// Load file .env
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Ambil data dari env
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=%s",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_SSLMODE"),
		os.Getenv("DB_TIMEZONE"),
	)

	// Koneksi ke Postgres
	database, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})

	if err != nil {
		panic("Gagal terkoneksi ke database!")
	}

	// Auto-Migrate sesuai skema yang sudah kita kunci
	err = database.AutoMigrate(
		&models.User{},     // 1. Induk
		&models.Role{},     // 2. Induk
		&models.UserRole{}, // 3. Anak (butuh User & Role)
		&models.Station{},  // 4. Induk
		&models.Sample{},   // 5. Anak (butuh User & Station)
		&models.Image{},    // 6. Cucu (butuh Sample)
	)

	if err != nil {
		log.Fatal("Gagal melakukan migrasi database:", err)
	}

	// Seed initial data
	seedInitialData(database)

	DB = database
	fmt.Println("Database terkoneksi dan migrasi berhasil!")
}

func seedInitialData(db *gorm.DB) {
	// Seed roles
	roles := []models.Role{
		{RoleName: "admin"},
		{RoleName: "operator"},
	}

	for _, role := range roles {
		var existingRole models.Role
		if err := db.Where("role_name = ?", role.RoleName).First(&existingRole).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				db.Create(&role)
				log.Printf("Role '%s' created", role.RoleName)
			}
		}
	}

	// Seed stations
	stations := []models.Station{
		{StationName: "Station A", Coordinate: "-6.2088,106.8456"},
		{StationName: "Station B", Coordinate: "-6.2146,106.8451"},
		{StationName: "Station C", Coordinate: "-6.2200,106.8500"},
	}

	for _, station := range stations {
		var existingStation models.Station
		if err := db.Where("station_name = ?", station.StationName).First(&existingStation).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				db.Create(&station)
				log.Printf("Station '%s' created", station.StationName)
			}
		}
	}

	// Seed admin user
	var adminRole models.Role
	db.Where("role_name = ?", "admin").First(&adminRole)

	adminUser := models.User{
		Nip:      "123456789",
		Username: "admin",
		Password: "$2a$10$hashedpassword", // You should hash this properly
		Gender:   "M",
	}

	var existingUser models.User
	if err := db.Where("username = ?", adminUser.Username).First(&existingUser).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			db.Create(&adminUser)

			// Create user role
			userRole := models.UserRole{
				UserID: adminUser.UserID,
				RoleID: adminRole.RoleID,
			}
			db.Create(&userRole)
			log.Printf("Admin user '%s' created", adminUser.Username)
		}
	}
}
