package models

import (
	"time"
)

// Table users: user_id (PK), nip, username, password, email, phone, gender
type User struct {
	UserID   uint   `gorm:"primaryKey;column:user_id" json:"user_id"`
	Nip      string `gorm:"column:nip;unique;not null" json:"nip"`
	Username string `gorm:"column:username;unique;not null" json:"username"`
	Password string `gorm:"column:password;not null" json:"-"`
	Email    string `gorm:"column:email;unique" json:"email"`
	Phone    string `gorm:"column:phone;unique" json:"phone"`
	Gender   string `gorm:"column:gender" json:"gender"`
}

func (User) TableName() string {
	return "users"
}

// Table roles: role_id (PK), role_name
type Role struct {
	RoleID   uint   `gorm:"primaryKey;column:role_id" json:"role_id"`
	RoleName string `gorm:"column:role_name;unique;not null" json:"role_name"`
}

func (Role) TableName() string {
	return "roles"
}

// Table user_roles: user_role_id (PK), user_id (FK), role_id (FK)
type UserRole struct {
	UserRoleID uint `gorm:"primaryKey;column:user_role_id" json:"user_role_id"`
	UserID     uint `gorm:"column:user_id" json:"user_id"`
	RoleID     uint `gorm:"column:role_id" json:"role_id"`
}

func (UserRole) TableName() string {
	return "user_roles"
}

// Table stations: station_id (PK), station_name, coordinate
type Station struct {
	StationID   uint   `gorm:"primaryKey;column:station_id" json:"station_id"`
	StationName string `gorm:"column:station_name;not null" json:"station_name"`
	Coordinate  string `gorm:"column:coordinate" json:"coordinate"`
}

func (Station) TableName() string {
	return "stations"
}

// Table samples: sample_id (PK), user_id (FK), station_id (FK), sample_name, created_at
type Sample struct {
	SampleID   uint      `gorm:"primaryKey;column:sample_id" json:"sample_id"`
	UserID     uint      `gorm:"column:user_id" json:"user_id"`
	StationID  uint      `gorm:"column:station_id" json:"station_id"`
	SampleName string    `gorm:"column:sample_name;not null" json:"sample_name"`
	CreatedAt  time.Time `gorm:"column:created_at" json:"created_at"`
	// Relasi
	User    User    `gorm:"foreignKey:UserID" json:"-"`
	Station Station `gorm:"foreignKey:StationID" json:"station"`
	Images  []Image `gorm:"foreignKey:SampleID" json:"images"`
}

// Table images: image_id (PK), image_path, user_id (FK), sample_id (FK), created_at
type Image struct {
	ImageID   uint      `gorm:"primaryKey;column:image_id" json:"image_id"`
	ImagePath string    `gorm:"column:image_path;not null" json:"image_path"`
	UserID    uint      `gorm:"column:user_id" json:"user_id"`
	SampleID  uint      `gorm:"column:sample_id" json:"sample_id"`
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`
}

func (Image) TableName() string {
	return "images"
}
