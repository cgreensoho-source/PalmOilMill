package controllers

import (
	"bytes"
	"html/template"

	"github.com/SebastiaanKlippert/go-wkhtmltopdf"

	"fmt"
	"path/filepath"
	"sampling/models"
	"sampling/repository"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type SampleController struct {
	sampleRepo *repository.SampleRepository
	imageRepo  *repository.ImageRepository
}

func NewSampleController() *SampleController {
	return &SampleController{
		sampleRepo: repository.NewSampleRepository(),
		imageRepo:  repository.NewImageRepository(),
	}
}

type CreateSampleRequest struct {
	UserID     uint   `json:"user_id"`
	StationID  uint   `json:"station_id"`
	SampleName string `json:"sample_name"`
	Condition  string `json:"condition"`
}

type CreateSampleResponse struct {
	SampleID uint   `json:"sample_id"`
	Message  string `json:"message"`
}

// CreateSample: Menerima input data sampling dan multiple images
// CreateSample godoc
// @Summary      Input Data Sampling & Upload Foto
// @Description  Petugas lapangan menginput nama sampel, kondisi, dan mengunggah beberapa foto dokumentasi sekaligus.
// @Tags         samples
// @Accept       multipart/form-data
// @Produce      json
// @Param        user_id      formData  int     true  "ID Petugas"
// @Param        station_id   formData  int     true  "ID Stasiun"
// @Param        sample_name  formData  string  true  "Nama Sampel"
// @Param        condition    formData  string  true  "Catatan Kondisi Lapangan"
// @Param        images       formData  file    true  "Multiple Images (Dokumentasi)"
// @Success      200          {object}  CreateSampleResponse
// @Failure      400          {object}  map[string]string "Error validation"
// @Router       /samples [post]
func (ctrl *SampleController) CreateSample(c *fiber.Ctx) error {
	form, err := c.MultipartForm()
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Failed to parse multipart form"})
	}

	// Ambil data dari form-data
	userIDStr := form.Value["user_id"]
	stationIDStr := form.Value["station_id"]
	sampleName := form.Value["sample_name"]
	conditionData := form.Value["condition"] // Menangkap field condition

	// Validasi input wajib
	if len(userIDStr) == 0 || len(stationIDStr) == 0 || len(sampleName) == 0 || len(conditionData) == 0 {
		return c.Status(400).JSON(fiber.Map{"error": "Missing required fields: user_id, station_id, sample_name, and condition are required"})
	}

	var userID, stationID uint
	fmt.Sscanf(userIDStr[0], "%d", &userID)
	fmt.Sscanf(stationIDStr[0], "%d", &stationID)

	// Inisialisasi Model Sample
	sample := models.Sample{
		UserID:     userID,
		StationID:  stationID,
		SampleName: sampleName[0],
		Condition:  conditionData[0], // Memasukkan nilai condition ke model
		CreatedAt:  time.Now(),
		IsReviewed: false,
	}

	// Simpan Sample ke Database
	if err := ctrl.sampleRepo.CreateSample(&sample); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create sample record"})
	}

	// Proses Upload Gambar
	files := form.File["images"]
	for _, file := range files {
		ext := filepath.Ext(file.Filename)
		filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
		savePath := filepath.Join("upload", filename)

		// Simpan file fisik
		if err := c.SaveFile(file, savePath); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to save physical image file"})
		}

		// Simpan record gambar ke database
		image := models.Image{
			ImagePath: savePath,
			UserID:    userID,
			SampleID:  sample.SampleID,
			CreatedAt: time.Now(),
		}

		if err := ctrl.imageRepo.CreateImage(&image); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to save image record to database"})
		}
	}

	return c.JSON(CreateSampleResponse{
		SampleID: sample.SampleID,
		Message:  "Sample created successfully with images and condition notes",
	})
}

// GetAllSamples: Ambil semua log sampling dengan filter (Admin & Asisten Only)
// GetAllSamples godoc
// @Summary      List Riwayat Sampling (Admin/Asisten)
// @Description  Mengambil semua log sampling dengan fitur filter ID User, ID Stasiun, dan rentang tanggal.
// @Tags         samples
// @Produce      json
// @Security     BearerAuth
// @Param        user_id     query     int     false  "Filter per Petugas"
// @Param        station_id  query     int     false  "Filter per Stasiun"
// @Param        start_date  query     string  false  "Format: YYYY-MM-DD"
// @Param        end_date    query     string  false  "Format: YYYY-MM-DD"
// @Success      200         {object}  map[string]interface{}
// @Router       /samples [get]
func (ctrl *SampleController) GetAllSamples(c *fiber.Ctx) error {
	if err := ctrl.checkAccess(c); err != nil {
		return err
	}

	var userID, stationID *uint
	var startDate, endDate *string

	if val := c.Query("user_id"); val != "" {
		id := new(uint)
		fmt.Sscanf(val, "%d", id)
		userID = id
	}

	if val := c.Query("station_id"); val != "" {
		id := new(uint)
		fmt.Sscanf(val, "%d", id)
		stationID = id
	}

	if start := c.Query("start_date"); start != "" {
		startDate = &start
	}

	if end := c.Query("end_date"); end != "" {
		endDate = &end
	}

	samples, err := ctrl.sampleRepo.GetAllSamples(userID, stationID, startDate, endDate)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to retrieve samples"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"total":   len(samples),
		"data":    samples,
	})
}

// GetSampleDetail: Lihat detail 1 sampel (Admin & Asisten Only)
// GetSampleDetail godoc
// @Summary      Detail Data Sampling
// @Description  Melihat detail lengkap satu data sampling beserta relasi User, Stasiun, dan Foto.
// @Tags         samples
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      int  true  "Sample ID"
// @Success      200  {object}  models.Sample
// @Router       /samples/{id} [get]
func (ctrl *SampleController) GetSampleDetail(c *fiber.Ctx) error {
	if err := ctrl.checkAccess(c); err != nil {
		return err
	}

	sampleID, err := c.ParamsInt("id")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid sample ID"})
	}

	sample, err := ctrl.sampleRepo.GetSampleByID(uint(sampleID))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Sample not found"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    sample,
	})
}

// GetImage: Ambil file gambar berdasarkan ID
// GetImage godoc
// @Summary      Lihat File Foto
// @Description  Mengambil/menampilkan file fisik gambar berdasarkan ID gambar.
// @Tags         samples
// @Produce      image/*
// @Param        id   path      int  true  "Image ID"
// @Success      200  {file}    binary
// @Router       /samples/images/{id} [get]
func (ctrl *SampleController) GetImage(c *fiber.Ctx) error {
	imageID, err := c.ParamsInt("id")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid image ID"})
	}
	image, err := ctrl.imageRepo.GetImageByID(uint(imageID))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Image not found"})
	}
	return c.SendFile(image.ImagePath)
}

// checkAccess: Helper untuk validasi Role Admin atau Asisten

func (ctrl *SampleController) checkAccess(c *fiber.Ctx) error {
	// Ambil role yang sudah diset oleh middleware.JWTMiddleware di c.Locals
	role := c.Locals("role")

	if role == "admin" || role == "asisten" {
		return nil
	}

	return c.Status(403).JSON(fiber.Map{
		"error": "Access denied: This action requires Admin or Assistant privileges",
	})
}

// ExportSamplePDF godoc
// @Summary      Export Laporan PDF
// @Description  Menghasilkan dokumen PDF resmi hasil sampling untuk diunduh.
// @Tags         samples
// @Produce      application/pdf
// @Param        id   path      int  true  "Sample ID"
// @Success      200  {file}    binary
// @Router       /samples/{id}/export [get]
func (ctrl *SampleController) ExportSamplePDF(c *fiber.Ctx) error {
	id, _ := c.ParamsInt("id")

	// 1. Ambil data dari DB
	sample, err := ctrl.sampleRepo.GetSampleByID(uint(id))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Data tidak ditemukan"})
	}

	// DEBUGGING: Cek di terminal Go lo, apakah Username & NIP muncul?
	// Jika di terminal muncul "KOSONG", berarti masalah ada di Repository/Database
	if sample.User.Username == "" {
		fmt.Printf("DEBUG: User data for Sample ID %d is EMPTY!\n", id)
	} else {
		fmt.Printf("DEBUG: User Found - Name: %s, NIP: %s\n", sample.User.Username, sample.User.Nip)
	}

	// 2. Mapping data (Gue bikin flat supaya HTML lo gampang bacanya)
	renderData := fiber.Map{
		"SampleID":   sample.SampleID,
		"CreatedAt":  sample.CreatedAt,
		"SampleName": sample.SampleName,
		"Condition":  sample.Condition,
		"IsReviewed": sample.IsReviewed,
		"User":       sample.User, // Sekarang ini sudah tidak tersembunyi
		"Station":    sample.Station,
		"Images":     sample.Images,
		"Now":        time.Now().Format("02-01-2006 15:04"),
	}

	// 3. Render HTML
	tmpl, err := template.ParseFiles("templates/sample_report.html")
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Template error: " + err.Error()})
	}

	var body bytes.Buffer
	if err := tmpl.Execute(&body, renderData); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Execute error: " + err.Error()})
	}

	// 4. Generate PDF
	wkhtmltopdf.SetPath(`C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe`)
	pdfg, err := wkhtmltopdf.NewPDFGenerator()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "PDF Engine error"})
	}

	pdfg.AddPage(wkhtmltopdf.NewPageReader(bytes.NewReader(body.Bytes())))
	pdfg.Dpi.Set(300)
	pdfg.Orientation.Set(wkhtmltopdf.OrientationPortrait)

	if err := pdfg.Create(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Gagal buat PDF"})
	}

	// 5. Kirim File
	fileName := fmt.Sprintf("Laporan-%d.pdf", id)
	c.Set("Content-Type", "application/pdf")
	c.Set("Content-Disposition", "attachment; filename="+fileName)

	return c.Send(pdfg.Bytes())
}
