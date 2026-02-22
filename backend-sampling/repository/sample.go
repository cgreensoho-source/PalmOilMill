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

// CreateSample creates a new sample
func (r *SampleRepository) CreateSample(sample *models.Sample) error {
	return r.db.Create(sample).Error
}

// GetSamplesByUserID retrieves samples by user ID
func (r *SampleRepository) GetSamplesByUserID(userID uint) ([]models.Sample, error) {
	var samples []models.Sample
	err := r.db.Where("user_id = ?", userID).Find(&samples).Error
	return samples, err
}

// GetSampleByID retrieves sample by ID
func (r *SampleRepository) GetSampleByID(sampleID uint) (*models.Sample, error) {
	var sample models.Sample
	err := r.db.Preload("Images").Preload("Station").First(&sample, sampleID).Error
	return &sample, err
}

// GetAllSamples retrieves all samples with optional filters
func (r *SampleRepository) GetAllSamples(userID *uint, stationID *uint, startDate, endDate *string) ([]models.Sample, error) {
	var samples []models.Sample

	query := r.db.Preload("User").Preload("Station").Preload("Images").Order("created_at DESC")

	if userID != nil {
		query = query.Where("user_id = ?", *userID)
	}

	if stationID != nil {
		query = query.Where("station_id = ?", *stationID)
	}

	if startDate != nil && *startDate != "" {
		query = query.Where("created_at >= ?", *startDate)
	}

	if endDate != nil && *endDate != "" {
		query = query.Where("created_at <= ?", *endDate)
	}

	err := query.Find(&samples).Error
	return samples, err
}

// GetSampleImages retrieves all images for a sample
func (r *SampleRepository) GetSampleImages(sampleID uint) ([]models.Image, error) {
	var images []models.Image
	err := r.db.Where("sample_id = ?", sampleID).Find(&images).Error
	return images, err
}

// GetImageByID retrieves image by ID
func (r *SampleRepository) GetImageByID(imageID uint) (*models.Image, error) {
	var image models.Image
	err := r.db.First(&image, imageID).Error
	return &image, err
}
