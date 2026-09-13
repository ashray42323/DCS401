/* ============================================================
   Pig script: clean the entry-gate scan logs stored in HDFS
   Goal: raw RFID gate scans are messy (blank IDs, duplicates).
         Pig cleans them, then counts daily entries per campus.
   Example raw line (comma-separated):
   2026-03-02 08:01:11,card_00123,Irvine,IN
   ============================================================ */

-- 1. Load raw gate logs from HDFS
gate = LOAD '/library/logs/gate/'
       USING PigStorage(',')
       AS (ts:chararray, card_id:chararray, campus:chararray, direction:chararray);

-- 2. Keep only valid "entry" scans (drop blanks and exits)
entries = FILTER gate BY (card_id IS NOT NULL)
                      AND (card_id != '')
                      AND (direction == 'IN');

-- 3. Pull the date part out of the timestamp
dated = FOREACH entries GENERATE
            SUBSTRING(ts, 0, 10) AS day,
            campus;

-- 4. Count entries per campus per day
grouped = GROUP dated BY (day, campus);
counts  = FOREACH grouped GENERATE
            group.day    AS day,
            group.campus AS campus,
            COUNT(dated) AS entries;

-- 5. Save the small, clean result back to HDFS for the warehouse ETL
STORE counts INTO '/library/output/daily_entries' USING PigStorage(',');
