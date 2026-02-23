package repository

import (
	"sampling/config"
	"sampling/models"

	"gorm.io/gorm"
)

type StationRepository struct {
	db *gorm.DB
}

func NewStationRepository() *StationRepository {
	return &StationRepository{db: config.DB}
}

// GetAllStations retrieves all stations
func (r *StationRepository) GetAllStations() ([]models.Station, error) {
	var stations []models.Station
	err := r.db.Find(&stations).Error
	return stations, err
}

// GetStationByID retrieves station by ID
func (r *StationRepository) GetStationByID(stationID uint) (*models.Station, error) {
	var station models.Station
	err := r.db.First(&station, stationID).Error
	return &station, err
}
