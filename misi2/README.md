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

## Ringkasan Kebutuhan dari Misi

PT XYZ merupakan perusahaan eksplorasi dan produksi mineral yang menghadapi tantangan besar dalam mengelola data dari berbagai departemen. Data berasal dari transaksi keuangan, laporan produksi, alat berat, dan pemantauan lingkungan.

Kebutuhan utama:

- **Analisis Volume Produksi**:  
  - Produksi tertinggi berdasarkan jenis material  
  - Realisasi produksi vs target per shift dan lokasi  
  - Produktivitas operator produksi  

- **Evaluasi Efisiensi Penggunaan Alat Berat**:  
  - Rata-rata jam operasi vs idle per jenis alat dan shift  
  - Downtime tertinggi per lokasi  
  - Konsumsi bahan bakar rata-rata  

- **Monitoring Keuangan dan Biaya Operasional**:  
  - Biaya aktual per proyek/lokasi/bulan  
  - Realisasi vs anggaran  
  - Proyek dengan pendapatan terbesar  

- **Pemantauan Kinerja Lingkungan**:  
  - Volume limbah/emisi bulanan  
  - Evaluasi reklamasi dan rehabilitasi  
  - Persentase kepatuhan terhadap regulasi  

---

## Analisis Dimensi, Fakta, dan Hierarki

| Dimension             | Hierarchy                     | Skenario Analisis        |
|-----------------------|-------------------------------|--------------------------|
| **Time**              | Day → Month → Year            | Semua analisis           |
| **Site**              | Site → Region → Country       | Semua analisis           |
| **Material**          | Material → Type → Category    | Produksi                 |
| **Equipment**         | Equipment → Equipment Type    | Alat Berat               |
| **Employee**          | Employee → Position → Dept.   | Produksi                 |
| **Project**           | Project → Department → Portf. | Keuangan                 |
| **Account**           | Account → Subcategory → Cat.  | Keuangan                 |
| **Shift**             | Shift (Morning/Afternoon/Night) | Produksi               |
| **Environmental_Activity** | Activity → Type → Regulation | Lingkungan           |

---

## SAP BW sebagai Solusi

PT XYZ memilih SAP Business Warehouse (BW) untuk integrasi data lintas departemen dari SAP S/4HANA, sensor IoT, laporan lingkungan, dan database inventaris. Keuntungan:

- Konsolidasi data real-time
- Laporan lebih akurat
- Analisis lintas departemen
- Efisiensi dan kecepatan dalam pengambilan keputusan

---

## Skema Konseptual Multidimensi

**Skema bintang (Star Schema)** digunakan sebagai pendekatan dengan tabel fakta utama dan dimensi pendukung.

### Tabel Fakta & Dimensi

| Proses Analitik                              | Tabel Fakta            | Dimensi Pendukung                                 |
|----------------------------------------------|-------------------------|---------------------------------------------------|
| Volume produksi harian                       | `fact_production`       | `dim_time`, `dim_site`, `dim_material`, `dim_employee`, `dim_shift` |
| Efisiensi alat berat                         | `fact_equipment_usage`  | `dim_time`, `dim_site`, `dim_equipment`          |
| Biaya operasional & anggaran proyek          | `fact_financials`       | `dim_time`, `dim_site`, `dim_project`, `dim_account` |
| Audit & monitoring emisi/limbah              | `fact_environmental`    | `dim_time`, `dim_site`, `dim_environmental_activity` |


![start_produksi](https://github.com/user-attachments/assets/42d0a9f8-4704-4a6d-8671-66907917cc4d)
![star_scka2](https://github.com/user-attachments/assets/7a66ddac-be74-4ffa-8c14-76bae2af84f1)
![start_3](https://github.com/user-attachments/assets/a12ae55b-7793-4eda-a2a8-db9b118e37e4)
![start4](https://github.com/user-attachments/assets/ea5cf7e5-6db2-4586-b1cb-64529333fe79)

---

## Penjelasan Tabel Fakta

- **fact_production**: Data produksi dan keterkaitannya dengan waktu, lokasi, material, karyawan, dan shift.
- **fact_equipment_usage**: Penggunaan alat berat berdasarkan waktu, lokasi, dan jenis alat.
- **fact_financials**: Keuangan proyek berdasarkan waktu, lokasi, proyek, dan akun.
- **fact_environmental**: Pemantauan aktivitas lingkungan seperti emisi dan reklamasi.

---

## Penjelasan Tabel Dimensi

| Nama Dimensi           | Deskripsi                              | Atribut                                     | Digunakan Oleh          |
|------------------------|-----------------------------------------|---------------------------------------------|-------------------------|
| Time                   | Waktu                                   | day, month, year, day_name                  | Semua                   |
| Site                   | Lokasi                                  | site_name, region, latitude, longitude      | Semua                   |
| Material               | Jenis material tambang                  | material_name, material_type, unit          | Produksi                |
| Employee               | Data karyawan                           | employee_name, position, department         | Produksi, Lingkungan    |
| Shift                  | Shift kerja                              | shift_name, start_time, end_time            | Produksi                |
| Equipment              | Alat berat                              | equipment_name, equipment_type, capacity    | Alat Berat              |
| Project                | Proyek                                  | project_name, status, start_date, end_date  | Keuangan                |
| Account                | Akun keuangan                           | account_name, account_type, budget_category | Keuangan                |
| Environmental_Activity | Aktivitas lingkungan                    | activity_name, category, impact_level       | Lingkungan              |

---

## Relasi Tabel

Contoh relasi `fact_production`:

- (N)---(1) `Time`: Waktu produksi  
- (N)---(1) `Site`: Lokasi tambang  
- (N)---(1) `Material`: Jenis material  
- (N)---(1) `Employee`: Operator produksi  
- (N)---(1) `Shift`: Shift kerja

Relasi serupa berlaku untuk fakta lain.

---

## Justifikasi Desain Konseptual

**Mengapa skema bintang?**

- Sederhana namun efektif
- Akses cepat dan fleksibel
- Modular dan skalabel
- Cocok untuk integrasi SAP BW & big data
- Mempermudah pelaporan untuk manajerial dan operasional

---

## Kesesuaian dengan Sumber Data

| Sumber Data              | Deskripsi                            | Frekuensi Update | Contoh Data Simulasi                        |
|--------------------------|---------------------------------------|------------------|---------------------------------------------|
| SAP S/4HANA              | Transaksi keuangan & produksi         | Real-time        | Produksi: 1500 ton; Biaya: $12,500          |
| Sensor IoT Alat Berat    | Data alat berat                       | Real-time        | Alat_ID: EX-001; Suhu: 75°C; 320 jam/bulan  |
| Laporan Lingkungan       | Emisi dari stasiun                    | Harian           | Emisi_CO2: 45 ppm → 2.3 ton/bulan           |
| Database Inventaris      | Stok bahan baku & suku cadang         | Mingguan         | Stok: 8500 ton bijih, 120 unit cadangan     |
