-- ============================================================
-- Hive script: summarize raw catalog-search logs stored in HDFS
-- Goal: turn billions of messy search-log lines into a small,
--       clean summary that can be loaded into the SQL warehouse.
-- ============================================================

-- 1. Define an EXTERNAL table that points at raw log files in HDFS.
--    Hive reads the files where they already sit; it does not copy them.
--    Example log line (tab-separated):
--    2026-03-02 09:15:22   student   "big data"   3   Main
CREATE EXTERNAL TABLE IF NOT EXISTS search_logs (
    ts          STRING,   -- timestamp
    user_type   STRING,   -- student / faculty / staff / guest
    search_term STRING,
    results     INT,      -- number of hits returned
    branch      STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/library/logs/search/';   -- HDFS folder

-- 2. Find the 20 most common searches that returned ZERO results.
--    These "failed searches" tell the library which books to buy.
SELECT search_term,
       COUNT(*) AS times_searched
FROM   search_logs
WHERE  results = 0
GROUP  BY search_term
ORDER  BY times_searched DESC
LIMIT  20;

-- 3. Daily search volume per branch (this small result is what we
--    export as a CSV and load into dim/fact tables in the warehouse).
SELECT SUBSTR(ts, 1, 10) AS search_day,
       branch,
       COUNT(*)          AS searches
FROM   search_logs
GROUP  BY SUBSTR(ts, 1, 10), branch;
