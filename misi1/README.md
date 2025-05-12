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

## Profil Industri dan Masalah Bisnis

PT XYZ merupakan perusahaan pertambangan yang bergerak dalam eksplorasi dan produksi mineral dengan operasi yang melibatkan data kompleks dari berbagai departemen seperti keuangan, penjualan, inventaris, dan produksi. Industri pertambangan saat ini menghadapi tantangan pengelolaan data berskala besar (big data) dengan variasi tinggi, mulai dari data terstruktur (transaksi keuangan) hingga tidak terstruktur (laporan geologi), serta kebutuhan integrasi real-time untuk mendukung pengambilan keputusan strategis. PT XYZ mengalami masalah kritis seperti sistem database yang terfragmentasi antar-departemen, pembaruan data manual bulanan yang tidak real-time, kesulitan analisis data untuk pelaporan kinerja, dan kapasitas penyimpanan terbatas yang menghambat pengolahan data historis. 

Untuk mengatasi masalah tersebut, perusahaan mengimplementasikan SAP Business Warehouse (BW) sebagai solusi data warehousing terintegrasi yang memungkinkan konsolidasi data dari SAP S/4HANA dan sumber non-SAP, otomatisasi pembaruan data, serta analisis real-time guna mengoptimalkan proses bisnis dan daya saing industri.

---

## Pendekatan Pembangunan Gudang Data

Pendekatan yang diambil adalah top-down, di mana manajemen mendorong transformasi digital melalui penerapan SAP Business Warehouse (BW) secara menyeluruh untuk menjawab kebutuhan strategis perusahaan. SAP BW diterapkan sebagai data warehouse utama sebelum kemungkinan pengembangan data mart sebagai pelengkap. Implementasi dilakukan secara menyeluruh di seluruh sistem data perusahaan dan bukan sebagai proyek percontohan.

---

## Daftar Stakeholder dan Tujuan Bisnis

| Stakeholder        | Peran                           | Tujuan Bisnis |
|--------------------|----------------------------------|----------------|
| CEO                | Mengarahkan visi dan strategi perusahaan | Mengakselerasi transformasi digital dan mendukung efisiensi operasional |
| CTO                | Mengelola pengembangan teknologi | Mengintegrasikan sistem data ke SAP BW untuk pengambilan keputusan real-time |
| CMO                | Mengelola strategi pemasaran     | Merancang strategi berbasis tren dan data penjualan |
| CFO                | Mengelola keuangan perusahaan    | Menyediakan laporan keuangan akurat untuk efisiensi biaya dan investasi |
| Product Manager    | Mengelola pengembangan produk    | Menyelaraskan fitur produk dengan kebutuhan pasar berdasarkan insight data |

---

## Simulasi Wawancara

1. Apa hambatan terbesar dalam mengakses data lintas departemen saat ini?  
2. Bagaimana SAP BW dapat mempercepat pelaporan keuangan?  
3. Apa indikator kinerja utama (KPI) untuk mengukur keberhasilan integrasi data?  
4. Bagaimana data real-time dari alat berat dapat meningkatkan efisiensi produksi?  
5. Apa risiko utama jika integrasi data tidak tercapai?

---

## Fakta dan Dimensi

| Kebutuhan | Fakta | Dimensi |
|-----------|-------|---------|
| Analisis volume produksi harian, per shift, per lokasi, dan per jenis material | Production | Time, Site, Material, Employee, Shift |
| Evaluasi efisiensi penggunaan alat berat, downtime, dan konsumsi bahan bakar | Equipment_Usage | Time, Site, Equipment |
| Monitoring biaya operasional, evaluasi anggaran proyek, dan pelaporan keuangan berkala | Financials | Time, Site, Project, Account |
| Audit aktivitas lingkungan, pemantauan emisi/limbah, dan kepatuhan terhadap regulasi lingkungan | Environmental | Time, Site, Kegiatan_Lingkungan |

---

## Entity Relationship Diagram (ERD)

> **Catatan**: Diagram ERD tidak dapat ditampilkan dalam Markdown secara visual. Silakan rujuk ke dokumen asli atau gunakan tools visual seperti dbdiagram.io untuk merepresentasikan skema ERD berdasarkan uraian di bawah ini.

Fakta-fakta utama:
- Fact_Production
- Fact_Equipment_Usage
- Fact_Financials
- Fact_Environmental

Dimensi yang terkait:
- Dim_Time
- Dim_Site
- Dim_Material
- Dim_Employee
- Dim_Equipment
- Dim_Account

![skema_bintang](https://github.com/user-attachments/assets/390b6de6-6eb0-4d9a-9293-1876f9eb30e9)

---

## Sumber Data dan Metadata

| Sumber Data          | Deskripsi                                | Frekuensi Update | Contoh Data Simulasi |
|----------------------|-------------------------------------------|------------------|-----------------------|
| SAP S/4HANA          | Data transaksi keuangan dan produksi      | Real-time        | Produksi_Harian: 1500 ton; Biaya_Operasional: $12,500 |
| Sensor IoT Alat Berat| Data suhu, getaran, dan jam operasi alat  | Real-time        | Alat_ID: EX-001; Suhu: 75°C; Jam_Operasi: 320 jam/bulan |
| Laporan Lingkungan   | Pengukuran emisi dari stasiun pemantauan  | Harian           | Emisi_CO2: 45 ppm → 2.3 ton/bulan |
| Database Inventaris  | Catatan stok bahan baku dan suku cadang   | Mingguan         | Stok_Bijih_Tembaga: 8500 ton; Stok_Suku_Cadang: 120 unit |

---

## Referensi

- [Implementasi SAP BW pada industri pertambangan - Telkom University Repository](https://repository.telkomuniversity.ac.id/pustaka/files/170607/jurnal_eproc/implementasi-sap-business-warehouse-sebagai-data-warehousing-pada-industri-pertambangan-pt-xyz-.pdf)
