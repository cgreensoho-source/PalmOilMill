# Dokumentasi API Backend Sampling

## 📋 Daftar Isi
- [Ikhtisar](#ikhtisar)
- [Teknologi](#teknologi)
- [Autentikasi](#autentikasi)
- [Endpoint API](#endpoint-api)
- [Model Data](#model-data)
- [Penanganan Error](#penanganan-error)
- [Setup & Instalasi](#setup--instalasi)
- [Testing](#testing)

## 🎯 Ikhtisar

API Backend untuk aplikasi mobile sampling data yang mendukung fitur offline/online synchronization. API ini menyediakan endpoint untuk autentikasi, manajemen stasiun sampling, upload sampel dengan foto, dan sinkronisasi data.

### Fitur Utama
- ✅ Autentikasi JWT-based
- ✅ Manajemen stasiun sampling
- ✅ Scan QR code untuk validasi lokasi
- ✅ Upload sampel dengan multiple gambar
- ✅ Sinkronisasi data offline ke online
- ✅ Validasi GPS untuk keamanan lokasi

## 🛠 Teknologi

- **Backend Framework**: Go + Fiber v2
- **Database**: PostgreSQL
- **ORM**: GORM
- **Authentication**: JWT (JSON Web Token)
- **Password Hashing**: bcrypt
- **File Upload**: Multipart form-data

## 🔐 Autentikasi

API menggunakan sistem autentikasi berbasis JWT. Untuk mengakses endpoint yang dilindungi:

1. **Dapatkan token** melalui endpoint `/auth/login`
2. **Sertakan token** dalam header request:
   ```
   Authorization: Bearer <your_jwt_token>
   ```

### Alur Autentikasi
```
1. Register/Login → Mendapatkan JWT Token
2. Setiap request → Header Authorization: Bearer <token>
3. Token expired → Login ulang
```

## 🌐 Endpoint API

### Base URL
```
http://localhost:3000/api/v1
```

---

## 1. 🔑 Authentication Endpoints

### POST /auth/register
**Registrasi pengguna baru**

Mendaftarkan pengguna baru dengan validasi data yang ketat.

#### Request Body
```json
{
  "nip": "string (required)",
  "username": "string (required)",
  "email": "string (optional)",
  "phone": "string (optional)",
  "password": "string (required, min 6 chars)",
  "confirm_password": "string (required, must match password)",
  "gender": "string (optional, 'male' or 'female')"
}
```
``json

  {
  "nip": "12345678",
  "username": "petugas_stasiun1",
  "email": "petugas@pabrik.com",
  "phone": "081234567890",
  "password": "password123",
  "confirm_password": "password123",
  "gender": "male",
  "roles": ["petugas"]
}
``


#### Response Success (201)
```json
{
  "message": "User registered successfully",
  "user": {
    "user_id": 1,
    "nip": "123456",
    "username": "petugas123",
    "email": "petugas@example.com",
    "phone": "+628123456789",
    "gender": "male"
  }
}
```

#### Response Error
- **400 Bad Request**: Field wajib tidak lengkap atau tidak valid
- **409 Conflict**: NIP, username, email, atau phone sudah terdaftar

---

### POST /auth/login
**Login pengguna**

Autentikasi menggunakan username dan password.

#### Request Body
```json
{
  "username": "string (required)",
  "password": "string (required)"
}
```

#### Response Success (200)
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "user_id": 1,
    "nip": "123456",
    "username": "petugas123",
    "email": "petugas@example.com",
    "phone": "+628123456789",
    "gender": "male"
  }
}
```

#### Response Error
- **401 Unauthorized**: Username atau password salah

---

## 2. 📍 Station Endpoints

### GET /stations
**Mengambil daftar semua stasiun sampling**

Endpoint ini digunakan untuk mendapatkan daftar stasiun yang tersedia untuk sampling.

#### Headers
```
Authorization: Bearer <token>
```

#### Response Success (200)
```json
{
  "stations": [
    {
      "station_id": 1,
      "station_name": "Stasiun A - Jakarta Pusat",
      "coordinate": "-6.2088,106.8456"
    },
    {
      "station_id": 2,
      "station_name": "Stasiun B - Jakarta Utara",
      "coordinate": "-6.1214,106.7744"
    }
  ]
}
```

---

### POST /stations/scan
**Validasi scan QR code stasiun**

Mencatat aktivitas scan QR code dengan timestamp otomatis.

#### Headers
```
Authorization: Bearer <token>
```

#### Request Body
```json
{
  "station_id": 1,
  "coordinate": "-6.2088,106.8456"
}
```

#### Response Success (200)
```json
{
  "message": "QR scan berhasil",
  "station_id": 1,
  "user_id": 1
}
```

#### Response Error
- **400 Bad Request**: station_id tidak valid
- **404 Not Found**: Stasiun tidak ditemukan

---

## 3. 📦 Sample Endpoints

### POST /samples
**Membuat sampel baru dengan upload gambar**

Membuat record sampel baru beserta upload multiple gambar.

#### Headers
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

#### Form Data
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | number | ✅ | ID pengguna |
| station_id | number | ✅ | ID stasiun |
| sample_name | string | ✅ | Nama sampel |
| condition | string | ✅ | Kondisi sampel |
| images | file[] | ✅ | Multiple gambar (JPG/PNG) |

#### Response Success (200)
```json
{
  "sample_id": 1,
  "message": "Sampel berhasil dibuat dengan gambar",
  "uploaded_images": 3
}
```

#### Response Error
- **400 Bad Request**: Data tidak lengkap atau format file salah
- **404 Not Found**: User atau stasiun tidak ditemukan
- **500 Internal Server Error**: Gagal upload file

---

### GET /samples
**Mengambil semua data sample dengan filter opsional**

Mendapatkan daftar semua sample dengan kemampuan filtering berdasarkan user, stasiun, dan tanggal.

#### Headers
```
Authorization: Bearer <token>
```

#### Query Parameters (Opsional)
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | number | Filter berdasarkan ID user |
| station_id | number | Filter berdasarkan ID stasiun |
| start_date | string | Filter tanggal mulai (format: YYYY-MM-DD) |
| end_date | string | Filter tanggal akhir (format: YYYY-MM-DD) |

#### Response Success (200)
```
json
{
  "success": true,
  "data": [
    {
      "sample_id": 1,
      "user_id": 1,
      "station_id": 1,
      "sample_name": "Sampel A",
      "created_at": "2024-01-15T10:30:00Z",
      "station": {
        "station_id": 1,
        "station_name": "Stasiun A",
        "coordinate": "-6.2088,106.8456"
      },
      "images": [
        {
          "image_id": 1,
          "image_path": "upload/gambar1.jpg",
          "sample_id": 1
        }
      ]
    }
  ],
  "total": 10
}
```

#### Example Request
```
bash
# Get all samples
curl -X GET http://localhost:3000/api/v1/samples \
  -H "Authorization: Bearer YOUR_TOKEN"

# Filter by user_id
curl -X GET "http://localhost:3000/api/v1/samples?user_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Filter by station_id
curl -X GET "http://localhost:3000/api/v1/samples?station_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Filter by date range
curl -X GET "http://localhost:3000/api/v1/samples?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### GET /samples/:id
**Mengambil detail sample berdasarkan ID**

Mendapatkan detail lengkap sebuah sample termasuk gambar-gambar yang terkait.

#### Headers
```
Authorization: Bearer <token>
```

#### Response Success (200)
```
json
{
  "success": true,
  "data": {
    "sample_id": 1,
    "user_id": 1,
    "station_id": 1,
    "sample_name": "Sampel A",
    "created_at": "2024-01-15T10:30:00Z",
    "station": {
      "station_id": 1,
      "station_name": "Stasiun A",
      "coordinate": "-6.2088,106.8456"
    },
    "images": [
      {
        "image_id": 1,
        "image_path": "upload/gambar1.jpg",
        "sample_id": 1
      },
      {
        "image_id": 2,
        "image_path": "upload/gambar2.jpg",
        "sample_id": 1
      }
    ]
  }
}
```

#### Response Error
- **404 Not Found**: Sample tidak ditemukan

---

## 4. 🖼️ Image Endpoints

### GET /images/:id
**Mengambil file gambar berdasarkan ID**

Mendapatkan file gambar berdasarkan ID gambar.

#### Headers
```
Authorization: Bearer <token>
```

#### Response Success (200)
Mengembalikan file gambar dalam format binary (JPEG/PNG).

#### Response Error
- **404 Not Found**: Gambar tidak ditemukan

#### Example Request
```
bash
curl -X GET http://localhost:3000/api/v1/images/1 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  --output gambar.jpg
```

---

## 5. 🔄 Sync Endpoints

### POST /sync
**Sinkronisasi data offline ke server**

Mengupload data yang dikumpulkan saat offline.

#### Headers
```
Authorization: Bearer <token>
```

#### Request Body
```json
{
  "samples": [
    {
      "user_id": 1,
      "station_id": 1,
      "sample_name": "Sampel Offline 001",
      "condition": "Kondisi baik",
      "images": [
        {
          "image_path": "/storage/emulated/0/DCIM/sample_001.jpg",
          "user_id": 1
        }
      ]
    }
  ]
}
```

#### Response Success (200)
```json
{
  "message": "Data berhasil disinkronkan",
  "synced_samples": 1,
  "synced_images": 1
}
```

---

## 📊 Model Data

### User
```json
{
  "user_id": "number (Primary Key)",
  "nip": "string (unique)",
  "username": "string (unique)",
  "email": "string (optional, unique)",
  "phone": "string (optional, unique)",
  "password": "string (hashed)",
  "gender": "string (optional)"
}
```

### Station
```json
{
  "station_id": "number (Primary Key)",
  "station_name": "string",
  "coordinate": "string (format: 'latitude,longitude')"
}
```

### Sample
```json
{
  "sample_id": "number (Primary Key)",
  "user_id": "number (Foreign Key)",
  "station_id": "number (Foreign Key)",
  "sample_name": "string",
  "condition": "string",
  "created_at": "timestamp"
}
```

### Image
```json
{
  "image_id": "number (Primary Key)",
  "image_path": "string",
  "user_id": "number (Foreign Key)",
  "sample_id": "number (Foreign Key)",
  "created_at": "timestamp"
}
```

## ⚠️ Penanganan Error

Semua error mengembalikan response dengan format standar:

```json
{
  "error": "Pesan error yang deskriptif"
}
```

### HTTP Status Codes
| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request berhasil |
| 201 | Created | Resource berhasil dibuat |
| 400 | Bad Request | Request tidak valid |
| 401 | Unauthorized | Token tidak valid atau missing |
| 404 | Not Found | Resource tidak ditemukan |
| 409 | Conflict | Data sudah ada (duplicate) |
| 500 | Internal Server Error | Error server |

### Error Messages
- **Autentikasi**: "Invalid username or password", "Token expired"
- **Validasi**: "Field X is required", "Invalid format"
- **Database**: "Record not found", "Foreign key constraint failed"
- **File Upload**: "File too large", "Unsupported file type"

## 🚀 Setup & Instalasi

### Prerequisites
- Go 1.19+
- PostgreSQL 12+
- Git

### Langkah Instalasi

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd backend-sampling
   ```

2. **Install dependencies**
   ```bash
   go mod tidy
   ```

3. **Setup environment variables**
   Buat file `.env` di root directory:
   ```env
   DB_HOST=localhost
   DB_USER=your_db_user
   DB_PASSWORD=your_db_password
   DB_NAME=sampling_db
   DB_PORT=5432
   DB_SSLMODE=disable
   DB_TIMEZONE=Asia/Jakarta

   JWT_SECRET=your_jwt_secret_key
   ```

4. **Setup database**
   - Buat database PostgreSQL
   - Jalankan migrasi otomatis saat startup

5. **Run server**
   ```bash
   go run main.go
   ```

   Server akan berjalan di `http://localhost:3000`

## 🧪 Testing

### Testing dengan cURL

#### 1. Register User
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "nip": "123456",
    "username": "petugas123",
    "email": "petugas@example.com",
    "phone": "+628123456789",
    "password": "password123",
    "confirm_password": "password123",
    "gender": "male"
  }'
```

#### 2. Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "petugas123",
    "password": "password123"
  }'
```

#### 3. Get Stations
```bash
curl -X GET http://localhost:3000/api/v1/stations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

#### 4. Scan QR
```bash
curl -X POST http://localhost:3000/api/v1/stations/scan \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "station_id": 1,
    "coordinate": "-6.2088,106.8456"
  }'
```

#### 5. Create Sample with Images
```bash
curl -X POST http://localhost:3000/api/v1/samples \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -F "user_id=1" \
  -F "station_id=1" \
  -F "sample_name=Sampel Test 001" \
  -F "condition=Kondisi baik" \
  -F "images=@/path/to/image1.jpg" \
  -F "images=@/path/to/image2.jpg"
```

### Testing dengan Postman

1. **Import collection** dari file `docs/postman_collection.json` (jika tersedia)
2. **Set environment variables**:
   - `base_url`: `http://localhost:3000/api/v1`
   - `jwt_token`: (akan di-set setelah login)
3. **Run tests** secara berurutan: Register → Login → Get Stations → Scan QR → Create Sample

### Test Scenarios

#### ✅ Positive Test Cases
- [ ] Register user baru berhasil
- [ ] Login dengan kredensial valid
- [ ] Get list stations berhasil
- [ ] Scan QR dengan station_id valid
- [ ] Upload sample dengan multiple images
- [ ] Sync data offline berhasil

#### ❌ Negative Test Cases
- [ ] Register dengan NIP duplicate
- [ ] Login dengan password salah
- [ ] Access endpoint tanpa token
- [ ] Scan QR dengan station_id tidak ada
- [ ] Upload file dengan format tidak didukung
- [ ] Upload file dengan ukuran terlalu besar

---

## 📞 Support

Untuk pertanyaan atau masalah teknis, silakan hubungi tim development atau buat issue di repository project.

**Version**: 1.0.0
**Last Updated**: 2024
**Author**: Backend Development Team














// Register handles user registration
// func (ctrl *AuthController) Register(c *fiber.Ctx) error {
// 	var req RegisterRequest
// 	if err := c.BodyParser(&req); err != nil {
// 		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
// 	}

// 	// Validate required fields
// 	if req.Nip == "" || req.Username == "" || req.Password == "" || req.ConfirmPassword == "" {
// 		return c.Status(400).JSON(fiber.Map{"error": "NIP, username, password, and confirm password are required"})
// 	}

// 	// Validate password confirmation
// 	if req.Password != req.ConfirmPassword {
// 		return c.Status(400).JSON(fiber.Map{"error": "Password and confirm password do not match"})
// 	}

// 	// Validate password strength (minimum 6 characters)
// 	if len(req.Password) < 6 {
// 		return c.Status(400).JSON(fiber.Map{"error": "Password must be at least 6 characters long"})
// 	}

// 	// Validate email format if provided
// 	if req.Email != "" {
// 		emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
// 		if !emailRegex.MatchString(req.Email) {
// 			return c.Status(400).JSON(fiber.Map{"error": "Invalid email format"})
// 		}
// 	}

// 	// Validate phone format if provided
// 	if req.Phone != "" {
// 		phoneRegex := regexp.MustCompile(`^[0-9+\-\s()]{10,15}$`)
// 		if !phoneRegex.MatchString(req.Phone) {
// 			return c.Status(400).JSON(fiber.Map{"error": "Invalid phone number format"})
// 		}
// 	}

// 	// Check if user already exists
// 	exists, err := ctrl.userRepo.CheckUserExists(req.Nip, req.Username, req.Email, req.Phone)
// 	if err != nil {
// 		return c.Status(500).JSON(fiber.Map{"error": "Failed to check user existence"})
// 	}
// 	if exists {
// 		return c.Status(409).JSON(fiber.Map{"error": "User with this NIP, username, email, or phone already exists"})
// 	}

// 	// Hash password
// 	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
// 	if err != nil {
// 		return c.Status(500).JSON(fiber.Map{"error": "Failed to hash password"})
// 	}

// 	// Create user
// 	// user := models.User{
// 	// 	Nip:      req.Nip,
// 	// 	Username: req.Username,
// 	// 	Email:    req.Email,
// 	// 	Phone:    req.Phone,
// 	// 	Password: string(hashedPassword),
// 	// 	Gender:   req.Gender,
// 	// }

// 	// if err := ctrl.userRepo.CreateUser(&user); err != nil {
// 	// 	return c.Status(500).JSON(fiber.Map{"error": "Failed to create user"})
// 	// }

// 	//Cek lagi, kita tidak bisa langsung memasukkan req.Roles ([]string) ke user.Roles ([]models.Role)
// 	user := models.User{
// 		Nip:      req.Nip,
// 		Username: req.Username,
// 		Email:    req.Email,
// 		Phone:    req.Phone,
// 		Password: string(hashedPassword),
// 		Gender:   req.Gender,
// 		// Kita tidak bisa langsung memasukkan req.Roles ([]string) ke user.Roles ([]models.Role)
// 	}

// 	// Rekomendasi: Kirim req.Roles ke repository untuk diproses
// 	// if err := ctrl.userRepo.CreateUser(&user, req.Roles); err != nil {
// 	// 	return c.Status(500).JSON(fiber.Map{"error": "Failed to create user"})
// 	// }

// 	// Panggil repository dengan membawa req.Roles
// 	if err := ctrl.userRepo.CreateUser(&user, req.Roles); err != nil {
// 		return c.Status(500).JSON(fiber.Map{"error": "Gagal mendaftarkan user dan role"})
// 	}

// 	config.DB.Preload("Roles").First(&user, user.UserID)

// 	// Remove password from response
// 	user.Password = ""

// 	response := RegisterResponse{
// 		Message: "User registered successfully",
// 		User:    user,
// 	}

// 	return c.Status(201).JSON(response)
// }