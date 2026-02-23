package models

import "time"

//
// =========================
// USER MODEL
// =========================
//

type User struct {
	UserID   uint   `gorm:"primaryKey;column:user_id" json:"user_id"`
	Nip      string `gorm:"column:nip;unique;not null" json:"nip"`
	Username string `gorm:"column:username;unique;not null" json:"username"`
	Password string `gorm:"column:password;not null" json:"-"`
	Email    string `gorm:"column:email;unique" json:"email"`
	Phone    string `gorm:"column:phone;unique" json:"phone"`
	Gender   string `gorm:"column:gender" json:"gender"`

	// Relations
	Samples []Sample `gorm:"-" json:"samples"`
	Roles   []Role   `gorm:"many2many:user_roles" json:"roles"`
}

func (User) TableName() string {
	return "users"
}

//
// =========================
// ROLE MODEL
// =========================
//

type Role struct {
	RoleID   uint   `gorm:"primaryKey;column:role_id" json:"role_id"`
	RoleName string `gorm:"column:role_name;unique;not null" json:"role_name"`
}

func (Role) TableName() string {
	return "roles"
}

//
// =========================
// USER ROLE (PIVOT TABLE)
// =========================
//

type UserRole struct {
	UserRoleID uint `gorm:"primaryKey;column:user_role_id"`
	UserID     uint `gorm:"column:user_id"`
	RoleID     uint `gorm:"column:role_id"`
}

func (UserRole) TableName() string {
	return "user_roles"
}

//
// =========================
// STATION MODEL
// =========================
//

type Station struct {
	StationID   uint   `gorm:"primaryKey;column:station_id" json:"station_id"`
	StationName string `gorm:"column:station_name;not null" json:"station_name"`
	Coordinate  string `gorm:"column:coordinate" json:"coordinate"`
}

func (Station) TableName() string {
	return "stations"
}

//
// =========================
// SAMPLE MODEL
// =========================
//

type Sample struct {
	SampleID   uint      `gorm:"primaryKey;column:sample_id" json:"sample_id"`
	UserID     uint      `gorm:"column:user_id;not null" json:"user_id"`
	StationID  uint      `gorm:"column:station_id;not null" json:"station_id"`
	SampleName string    `gorm:"column:sample_name;not null" json:"sample_name"`
	Condition  string    `gorm:"column:condition" json:"condition"`
	IsReviewed bool      `gorm:"column:is_reviewed;default:false" json:"is_reviewed"`
	CreatedAt  time.Time `gorm:"column:created_at" json:"created_at"`

	// Relations (INI YANG SUDAH BENAR)
	User    User    `gorm:"foreignKey:UserID;references:UserID" json:"user"`
	Station Station `gorm:"foreignKey:StationID;references:StationID" json:"station"`
	Images  []Image `gorm:"foreignKey:SampleID" json:"images"`
}

func (Sample) TableName() string {
	return "samples"
}

//
// =========================
// IMAGE MODEL
// =========================
//

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
