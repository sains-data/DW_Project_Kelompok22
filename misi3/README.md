# Laporan Analisis Kebutuhan Bisnis dan Teknis Perancangan Data Warehouse di Industri Pertambangan dan Sumber Daya Mineral pada PT XYZ
![Logoitera](https://github.com/user-attachments/assets/dd5bb448-e048-401e-9bf1-0265f9030ef7)
## Disusun Oleh

- Ericson Chandra Sihombing (121450026)  
- Ramadhita Atifa Hendri (121450131)  
- Eggi Satria (122450032)  
- Nabila Anilda Zahrah (122450063)  
- Syalaisha Andini Putriansyah (122450111)  

Program Studi Sains Data  
Fakultas Sains  
Institut Teknologi Sumatera  
2025

---

## Alur Aliran Data

![gambar1](https://github.com/user-attachments/assets/3ffdb87b-ee4f-4e01-b121-f4cc5cc49b74)
Aliran data PT XYZ berasal dari SAP S/4HANA dan IoT Sensor Alat Berat. Data dikumpulkan dalam berbagai format (Excel, CSV), kemudian diekstrak menggunakan SSIS OLEDB ke SQL Server. Setelah validasi dan transformasi, data dimasukkan ke dalam star schema (tabel fakta dan dimensi). Visualisasi dilakukan melalui SSRS dan Power BI.

---

## Arsitektur

Struktur Three-Tier Architecture digunakan:

![gambar2](https://github.com/user-attachments/assets/3e4dccb5-d148-49e8-bf39-31c6011dba0d)
1. **Alur Aliran Data**:  
   - Sumber: SAP, IoT  
   - Pengambilan: SSIS OLEDB  
   - Staging Area → Transformasi → Data Warehouse → Laporan  
2. **ETL**:  
   - Extract → Transform → Load  
3. **Teknologi**:  
   - SQL Server, SSMS, SSDT, SSIS, SSRS, Power BI  
4. **Star Schema**:  
   - Fakta: produksi, alat berat, keuangan, lingkungan  
   - Dimensi: waktu, lokasi, material, karyawan, dll  
5. **Proses Pengolahan**:  
   - ETL → Visualisasi  
6. **Keamanan & Pemantauan**:  
   - SQL Profiler, DMVs, SQL Server Agent  
7. **Query Analitik**:  
   - Produksi, idle time, pendapatan, penggunaan alat berat

---

## ETL Pipeline

- **Extract**: SAP S/4HANA, IoT, Excel  
- **Transform**:  
  - Pembersihan data  
  - Penyatuan format & entitas  
- **Load**:  
  - Dimensi → Fakta  
  - Rutin & terjadwal  
- Manfaat:  
  - Gabungkan data multi-sumber  
  - Siap digunakan oleh semua unit bisnis  

---

## Alat yang Digunakan

### 4.1 Pemodelan & Desain Skema

- **SSMS**: GUI untuk desain & visualisasi skema  
- **SSDT**: Pengembangan modular, validasi & version control  

### 4.3 Integrasi & ETL

- **SSIS**:  
  - Control Flow & Data Flow  
  - Transformasi: Lookup, Derived Column, dsb  
  - Terjadwal via SQL Server Agent  

### 4.4 Pemantauan & Optimasi

- **SQL Profiler**: Debugging & monitoring query  
- **DMVs**: Monitoring performa secara programatik  

### 4.5 Visualisasi & Laporan

- **SSRS**:  
  - Laporan otomatis, grafik, tabulasi  
- **Power BI**:  
  - Dashboard interaktif, integrasi SQL  

![gambar3](https://github.com/user-attachments/assets/d9b82035-6c3a-4fbb-9191-7a68015b2b99)

---

# 5. Script Query

Membangun sistem data warehouse menjadi langkah penting bagi PT XYZ dalam menyatukan berbagai data operasional di industri pertambangan. Melalui skrip SQL yang dirancang khusus, perusahaan dapat menyusun struktur data yang mencakup tabel fakta dan dimensi, menghubungkan informasi penting seperti aktivitas produksi tambang, performa alat berat, pemantauan lingkungan, hingga kepatuhan terhadap peraturan keselamatan. Pendekatan ini memungkinkan analisis yang lebih mendalam dan real-time, sehingga manajemen dapat mengambil keputusan strategis dengan lebih percaya diri dan berbasis data yang akurat.  

## 5.1 DDL

```sql
-- Fakta Produksi
CREATE TABLE fact_production (
    production_id INT IDENTITY(1,1) PRIMARY KEY,
    time_key INT FOREIGN KEY REFERENCES dim_time(time_key),
    site_key INT FOREIGN KEY REFERENCES dim_site(site_key),
    material_key INT FOREIGN KEY REFERENCES dim_material(material_key),
    employee_key INT FOREIGN KEY REFERENCES dim_employee(employee_key),
    shift_key INT FOREIGN KEY REFERENCES dim_shift(shift_key),
    volume_produced FLOAT,
    production_target FLOAT
);
-- Fakta Penggunaan Alat Berat
CREATE TABLE fact_equipment_usage (
    usage_id INT IDENTITY(1,1) PRIMARY KEY,
    time_key INT FOREIGN KEY REFERENCES dim_time(time_key),
    site_key INT FOREIGN KEY REFERENCES dim_site(site_key),
    equipment_key INT FOREIGN KEY REFERENCES dim_equipment(equipment_key),
    operating_hours FLOAT,
    idle_hours FLOAT,
    fuel_consumed FLOAT
);
-- Fakta Keuangan
CREATE TABLE fact_financials (
    financial_id INT IDENTITY(1,1) PRIMARY KEY,
    time_key INT FOREIGN KEY REFERENCES dim_time(time_key),
    site_key INT FOREIGN KEY REFERENCES dim_site(site_key),
    project_key INT FOREIGN KEY REFERENCES dim_project(project_key),
    account_key INT FOREIGN KEY REFERENCES dim_account(account_key),
    actual_cost DECIMAL(18,2),
    budget_cost DECIMAL(18,2),
    revenue DECIMAL(18,2)
);
-- Fakta Lingkungan
CREATE TABLE fact_environmental (
    env_id INT IDENTITY(1,1) PRIMARY KEY,
    time_key INT FOREIGN KEY REFERENCES dim_time(time_key),
    site_key INT FOREIGN KEY REFERENCES dim_site(site_key),
    activity_key INT FOREIGN KEY REFERENCES dim_environmental_activity(activity_key),
    emission_volume FLOAT,
    waste_volume FLOAT,
    compliance_percent FLOAT
);
-- Dimensi Waktu
CREATE TABLE dim_time (
    time_key INT PRIMARY KEY,
    full_date DATE,
    day INT,
    month INT,
    year INT,
    day_name NVARCHAR(20)
);
-- Dimensi Lokasi Tambang
CREATE TABLE dim_site (
    site_key INT IDENTITY(1,1) PRIMARY KEY,
    site_name NVARCHAR(100),
    region NVARCHAR(100),
    latitude FLOAT,
    longitude FLOAT
);
-- Dimensi Material
CREATE TABLE dim_material (
    material_key INT IDENTITY(1,1) PRIMARY KEY,
    material_name NVARCHAR(100),
    material_type NVARCHAR(50),
    unit_of_measure NVARCHAR(20)
);
-- Dimensi Karyawan
CREATE TABLE dim_employee (
    employee_key INT IDENTITY(1,1) PRIMARY KEY,
    employee_name NVARCHAR(100),
    position NVARCHAR(50),
    department NVARCHAR(50),
    hire_date DATE
);
-- Dimensi Shift
CREATE TABLE dim_shift (
    shift_key INT IDENTITY(1,1) PRIMARY KEY,
    shift_name NVARCHAR(50),
    start_time TIME,
    end_time TIME
);
-- Dimensi Alat Berat
CREATE TABLE dim_equipment (
    equipment_key INT IDENTITY(1,1) PRIMARY KEY,
    equipment_name NVARCHAR(100),
    equipment_type NVARCHAR(50),
    model NVARCHAR(50),
    capacity FLOAT
);
-- Dimensi Proyek
CREATE TABLE dim_project (
    project_key INT IDENTITY(1,1) PRIMARY KEY,
    project_name NVARCHAR(100),
    status NVARCHAR(50),
    start_date DATE,
    end_date DATE
);
-- Dimensi Akun
CREATE TABLE dim_account (
    account_key INT IDENTITY(1,1) PRIMARY KEY,
    account_name NVARCHAR(100),
    account_type NVARCHAR(50),
    budget_category NVARCHAR(50)
);
-- Dimensi Aktivitas Lingkungan
CREATE TABLE dim_environmental_activity (
    activity_key INT IDENTITY(1,1) PRIMARY KEY,
    activity_name NVARCHAR(100),
    category NVARCHAR(50),
    impact_level NVARCHAR(50)
);
```

## 5.2 Query Analitik

```sql
-- 1. Produksi tertinggi berdasarkan material dan lokasi
SELECT DM.material_name, SUM(FP.volume_produced) AS total_Production
FROM fact_production FP
JOIN material DM ON FP.material_key = DM.material_key
GROUP BY DM.material_name
ORDER BY total_Production DESC;

-- 2. Total produksi berdasarkan waktu, shift, dan material
SELECT
    d_time.date,
    d_shift.shift_name,
    d_site.site_name,
    d_material.material_type,
    SUM(f.production_volume) AS total_production
FROM
    fact_operational_data f
JOIN dim_time d_time ON f.time_id = d_time.time_id
JOIN dim_shift d_shift ON f.shift_id = d_shift.shift_id
JOIN dim_site d_site ON f.site_id = d_site.site_id
JOIN dim_material d_material ON f.material_id = d_material.material_id
GROUP BY d_time.date, d_shift.shift_name, d_site.site_name, d_material.material_type;

-- 3. Proyek dengan pendapatan terbesar 
SELECT P.project_name, SUM(F.revenue) AS total_revenue
FROM fact_financials F
JOIN dim_project P ON F.project_key = P.project_key
GROUP BY P.project_name
ORDER BY total_revenue DESC;

-- 4. Alat berat dengan Downtime tertinggi
SELECT E.equipment_name, SUM(downtime_hours) AS total_idle
FROM fact_equipment_usage F
JOIN dim_equipment E ON F.equipment_key = E.equipment_key
GROUP BY E.equipment_name
ORDER BY total_idle DESC;

-- 5. Rata-rata jam penggunaan alat berat
SELECT
    E.equipment_type,
    d_shift.shift_name,
    AVG(f.equipment_usage_hours) AS avg_usage
FROM fact_operational f
JOIN dim_equipment d_equipment ON f.equipment_id = d_equipment.equipment_id
JOIN dim_shift d_shift ON f.shift_id = d_shift.shift_id
GROUP BY d_equipment.equipment_type, d_shift.shift_name;
```

## 5.3 Indexing

```sql
CREATE NONCLUSTERED INDEX idx_time_id ON fact_production(time_id);
CREATE NONCLUSTERED INDEX idx_equipment ON fact_equipment_usage(equipment_id);
CREATE NONCLUSTERED INDEX idx_account_project ON fact_financials(account_id, project_id);
CREATE NONCLUSTERED INDEX idx_env_time_site ON fact_environmental(time_id, site_id);
```

## 5.4 Partitioning

```sql
CREATE PARTITION FUNCTION pf_YearRange (int) AS RANGE LEFT FOR VALUES (2021, 2022, 2023);
CREATE PARTITION SCHEME ps_YearScheme AS PARTITION pf_YearRange ALL TO ([PRIMARY]);
CREATE TABLE fact_production (...) ON ps_YearScheme(year);
CREATE VIEW vw_production_2023 AS SELECT * FROM fact_production WHERE year = 2023;
```