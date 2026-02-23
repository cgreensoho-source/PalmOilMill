package repository

import (
	"sampling/config"
	"sampling/models"

	"gorm.io/gorm"
)

type SampleRepository struct {
	db *gorm.DB
}

func NewSampleRepository() *SampleRepository {
	return &SampleRepository{db: config.DB}
}

// 1. CreateSample: Menyimpan data sampling baru dari petugas
func (r *SampleRepository) CreateSample(sample *models.Sample) error {
	return r.db.Create(sample).Error
}

// 2. GetAllSamples: Untuk Log Server dengan filter pencarian
func (r *SampleRepository) GetAllSamples(userID, stationID *uint, startDate, endDate *string) ([]models.Sample, error) {
	var samples []models.Sample

	// Preload User, Station, dan Images agar log lengkap
	query := r.db.Preload("User").Preload("Station").Preload("Images").Order("created_at DESC")

	if userID != nil {
		query = query.Where("user_id = ?", *userID)
	}

	if stationID != nil {
		query = query.Where("station_id = ?", *stationID)
	}

	// Filter Range Tanggal
	if startDate != nil && endDate != nil && *startDate != "" && *endDate != "" {
		query = query.Where("created_at BETWEEN ? AND ?", *startDate, *endDate)
	} else if startDate != nil && *startDate != "" {
		query = query.Where("created_at >= ?", *startDate)
	} else if endDate != nil && *endDate != "" {
		query = query.Where("created_at <= ?", *endDate)
	}

	err := query.Find(&samples).Error
	return samples, err
}

// 3. GetSampleByID: SANGAT PENTING untuk Laporan PDF
// Fungsi ini harus menarik semua relasi agar template HTML PDF terisi lengkap
func (r *SampleRepository) GetSampleByID(id uint) (*models.Sample, error) {
	var sample models.Sample

	// Preload "User" (siapa yang ambil sampel)
	// Preload "Station" (di mana lokasi stasiunnya)
	// Preload "Images" (foto-foto pendukung sampel)
	err := r.db.Preload("User").Preload("Station").Preload("Images").First(&sample, id).Error

	if err != nil {
		return nil, err
	}
	return &sample, nil
}

// 4. GetSamplesByUserID: Riwayat sampling per petugas
func (r *SampleRepository) GetSamplesByUserID(userID uint) ([]models.Sample, error) {
	var samples []models.Sample
	// Tetap pakai preload supaya di mobile apps/frontend muncul datanya lengkap
	err := r.db.Preload("Station").Where("user_id = ?", userID).Order("created_at DESC").Find(&samples).Error
	return samples, err
}

// 5. GetImageByID: Ambil path file fisik gambar
func (r *SampleRepository) GetImageByID(imageID uint) (*models.Image, error) {
	var image models.Image
	err := r.db.First(&image, imageID).Error
	if err != nil {
		return nil, err
	}
	return &image, nil
}
