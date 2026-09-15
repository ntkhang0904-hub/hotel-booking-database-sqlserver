-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 00_run_all_setup.sql
-- MO TA: Tap lenh tong hop Master Script chay toan bo du an
-- ============================================================================

-- LUA CHON 1 (Khuyen nghi):
-- Mo file "00_all_in_one_install.sql" trong SSMS va bam [Execute] (hoac F5).
-- File do da gom day du toan bo cac buoc: Tao bang, Nap du lieu, Views, Functions,
-- Stored Procedures, Triggers va Indexes ma khong can bat SQLCMD.

-- LUA CHON 2:
-- Chay lan luot cac file theo thu tu danh so:
-- 1. sql/01_schema_and_tables.sql
-- 2. sql/02_seed_sample_data.sql
-- 3. sql/03_views.sql
-- 4. sql/04_functions.sql
-- 5. sql/05_stored_procedures.sql
-- 6. sql/06_triggers.sql
-- 7. sql/07_advanced_queries.sql (De chay thu nghiem 16 cau query)
-- 8. sql/08_indexes_and_tuning.sql

PRINT '============================================================';
PRINT ' DU AN CSDL HOTEL BOOKING SYSTEM DA SAN SANG!';
PRINT ' Vui long mo file 00_all_in_one_install.sql de khoi tao toan bo.';
PRINT '============================================================';
GO
