RESET ROLE;

CREATE SCHEMA IF NOT EXISTS SALAM;

CREATE TABLE IF NOT EXISTS SALAM.mahasiswas (
    nim CHAR(10) PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    semester INT CHECK (semester BETWEEN 1 AND 14),
    ipk NUMERIC(3, 2) CHECK (ipk >= 0.00 AND ipk <= 4.00)
);

INSERT INTO SALAM.mahasiswas (nim, nama, email, semester, ipk) 
VALUES ('1237050001', 'Ahmad Fauzi', 'ahmad@salam.ac.id', 5, 3.75)
ON CONFLICT (nim) DO NOTHING;

CREATE USER backend_dev WITH PASSWORD 'backend_pass';
CREATE USER bi_dev WITH PASSWORD 'bi_pass';
CREATE USER data_engineer WITH PASSWORD 'de_pass';

GRANT USAGE ON SCHEMA SALAM TO backend_dev;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA SALAM TO backend_dev;
ALTER DEFAULT PRIVILEGES IN SCHEMA SALAM GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO backend_dev;

GRANT USAGE ON SCHEMA SALAM TO bi_dev;
GRANT SELECT ON ALL TABLES IN SCHEMA SALAM TO bi_dev;
ALTER DEFAULT PRIVILEGES IN SCHEMA SALAM GRANT SELECT ON TABLES TO bi_dev;

GRANT ALL PRIVILEGES ON SCHEMA SALAM TO data_engineer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA SALAM TO data_engineer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA SALAM TO data_engineer;
ALTER DEFAULT PRIVILEGES IN SCHEMA SALAM GRANT ALL PRIVILEGES ON TABLES TO data_engineer;

CREATE TABLE IF NOT EXISTS SALAM.matakuliahs (
    kode_mk VARCHAR(10) PRIMARY KEY,
    nama_mk VARCHAR(100) UNIQUE NOT NULL,
    sks INT CHECK (sks BETWEEN 1 AND 6),
    kuota INT CHECK (kuota >= 0)
);

CREATE TABLE IF NOT EXISTS SALAM.krs_mahasiswa (
    id_krs SERIAL PRIMARY KEY,
    nim CHAR(10) REFERENCES SALAM.mahasiswas(nim) ON DELETE CASCADE,
    kode_mk VARCHAR(10) REFERENCES SALAM.matakuliahs(kode_mk) ON DELETE CASCADE,
    nilai_angka NUMERIC(5, 2) CHECK (nilai_angka BETWEEN 0.00 AND 100.00),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (nim, kode_mk)
);

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA SALAM TO backend_dev, data_engineer;

INSERT INTO SALAM.matakuliahs (kode_mk, nama_mk, sks, kuota) VALUES
('IF501', 'Manajemen Basis Data', 3, 40),
('IF502', 'Artificial Intelligence', 3, 35),
('IF503', 'Pengembangan Aplikasi Mobile', 3, 30),
('IF504', 'Manajemen Proyek Perangkat Lunak', 3, 40)
ON CONFLICT (kode_mk) DO NOTHING;

CREATE OR REPLACE FUNCTION SALAM.update_timestamp_krs()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_krs ON SALAM.krs_mahasiswa;
CREATE TRIGGER trg_update_krs
BEFORE UPDATE ON SALAM.krs_mahasiswa
FOR EACH ROW
EXECUTE FUNCTION SALAM.update_timestamp_krs();

BEGIN;

INSERT INTO SALAM.mahasiswas (nim, nama, email, semester, ipk)
VALUES ('1237050001', 'Ahmad Fauzi', 'ahmad@salam.ac.id', 5, 3.75)
ON CONFLICT (nim) DO NOTHING;

INSERT INTO SALAM.krs_mahasiswa (nim, kode_mk, nilai_angka) VALUES
('1237050001', 'IF501', 88.50), -- Manajemen Basis Data
('1237050001', 'IF502', 90.00), -- Artificial Intelligence
('1237050001', 'IF503', 85.00), -- Pengembangan Aplikasi Mobile
('1237050001', 'IF504', 92.00)  -- Manajemen Proyek Perangkat Lunak
ON CONFLICT (nim, kode_mk) DO NOTHING;

UPDATE SALAM.matakuliahs SET kuota = kuota - 1 WHERE kode_mk IN ('IF501', 'IF502', 'IF503', 'IF504');

COMMIT;

BEGIN;

UPDATE SALAM.krs_mahasiswa SET nilai_angka = 50.00 WHERE nim = '1237050001' AND kode_mk = 'IF502';

ROLLBACK;

SELECT * FROM SALAM.krs_mahasiswa WHERE nim = '1237050001';

CREATE OR REPLACE VIEW SALAM.v_rekap_nilai_matkul AS
SELECT 
    m.nim,
    m.nama AS nama_mahasiswa,
    mk.kode_mk,
    mk.nama_mk,
    mk.sks,
    k.nilai_angka,
    CASE 
        WHEN k.nilai_angka >= 85 THEN 'A'
        WHEN k.nilai_angka >= 75 THEN 'B'
        WHEN k.nilai_angka >= 65 THEN 'C'
        ELSE 'D'
    END AS nilai_huruf,
    k.updated_at
FROM SALAM.krs_mahasiswa k
JOIN SALAM.mahasiswas m ON k.nim = m.nim
JOIN SALAM.matakuliahs mk ON k.kode_mk = mk.kode_mk;

GRANT SELECT ON SALAM.v_rekap_nilai_matkul TO bi_dev;

SET ROLE backend_dev;
INSERT INTO SALAM.mahasiswas VALUES ('1237050009', 'Tes Backend', 'be@salam.ac.id', 5, 3.20);

RESET ROLE;

SET ROLE bi_dev;
SELECT * FROM SALAM.v_rekap_nilai_matkul;

RESET ROLE;

SET ROLE data_engineer;
CREATE TABLE SALAM.log_uji_de (id INT PRIMARY KEY, keterangan VARCHAR(50));
INSERT INTO SALAM.log_uji_de VALUES (1, 'Uji coba oleh Data Engineer');
ALTER TABLE SALAM.log_uji_de ADD COLUMN waktu TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
DROP TABLE SALAM.log_uji_de;
RESET ROLE;