## Dokumentasi Lengkap API Backend Sampling

Dokumen ini menjelaskan **seluruh endpoint** yang ada di backend sampling, termasuk:

- **Autentikasi & otorisasi (JWT)**
- **Endpoint umum** untuk stasiun, sampel, gambar, dan sinkronisasi
- **Endpoint role-based** (Admin, Asisten, User)
- **Contoh penggunaan dengan header, body, dan contoh request (cURL / Postman)**

Base URL:

```text
http://localhost:3000/api/v1
```

---

## 📋 Ringkasan Endpoint

| Kelompok         | Method | Path                               | Deskripsi Singkat                                    | Role          |
|------------------|--------|------------------------------------|------------------------------------------------------|--------------|
| Auth             | POST   | `/auth/register`                   | Registrasi user baru                                 | Publik       |
| Auth             | POST   | `/auth/login`                      | Login dan dapatkan JWT                              | Publik       |
| Station          | GET    | `/stations`                        | List semua stasiun                                  | Login (user) |
| Station          | POST   | `/stations/scan`                   | Scan QR stasiun                                     | Login (user) |
| Station          | POST   | `/stations/validate-gps`           | Validasi GPS (haversine)                            | Login (user) |
| QR               | GET    | `/qr/:id`                          | Generate QR code untuk stasiun                      | Login (user) |
| QR               | GET    | `/qr/:id/data`                     | Ambil data detail QR                                | Login (user) |
| Sample           | POST   | `/samples`                         | Input data sampel + upload foto                     | Login (user) |
| Sample           | GET    | `/samples`                         | List semua sampling (filter)                        | Admin/Asisten |
| Sample           | GET    | `/samples/{id}`                    | Detail 1 sample                                      | Admin/Asisten |
| Sample           | GET    | `/samples/my`                      | List semua sampling milik user login                | Login (user) |
| Sample           | GET    | `/samples/{id}/export`             | Export laporan PDF                                  | Admin/Asisten |
| Image            | GET    | `/images/{id}`                     | Ambil file gambar fisik                             | Publik (tanpa JWT) |
| Sync             | POST   | `/sync`                            | Sinkronisasi data offline → server                  | Login (user) |
| Admin User       | GET    | `/admin/users`                     | List semua user + roles                             | Admin        |
| Admin User       | GET    | `/admin/users/{id}`                | Detail 1 user                                        | Admin        |
| Admin User       | PUT    | `/admin/users/{id}`                | Update data user (parsial)                          | Admin        |
| Admin User       | DELETE | `/admin/users/{id}`                | Hapus user + relasi (clean delete)                  | Admin        |
| Admin Sample     | PUT    | `/admin/samples/{id}/review`       | ACC / review status sample                          | Admin        |
| Admin Sample     | PUT    | `/admin/samples/{id}`              | Edit data sample (nama, kondisi, stasiun)           | Admin        |
| Admin Station    | POST   | `/admin/stations`                  | Tambah stasiun baru                                 | Admin        |

> Semua path di atas **otomatis diprefix** oleh `http://localhost:3000/api/v1`.

---

## 🔐 Autentikasi & Header

API menggunakan JWT. Alur:

1. Register (jika perlu) → `POST /auth/register`
2. Login → `POST /auth/login` → dapat token JWT
3. Untuk setiap request ke endpoint **protected**, kirim header:

```text
Authorization: Bearer <your_jwt_token>
```

Jika token tidak ada / invalid → server balas `401 Unauthorized`.

---

## 1. Authentication Endpoints

### 1.1 POST `/auth/register`

**Registrasi pengguna baru** dengan validasi NIP, username, email, dan roles.

- **Akses**: Publik
- **Body (JSON)**:

```json
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
```

- **Response 201 (berhasil)**:

```json
{
  "message": "User registered successfully",
  "user": {
    "user_id": 1,
    "nip": "12345678",
    "username": "petugas_stasiun1",
    "email": "petugas@pabrik.com",
    "phone": "081234567890",
    "gender": "male",
    "roles": [
      { "role_id": 2, "role_name": "petugas" }
    ]
  }
}
```

### 1.2 POST `/auth/login`

**Login pengguna** dan mendapatkan JWT.

- **Akses**: Publik
- **Body (JSON)**:

```json
{
  "username": "petugas_stasiun1",
  "password": "password123"
}
```

- **Response 200 (berhasil)**:

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "user_id": 1,
    "nip": "12345678",
    "username": "petugas_stasiun1",
    "email": "petugas@pabrik.com",
    "phone": "081234567890",
    "gender": "male",
    "roles": [
      { "role_id": 2, "role_name": "petugas" }
    ]
  }
}
```

---

## 2. Station Endpoints

### 2.1 GET `/stations`

Mengambil daftar semua stasiun sampling.

- **Akses**: Login (user, asisten, admin)
- **Headers**:

```text
Authorization: Bearer <token>
```

- **Response 200**:

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

### 2.2 POST `/stations/scan`

Mencatat aktivitas scan QR code stasiun.

- **Akses**: Login (user)
- **Headers**:

```text
Authorization: Bearer <token>
Content-Type: application/json
```

- **Body**:

```json
{
  "station_id": 1,
  "coordinate": "-6.2088,106.8456"
}
```

- **Response 200**:

```json
{
  "message": "QR scan berhasil",
  "station_id": 1,
  "user_id": 1
}
```

### 2.3 POST `/stations/validate-gps`

Validasi jarak GPS antara posisi user dengan koordinat stasiun (haversine).

- **Akses**: Login (user)
- **Body (contoh)**:

```json
{
  "station_id": 1,
  "user_coordinate": "-6.2089,106.8457"
}
```

> Response berisi informasi jarak dan status valid / tidak sesuai aturan yang Anda terapkan di backend.

---

## 3. Sample Endpoints (Umum)

### 3.1 POST `/samples` – Input Sample + Upload Foto

Membuat record sample baru plus upload satu atau lebih gambar.

- **Akses**: Login (user)
- **Headers**:

```text
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

- **Form-Data**:

| Key         | Type  | Required | Keterangan                        |
|------------|-------|----------|-----------------------------------|
| `user_id`  | Text  | ✅       | ID user (sesuai tabel `users`)   |
| `station_id` | Text | ✅       | ID stasiun                        |
| `sample_name` | Text | ✅      | Nama sampel                       |
| `condition` | Text | ✅       | Catatan kondisi lapangan          |
| `images`   | File  | ✅       | Bisa multi (ulang key `images`)  |

- **Contoh di Postman**:
  - Body → `form-data`
  - Baris:
    - `user_id` = `5` (Text)
    - `station_id` = `1` (Text)
    - `sample_name` = `Sampel Pagi 1` (Text)
    - `condition` = `Buah matang, tanpa kontaminasi` (Text)
    - `images` = pilih `foto1.jpg` (File)
    - `images` = pilih `foto2.jpg` (File)

- **Response 200**:

```json
{
  "sample_id": 10,
  "message": "Sample created successfully with images and condition notes"
}
```

### 3.2 GET `/samples` – List Semua Sample (Admin/Asisten)

Mengambil semua log sampling dengan filter opsional.

- **Akses**: Hanya **admin** dan **asisten**
- **Headers**:

```text
Authorization: Bearer <token_admin_atau_asisten>
```

- **Query Parameters (opsional)**:

| Parameter    | Contoh               | Keterangan                    |
|-------------|----------------------|-------------------------------|
| `user_id`   | `?user_id=5`         | Filter per petugas            |
| `station_id`| `?station_id=1`      | Filter per stasiun            |
| `start_date`| `?start_date=2024-01-01` | Tanggal mulai (YYYY-MM-DD) |
| `end_date`  | `?end_date=2024-01-31`   | Tanggal akhir (YYYY-MM-DD) |

- **Contoh**:

```bash
# Semua sample
curl -X GET "http://localhost:3000/api/v1/samples" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# Filter per user
curl -X GET "http://localhost:3000/api/v1/samples?user_id=5" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

- **Response 200** (disederhanakan):

```json
{
  "success": true,
  "total": 2,
  "data": [
    {
      "sample_id": 10,
      "user_id": 5,
      "station_id": 1,
      "sample_name": "Sampel Pagi 1",
      "condition": "Buah matang, tanpa kontaminasi",
      "is_reviewed": false,
      "created_at": "2024-01-15T10:30:00Z",
      "user": { "...": "data user" },
      "station": { "...": "data station" },
      "images": [ { "...": "data image" } ]
    }
  ]
}
```

### 3.3 GET `/samples/{id}` – Detail 1 Sample

- **Akses**: Admin / Asisten
- **Headers**:

```text
Authorization: Bearer <token_admin_atau_asisten>
```

- **Contoh**: `GET /samples/10`

- **Response 200**:

```json
{
  "success": true,
  "data": {
    "sample_id": 10,
    "user_id": 5,
    "station_id": 1,
    "sample_name": "Sampel Pagi 1",
    "condition": "Buah matang, tanpa kontaminasi",
    "is_reviewed": false,
    "created_at": "2024-01-15T10:30:00Z",
    "user": { "...": "data user" },
    "station": { "...": "data station" },
    "images": [ { "...": "data image" } ]
  }
}
```

### 3.4 GET `/samples/my` – Riwayat Sample User Login

Endpoint ini mengembalikan **semua sample yang dibuat oleh user yang sedang login** (dibaca dari `user_id` di JWT).

- **Akses**: Semua user yang login (role apa pun)
- **Headers**:

```text
Authorization: Bearer <token_user>
```

- **Contoh**:

```bash
curl -X GET "http://localhost:3000/api/v1/samples/my" \
  -H "Authorization: Bearer YOUR_USER_TOKEN"
```

- **Response 200**:

```json
{
  "success": true,
  "total": 2,
  "data": [
    {
      "sample_id": 10,
      "user_id": 5,
      "station_id": 1,
      "sample_name": "Sampel Pagi 1",
      "condition": "Buah matang, tanpa kontaminasi",
      "is_reviewed": false,
      "created_at": "2024-01-15T10:30:00Z",
      "station": { "...": "data station" },
      "images": [ { "...": "data image" } ]
    }
  ]
}
```

### 3.5 GET `/samples/{id}/export` – Export PDF

Menghasilkan laporan sampling dalam bentuk file PDF.

- **Akses**: Admin / Asisten
- **Headers**:

```text
Authorization: Bearer <token_admin_atau_asisten>
```

- **Response**: file PDF (binary) dengan header:

```text
Content-Type: application/pdf
Content-Disposition: attachment; filename=Laporan-{id}.pdf
```

---

## 4. Image Endpoints

### 4.1 GET `/images/{id}`

Mengambil file gambar fisik berdasarkan `image_id`.

- **Akses**: Publik (tidak perlu JWT, karena hanya mengembalikan file statis)
- **Contoh**:

```bash
curl -X GET "http://localhost:3000/api/v1/images/21" --output gambar.jpg
```

Jika `image_id` tidak ditemukan → `404 Not Found`.

---

## 5. Sync Endpoint

### 5.1 POST `/sync`

Sinkronisasi data yang dikumpulkan secara offline ke server.

- **Akses**: Login (user)
- **Headers**:

```text
Authorization: Bearer <token>
Content-Type: application/json
```

- **Body (contoh)**:

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

- **Response 200**:

```json
{
  "message": "Data berhasil disinkronkan",
  "synced_samples": 1,
  "synced_images": 1
}
```

---

## 6. Admin User Endpoints

Semua endpoint ini berada di bawah prefix:

```text
http://localhost:3000/api/v1/admin
```

Dan **wajib**:

```text
Authorization: Bearer <token_admin>
```

### 6.1 GET `/admin/users` – List Semua User

Mengambil semua user beserta roles-nya.

- **Akses**: Admin

- **Response 200**:

```json
[
  {
    "user_id": 1,
    "nip": "12345678",
    "username": "admin",
    "email": "admin@example.com",
    "phone": "08123456789",
    "gender": "L",
    "roles": [
      { "role_id": 1, "role_name": "admin" }
    ]
  },
  {
    "user_id": 2,
    "nip": "87654321",
    "username": "petugas1",
    "email": "petugas1@example.com",
    "phone": "0899999999",
    "gender": "P",
    "roles": [
      { "role_id": 2, "role_name": "petugas" }
    ]
  }
]
```

### 6.2 GET `/admin/users/{id}` – Detail User

- **Akses**: Admin
- **Contoh**: `GET /admin/users/2`

- **Response 200**:

```json
{
  "user_id": 2,
  "nip": "87654321",
  "username": "petugas1",
  "email": "petugas1@example.com",
  "phone": "0899999999",
  "gender": "P",
  "roles": [
    { "role_id": 2, "role_name": "petugas" }
  ]
}
```

### 6.3 PUT `/admin/users/{id}` – Update Data User (Parsial)

Hanya field yang dikirim yang akan diupdate. Password akan di-hash jika diisi.

- **Akses**: Admin
- **Body (JSON, semua opsional)**:

```json
{
  "nip": "99999999",
  "username": "petugas1_update",
  "email": "baru@example.com",
  "phone": "0812000000",
  "password": "passwordBaru123",
  "gender": "L",
  "roles": ["admin", "petugas"]
}
```

- **Response 200**:

```json
{
  "message": "Data user berhasil diperbarui tanpa menghapus data lama"
}
```

### 6.4 DELETE `/admin/users/{id}` – Hapus User + Relasi

Menghapus user beserta relasi di tabel `user_roles`, `images`, dan `samples` (clean delete).

- **Akses**: Admin

- **Response 200**:

```json
{
  "message": "User ID 5 dan seluruh datanya di tabel images, samples, dan roles berhasil dibersihkan!"
}
```

---

## 7. Admin Sample & Station Endpoints

Prefix:

```text
http://localhost:3000/api/v1/admin
Authorization: Bearer <token_admin>
```

### 7.1 PUT `/admin/samples/{id}/review` – ACC / Review Sampel

Mengubah status `is_reviewed` pada sebuah sample.

- **Body (JSON)**:

```json
{
  "is_reviewed": true
}
```

- **Response 200**:

```json
{
  "message": "Status sampel berhasil diperbarui",
  "is_reviewed": true
}
```

### 7.2 PUT `/admin/samples/{id}` – Edit Data Sampling (Admin)

Admin dapat mengubah **nama sample**, **kondisi**, dan **station_id**. Semua field opsional.

- **Body (JSON)**:

```json
{
  "sample_name": "Sampel Uji Lab 001 (Update)",
  "condition": "Kondisi bagus, updated oleh admin",
  "station_id": 2
}
```

- **Response 200**:

```json
{
  "message": "Data sample berhasil diupdate",
  "data": {
    "sample_id": 10,
    "user_id": 5,
    "station_id": 2,
    "sample_name": "Sampel Uji Lab 001 (Update)",
    "condition": "Kondisi bagus, updated oleh admin",
    "is_reviewed": false,
    "created_at": "2024-01-15T10:30:00Z",
    "user": { "...": "data user" },
    "station": { "...": "data station" },
    "images": [ { "...": "data image" } ]
  }
}
```

### 7.3 POST `/admin/stations` – Tambah Stasiun

Menambahkan stasiun baru.

- **Body (JSON, contoh)**:

```json
{
  "station_name": "Stasiun C - Kebun 3",
  "coordinate": "-6.3000,106.9000"
}
```

- **Response 201 / 200** (contoh):

```json
{
  "station_id": 3,
  "station_name": "Stasiun C - Kebun 3",
  "coordinate": "-6.3000,106.9000"
}
```

---

## 8. Model Data (Ringkasan)

### 8.1 User

```json
{
  "user_id": 1,
  "nip": "string (unique)",
  "username": "string (unique)",
  "email": "string (optional, unique)",
  "phone": "string (optional, unique)",
  "password": "string (hashed, tidak dikirim ke client)",
  "gender": "string",
  "roles": [
    {
      "role_id": 1,
      "role_name": "admin"
    }
  ]
}
```

### 8.2 Station

```json
{
  "station_id": 1,
  "station_name": "Stasiun A",
  "coordinate": "-6.2088,106.8456"
}
```

### 8.3 Sample

```json
{
  "sample_id": 10,
  "user_id": 5,
  "station_id": 1,
  "sample_name": "Sampel Pagi 1",
  "condition": "Kondisi baik",
  "is_reviewed": false,
  "created_at": "2024-01-15T10:30:00Z",
  "user": { "...": "data user" },
  "station": { "...": "data station" },
  "images": [ { "...": "data image" } ]
}
```

### 8.4 Image

```json
{
  "image_id": 21,
  "image_path": "upload/xxxx.jpg",
  "user_id": 5,
  "sample_id": 10,
  "created_at": "2024-01-15T10:31:00Z"
}
```

---

## 9. Penanganan Error

Semua error menggunakan format standar:

```json
{
  "error": "Pesan error yang deskriptif"
}
```

Contoh:

- `400 Bad Request`:

```json
{
  "error": "Missing required fields: user_id, station_id, sample_name, and condition are required"
}
```

- `401 Unauthorized`:

```json
{
  "error": "Token tidak valid atau expired"
}
```

- `403 Forbidden`:

```json
{
  "error": "Access denied: This action requires Admin or Assistant privileges"
}
```

- `404 Not Found`:

```json
{
  "error": "Sample not found"
}
```

---

## 10. Setup Singkat

Ringkasan (detail bisa lihat `README.md` atau `docs/api.md`):

1. Install dependency:

```bash
go mod tidy
```

2. Siapkan `.env` untuk koneksi PostgreSQL dan `JWT_SECRET`.
3. Jalankan server:

```bash
go run main.go
```

Server jalan di `http://localhost:3000`, dokumentasi Swagger di:

```text
http://localhost:3000/swagger/index.html
```

---

## 11. Testing dengan Postman (Alur Sederhana)

1. **Register / siapkan admin & user**
2. **Login** → ambil `token`
3. **Sebagai user**:
   - `POST /samples` → kirim data + foto
   - `GET /samples/my` → cek riwayat milik sendiri
4. **Sebagai admin**:
   - `GET /admin/users` → lihat semua user
   - `GET /samples` → lihat semua sample
   - `PUT /admin/samples/{id}/review` → ACC sample
   - `PUT /admin/samples/{id}` → edit detail sample

Dengan dokumentasi ini, Anda bisa langsung mengkonfigurasi koleksi Postman / Insomnia untuk seluruh endpoint yang tersedia di backend sampling.
