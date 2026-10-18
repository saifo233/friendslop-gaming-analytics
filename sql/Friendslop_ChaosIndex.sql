/* =====================================================================
   FRIENDSLOP - CHAOS INDEX & ANALYSIS 

   ===================================================================== */


/* ---------- 1. JOIN CHECKS ---------- */

SELECT 'In Reviews, not in Games' AS issue, r.game_title
FROM (SELECT DISTINCT game_title FROM dbo.Friendslop_Reviews) r
LEFT JOIN dbo.Friendslop_Data g ON g.game_title = r.game_title
WHERE g.game_title IS NULL
UNION ALL
SELECT 'In Games, not in Reviews', g.game_title
FROM dbo.Friendslop_Data g
LEFT JOIN (SELECT DISTINCT game_title FROM dbo.Friendslop_Reviews) r ON r.game_title = g.game_title
WHERE r.game_title IS NULL;

SELECT game_title, COUNT(*) AS review_rows
FROM dbo.Friendslop_Reviews
GROUP BY game_title
HAVING COUNT(*) <> 100;

SELECT game_title, COUNT(*) AS rows_in_games
FROM dbo.Friendslop_Data
GROUP BY game_title
HAVING COUNT(*) > 1;
GO


/* ---------- 2. KEYWORD TABLE ----------*/

IF OBJECT_ID('dbo.ChaosKeywords') IS NOT NULL DROP TABLE dbo.ChaosKeywords;
CREATE TABLE dbo.ChaosKeywords (
    bucket     varchar(20) NOT NULL,
    keyword    varchar(30) NOT NULL,
    match_type char(1)     NOT NULL
);

INSERT INTO dbo.ChaosKeywords (bucket, keyword, match_type) VALUES
 ('chaos_fun','scream','P'), ('chaos_fun','laugh','P'),    ('chaos_fun','chao','P'),
 ('chaos_fun','hilarious','P'), ('chaos_fun','funny','P'),('chaos_fun','yell','P'),
 ('jank','jank','P'),  ('jank','glitch','P'), ('jank','bug','P'), ('jank','broken','E'),
 ('jank','crash','P'), ('jank','lag','E'),    ('jank','laggy','E'), ('jank','clunky','P'),
 ('betrayal','betray','P'), ('betrayal','troll','P'), ('betrayal','sabotag','P'),
 ('betrayal','grief','P'),  ('betrayal','kill','P'),  ('betrayal','steal','P');
GO

/* ---------- 3. NORMALISE TEXT ----------
   Scored reviews = usable AND longer than 3 characters.
   Lower-case, replace punctuation with spaces, pad with a space on each side
   so ' lag ' only matches the whole word.                                  */
DECLARE @punct nvarchar(100) = N'.,!?;:()"''-/\[]*~+=&%#@^_|<>{}`$';

IF OBJECT_ID('dbo.ReviewScores') IS NOT NULL DROP TABLE dbo.ReviewScores;

SELECT r.review_id,
       r.game_title,
       r.review_type,
       N' ' + TRANSLATE(LOWER(r.text_clean), @punct, REPLICATE(N' ', LEN(@punct))) + N' ' AS norm_text
INTO dbo.ReviewScores
FROM dbo.Friendslop_Reviews r
   WHERE r.is_usable = 1
     AND r.is_very_short = 0;
GO


/* ---------- 4. FLAG EACH REVIEW PER BUCKET ---------- */
IF OBJECT_ID('dbo.ReviewBucketHits') IS NOT NULL DROP TABLE dbo.ReviewBucketHits;

SELECT s.review_id, s.game_title, s.review_type,
       MAX(CASE WHEN k.bucket = 'chaos_fun' THEN 1 ELSE 0 END) AS chaos_fun,
       MAX(CASE WHEN k.bucket = 'jank'      THEN 1 ELSE 0 END) AS jank,
       MAX(CASE WHEN k.bucket = 'betrayal'  THEN 1 ELSE 0 END) AS betrayal
INTO dbo.ReviewBucketHits
FROM dbo.ReviewScores s
LEFT JOIN dbo.ChaosKeywords k
  ON (k.match_type = 'P' AND s.norm_text LIKE N'% ' + k.keyword + N'%')
  OR (k.match_type = 'E' AND s.norm_text LIKE N'% ' + k.keyword + N' %')
GROUP BY s.review_id, s.game_title, s.review_type;
GO


/* ---------- 5. CHAOS INDEX PER GAME ----------*/

IF OBJECT_ID('dbo.ChaosIndex') IS NOT NULL DROP TABLE dbo.ChaosIndex;

SELECT game_title,
       COUNT(*) AS reviews_scored,
       CAST(100.0 * SUM(chaos_fun) / COUNT(*) AS decimal(5,1)) AS chaos_fun_pct,
       CAST(100.0 * SUM(jank)      / COUNT(*) AS decimal(5,1)) AS jank_pct,
       CAST(100.0 * SUM(betrayal)  / COUNT(*) AS decimal(5,1)) AS betrayal_pct,
       CAST(100.0 * SUM(CASE WHEN chaos_fun + jank + betrayal > 0 THEN 1 ELSE 0 END)
                  / COUNT(*) AS decimal(5,1)) AS any_keyword_pct
INTO dbo.ChaosIndex
FROM dbo.ReviewBucketHits
GROUP BY game_title;
GO

/* ---------- 6. JOINED VIEW  ---------- */
CREATE OR ALTER VIEW dbo.vw_GameAnalysis AS
SELECT g.game_title, g.release_year, g.era, g.sub_genre, g.key_social_feature,
       g.price_type, g.price_usd, g.peak_players,
       g.positive_reviews, g.negative_reviews, g.total_reviews,
       CAST(100.0 * g.positive_reviews / NULLIF(g.total_reviews, 0) AS decimal(5,1)) AS lifetime_positive_pct,
       g.estimated_owners,
       g.owners_per_review,
       g.estimated_revenue_usd,
       c.reviews_scored, c.chaos_fun_pct, c.jank_pct, c.betrayal_pct, c.any_keyword_pct
FROM dbo.Friendslop_Data g
JOIN dbo.ChaosIndex c ON c.game_title = g.game_title;
GO

SELECT * FROM dbo.vw_GameAnalysis ORDER BY release_year, game_title;
GO


/* ---------- 7. DO CHAOS / JANK RATES RELATE TO SUCCESS? ----------  */
WITH pairs AS (
    SELECT m.metric, v.outcome, CAST(m.x AS float) AS x, CAST(v.y AS float) AS y
    FROM dbo.vw_GameAnalysis a
    CROSS APPLY (VALUES ('chaos_fun', a.chaos_fun_pct),
                        ('jank',      a.jank_pct),
                        ('betrayal',  a.betrayal_pct)) m(metric, x)
    CROSS APPLY (VALUES ('log_owners', LOG10(CAST(a.estimated_owners AS float))),
                        ('log_peak',   LOG10(CAST(a.peak_players     AS float)))) v(outcome, y)
),
stats AS (
    SELECT metric, outcome, COUNT(*) AS n,
           SUM(x) AS sx, SUM(y) AS sy, SUM(x*y) AS sxy, SUM(x*x) AS sxx, SUM(y*y) AS syy
    FROM pairs GROUP BY metric, outcome
)
SELECT metric, outcome, n,
       ROUND((n*sxy - sx*sy) / NULLIF(SQRT((n*sxx - sx*sx) * (n*syy - sy*sy)), 0), 2) AS pearson_r
FROM stats
ORDER BY outcome, metric;
GO


/* ---------- 8. BUSINESS QUESTIONS ---------- */

-- 8a. Median owners and peak players by social feature
SELECT DISTINCT key_social_feature,
       COUNT(*) OVER (PARTITION BY key_social_feature) AS games,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_owners) OVER (PARTITION BY key_social_feature) AS median_owners,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY peak_players)     OVER (PARTITION BY key_social_feature) AS median_peak_players
FROM dbo.vw_GameAnalysis
ORDER BY median_owners DESC;

-- 8b. Same, by sub-genre
SELECT DISTINCT sub_genre,
       COUNT(*) OVER (PARTITION BY sub_genre) AS games,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_owners) OVER (PARTITION BY sub_genre) AS median_owners,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY peak_players)     OVER (PARTITION BY sub_genre) AS median_peak_players
FROM dbo.vw_GameAnalysis
ORDER BY median_peak_players DESC;

-- 8c. Median revenue by social feature - PAID GAMES ONLY
SELECT DISTINCT key_social_feature,
       COUNT(*) OVER (PARTITION BY key_social_feature) AS paid_games,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_revenue_usd) OVER (PARTITION BY key_social_feature) AS median_revenue_usd
FROM dbo.vw_GameAnalysis
WHERE price_type = 'Paid'
ORDER BY median_revenue_usd DESC;

-- 8d. Pre-2023 vs 2023+
SELECT DISTINCT era,
       COUNT(*) OVER (PARTITION BY era) AS games,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_owners) OVER (PARTITION BY era) AS median_owners,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY peak_players)     OVER (PARTITION BY era) AS median_peak_players,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_usd)        OVER (PARTITION BY era) AS median_price_usd
FROM dbo.vw_GameAnalysis;

-- 8e. Owners (total estimated) by release year, for the time-series chart
SELECT release_year, COUNT(*) AS games, SUM(estimated_owners) AS total_owners
FROM dbo.vw_GameAnalysis
GROUP BY release_year
ORDER BY release_year;

-- 8f. Recent sentiment (the 100 latest reviews) vs lifetime sentiment
WITH recent AS (
    SELECT game_title,
           100.0 * SUM(CASE WHEN review_type = 'Recommended' THEN 1 ELSE 0 END) / COUNT(*) AS recent_positive_pct
    FROM dbo.Friendslop_Reviews
    GROUP BY game_title
)
SELECT a.game_title,
       a.lifetime_positive_pct,
       CAST(r.recent_positive_pct AS decimal(5,1)) AS recent_positive_pct,
       CAST(r.recent_positive_pct - a.lifetime_positive_pct AS decimal(5,1)) AS gap_pts
FROM dbo.vw_GameAnalysis a
JOIN recent r ON r.game_title = a.game_title
ORDER BY gap_pts;

/* ---------- 9. EXPORT: CHAOS INDEX BY GAME ---------- */
SELECT game_title, era, sub_genre, key_social_feature,
       reviews_scored, chaos_fun_pct, jank_pct, betrayal_pct, any_keyword_pct
FROM dbo.vw_GameAnalysis
ORDER BY game_title;
GO
