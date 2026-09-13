-- ============================================================
-- DCS 401 - Week 3 Assignment
-- University Library Data Warehouse (Star Schema)
-- Author: Sun (Westcliff University)
-- Standard SQL. Tested on SQLite; notes show MySQL/PostgreSQL variants.
-- ============================================================

-- ---------- Clean start (safe to re-run) ----------
DROP VIEW  IF EXISTS v_monthly_loans_by_subject;
DROP TABLE IF EXISTS fact_loan;
DROP TABLE IF EXISTS dim_book;
DROP TABLE IF EXISTS dim_member;
DROP TABLE IF EXISTS dim_branch;
DROP TABLE IF EXISTS dim_date;

-- ============================================================
-- 1. DIMENSION TABLES
-- ============================================================

-- Books that can be borrowed
CREATE TABLE dim_book (
    book_id       INTEGER PRIMARY KEY,
    title         TEXT    NOT NULL,
    author        TEXT,
    subject       TEXT,            -- e.g. 'Data Science', 'History'
    publisher     TEXT,
    publish_year  INTEGER
);

-- Library members (students, faculty, staff)
CREATE TABLE dim_member (
    member_id     INTEGER PRIMARY KEY,
    member_type   TEXT,            -- 'Student', 'Faculty', 'Staff'
    department    TEXT,
    join_date     TEXT
);

-- Physical library branches / campuses
CREATE TABLE dim_branch (
    branch_id     INTEGER PRIMARY KEY,
    branch_name   TEXT,
    campus        TEXT
);

-- Calendar dimension (one row per day)
CREATE TABLE dim_date (
    date_id       INTEGER PRIMARY KEY,   -- format YYYYMMDD, e.g. 20260302
    full_date     TEXT,
    month_name    TEXT,
    quarter       INTEGER,
    year          INTEGER,
    is_weekend    INTEGER               -- 0 = weekday, 1 = weekend
);

-- ============================================================
-- 2. FACT TABLE (one row per book loan)
-- ============================================================
CREATE TABLE fact_loan (
    loan_id           INTEGER PRIMARY KEY,
    book_id           INTEGER NOT NULL,
    member_id         INTEGER NOT NULL,
    branch_id         INTEGER NOT NULL,
    checkout_date_id  INTEGER NOT NULL,
    return_date_id    INTEGER,          -- NULL if not returned yet
    days_kept         INTEGER,          -- measure
    fine_amount       REAL,             -- measure (USD)
    renewed_count     INTEGER,          -- measure
    FOREIGN KEY (book_id)          REFERENCES dim_book(book_id),
    FOREIGN KEY (member_id)        REFERENCES dim_member(member_id),
    FOREIGN KEY (branch_id)        REFERENCES dim_branch(branch_id),
    FOREIGN KEY (checkout_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (return_date_id)   REFERENCES dim_date(date_id)
);

-- ============================================================
-- 3. INDEXES
-- Foreign-key columns are the ones we JOIN and FILTER on most,
-- so indexing them speeds up analytical queries.
-- ============================================================
CREATE INDEX idx_loan_book     ON fact_loan(book_id);
CREATE INDEX idx_loan_member   ON fact_loan(member_id);
CREATE INDEX idx_loan_branch   ON fact_loan(branch_id);
CREATE INDEX idx_loan_checkout ON fact_loan(checkout_date_id);

-- ============================================================
-- 4. SAMPLE DATA (small, realistic set)
-- ============================================================
INSERT INTO dim_book VALUES
 (1,'Big Data: Principles and Best Practices','Nathan Marz','Data Science','Manning',2015),
 (2,'The Data Warehouse Toolkit','Ralph Kimball','Data Science','Wiley',2013),
 (3,'A Brief History of Time','Stephen Hawking','Physics','Bantam',1998),
 (4,'Sapiens','Yuval Noah Harari','History','Harper',2015),
 (5,'Clean Code','Robert C. Martin','Software Engineering','Prentice Hall',2008);

INSERT INTO dim_member VALUES
 (101,'Student','Computer Science','2025-08-20'),
 (102,'Student','Business','2025-08-21'),
 (103,'Faculty','Computer Science','2019-01-10'),
 (104,'Student','Physics','2024-08-19'),
 (105,'Staff','Library','2018-05-05');

INSERT INTO dim_branch VALUES
 (1,'Main Library','Irvine'),
 (2,'Downtown Annex','Los Angeles');

INSERT INTO dim_date VALUES
 (20260302,'2026-03-02','March',1,2026,0),
 (20260303,'2026-03-03','March',1,2026,0),
 (20260310,'2026-03-10','March',1,2026,0),
 (20260314,'2026-03-14','March',1,2026,1),
 (20260401,'2026-04-01','April',2,2026,0),
 (20260405,'2026-04-05','April',2,2026,1);

-- fact rows: (loan, book, member, branch, checkout, return, days, fine, renewals)
INSERT INTO fact_loan VALUES
 (5001,1,101,1,20260302,20260310, 8,0.00,0),
 (5002,2,103,1,20260302,20260314,12,0.00,1),
 (5003,3,104,2,20260303,20260401,29,4.50,0),
 (5004,1,102,1,20260310,NULL,      NULL,NULL,0),
 (5005,4,101,1,20260314,20260401,18,1.50,1),
 (5006,2,102,2,20260401,20260405, 4,0.00,0),
 (5007,5,103,1,20260401,NULL,      NULL,NULL,0);

-- ============================================================
-- 5. ANALYTICAL QUERIES (examples)
-- ============================================================

-- Q1: Which subjects are borrowed most? (JOIN + GROUP BY)
SELECT b.subject,
       COUNT(*)            AS total_loans,
       AVG(f.days_kept)    AS avg_days_kept
FROM   fact_loan f
JOIN   dim_book  b ON f.book_id = b.book_id
GROUP  BY b.subject
ORDER  BY total_loans DESC;

-- Q2: Total fines collected per branch
SELECT br.branch_name,
       SUM(f.fine_amount) AS total_fines
FROM   fact_loan  f
JOIN   dim_branch br ON f.branch_id = br.branch_id
GROUP  BY br.branch_name;

-- Q3: Books still out (not yet returned)
SELECT f.loan_id, b.title, m.member_type, d.full_date AS checked_out_on
FROM   fact_loan  f
JOIN   dim_book   b ON f.book_id   = b.book_id
JOIN   dim_member m ON f.member_id = m.member_id
JOIN   dim_date   d ON f.checkout_date_id = d.date_id
WHERE  f.return_date_id IS NULL;

-- ============================================================
-- 6. VIEW: monthly loan counts per subject (reusable report)
-- ============================================================
CREATE VIEW v_monthly_loans_by_subject AS
SELECT d.year,
       d.month_name,
       b.subject,
       COUNT(*) AS loans
FROM   fact_loan f
JOIN   dim_book  b ON f.book_id = b.book_id
JOIN   dim_date  d ON f.checkout_date_id = d.date_id
GROUP  BY d.year, d.month_name, b.subject;

-- Use the view like a normal table:
SELECT * FROM v_monthly_loans_by_subject ORDER BY loans DESC;
