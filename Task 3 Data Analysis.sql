CREATE DATABASE eklipse_db;
USE eklipse_db;

CREATE TABLE gamesession (
    id INT PRIMARY KEY,
    user_id INT,
    duration BIGINT,
    submited_date DATETIME,
    created_at DATETIME,
    game_name VARCHAR(255),
    join_at DATETIME
);

CREATE TABLE gamesession (
    id INT PRIMARY KEY,
    user_id INT,
    duration BIGINT,
    submited_date DATETIME,
    created_at DATETIME,
    game_name VARCHAR(255),
    join_at DATETIME
);

CREATE TABLE clips (
  id INT PRIMARY KEY,
  user_id INT,
  gamesession_id INT,
  clip_type_id INT,
  event_name VARCHAR(255),
  game_name VARCHAR(255),
  duration INT, 
  created_at DATETIME,
  join_at DATETIME
);

CREATE TABLE premium (
  user_id INT PRIMARY KEY,
  starts_at DATETIME,
  ends_at DATETIME,
  created_at DATETIME,
  updated_at DATETIME,
  canceled_at DATETIME,
  deleted_at DATETIME,
  join_at DATETIME
);

CREATE TABLE downloaded_clips (
  id INT PRIMARY KEY,
  user_id INT,
  clip_id INT,
  gamesession_id INT,
  created_at DATETIME,
  join_at DATETIME
);

CREATE TABLE shared_clips (
  user_id INT,
  clip_id INT,
  gamesession_id INT,
  created_at DATETIME,
  scheduled_at DATETIME,
  join_at DATETIME,
  PRIMARY KEY (user_id, clip_id) 
);

SELECT DATABASE();
SHOW TABLES;

SELECT * FROM gamesession LIMIT 10;
SELECT * FROM clips LIMIT 10;
SELECT * FROM downloaded_clips LIMIT 10;
SELECT * FROM shared_clips LIMIT 10;
SELECT * FROM premium LIMIT 10;

SELECT MIN(created_at), MAX(created_at) FROM gamesession;
SELECT MIN(created_at), MAX(created_at) FROM clips;

-- 1. CLIP ENGAGEMENT ANALYSIS
-- Joins: clips + downloaded_clips + shared_clips + premium
-- Purpose: Analyze monthly clip engagement activity segmented by premium/free status
WITH clip_activity AS (
    SELECT user_id, DATE(created_at) AS activity_date, 'upload' AS activity_type
    FROM clips
    WHERE created_at BETWEEN '2023-05-01' AND '2023-12-31'
    UNION ALL
    SELECT user_id, DATE(created_at), 'download'
    FROM downloaded_clips
    WHERE created_at BETWEEN '2023-05-01' AND '2023-12-31'
    UNION ALL
    SELECT user_id, DATE(created_at), 'share'
    FROM shared_clips
    WHERE created_at BETWEEN '2023-05-01' AND '2023-12-31'
),
monthly_clip_engagement AS (
    SELECT
        user_id,
        DATE_FORMAT(activity_date, '%Y-%m') AS month,
        COUNT(*) AS total_clip_engagement
    FROM clip_activity
    GROUP BY user_id, DATE_FORMAT(activity_date, '%Y-%m')
),
user_status AS (
    SELECT DISTINCT
        mce.user_id,
        mce.month,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM premium p
                WHERE p.user_id = mce.user_id
                  AND p.starts_at <= LAST_DAY(CONCAT(mce.month, '-01'))
                  AND (p.ends_at >= CONCAT(mce.month, '-01') OR p.ends_at IS NULL)
                  AND (p.canceled_at IS NULL OR p.canceled_at > LAST_DAY(CONCAT(mce.month, '-01')))
            ) THEN 'Premium'
            ELSE 'Free'
        END AS premium_status
    FROM monthly_clip_engagement mce
)
SELECT
    mce.month,
    us.premium_status,
    COUNT(DISTINCT mce.user_id) AS total_users,
    SUM(mce.total_clip_engagement) AS total_engagements,
    AVG(mce.total_clip_engagement) AS avg_engagement_per_user
FROM monthly_clip_engagement mce
JOIN user_status us
    ON mce.user_id = us.user_id
   AND mce.month = us.month
GROUP BY mce.month, us.premium_status
ORDER BY mce.month, us.premium_status;

-- 2. GAME PERFORMANCE SUMMARY
-- Joins: gamesession + clips + premium
-- Purpose: Summarize game-level user activity and engagement
SELECT
    g.game_name,
    COUNT(DISTINCT g.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS clip_creators,
    COUNT(DISTINCT p.user_id) AS premium_users,
    ROUND(AVG(g.duration) / 60000, 2) AS avg_session_minutes, 
    ROUND(
        COUNT(DISTINCT c.user_id) * 100.0 /
        NULLIF(COUNT(DISTINCT g.user_id), 0),
        2
    ) AS clip_creation_rate,
    ROUND(
        COUNT(DISTINCT p.user_id) * 100.0 /
        NULLIF(COUNT(DISTINCT g.user_id), 0),
        2
    ) AS premium_conversion_rate
FROM gamesession g
LEFT JOIN clips c 
    ON g.id = c.gamesession_id
LEFT JOIN premium p 
    ON g.user_id = p.user_id
WHERE g.submited_date BETWEEN '2023-05-01' AND '2023-12-31'
GROUP BY g.game_name
ORDER BY total_users DESC;

-- 3. CLIP PERFORMANCE ACROSS ALL USER ACTIONS
-- Joins: clips + downloaded_clips + shared_clips + gamesession
-- Purpose: Analyze clip performance and user engagement patterns
SELECT 
    c.clip_type_id,
    CASE 
        WHEN c.clip_type_id = 1 THEN 'Horizontal AI Highlight'
        WHEN c.clip_type_id = 2 THEN 'TikTok Converted'
        WHEN c.clip_type_id = 3 THEN 'Trimmed Clips'
        WHEN c.clip_type_id = 5 THEN 'Eventful Highlights'
        WHEN c.clip_type_id = 6 THEN 'Weekly Montage'
        WHEN c.clip_type_id = 7 THEN 'Local Upload'
        WHEN c.clip_type_id = 8 THEN 'YouTube Vertical'
        ELSE 'Other'
    END as clip_type_name,
    c.game_name,
    COUNT(c.id) as total_clips,
    COUNT(DISTINCT dc.clip_id) as downloaded_clips,
    COUNT(DISTINCT sc.clip_id) as shared_clips,
    AVG(c.duration) as avg_clip_duration_seconds,
    ROUND(COUNT(DISTINCT dc.clip_id) * 100.0 / COUNT(c.id), 2) as download_rate,
    ROUND(COUNT(DISTINCT sc.clip_id) * 100.0 / COUNT(c.id), 2) as share_rate
FROM clips c
LEFT JOIN downloaded_clips dc ON c.id = dc.clip_id
LEFT JOIN shared_clips sc ON c.id = sc.clip_id
LEFT JOIN gamesession g ON c.gamesession_id = g.id
WHERE c.created_at >= '2023-05-01' AND c.created_at <= '2023-12-31'
GROUP BY c.clip_type_id, c.game_name
HAVING total_clips >= 10
ORDER BY download_rate DESC, share_rate DESC;

-- 4. PREMIUM REVENUE AND CHURN ANALYSIS
-- Joins: premium + gamesession + clips + downloaded_clips
-- Purpose: Analyze premium user behavior and revenue metrics
SELECT 
    DATE_FORMAT(p.starts_at, '%Y-%m') as month,
    COUNT(p.user_id) as new_premium_users,
    COUNT(CASE WHEN p.canceled_at IS NULL THEN 1 END) as active_premium,
    COUNT(CASE WHEN p.canceled_at IS NOT NULL THEN 1 END) as canceled_premium,
    AVG(DATEDIFF(COALESCE(p.ends_at, '2023-12-31'), p.starts_at)) as avg_subscription_days,
    COUNT(DISTINCT g.user_id) as premium_users_with_sessions,
    COUNT(DISTINCT c.user_id) as premium_users_with_clips,
    COUNT(DISTINCT dc.user_id) as premium_users_downloading,
    AVG(total_clips.clip_count) as avg_clips_per_premium_user,
    ROUND(COUNT(CASE WHEN p.canceled_at IS NOT NULL THEN 1 END) * 100.0 / COUNT(p.user_id), 2) as cancellation_rate
FROM premium p
LEFT JOIN gamesession g ON p.user_id = g.user_id 
    AND g.submited_date BETWEEN p.starts_at AND COALESCE(p.ends_at, '2023-12-31')
LEFT JOIN clips c ON p.user_id = c.user_id 
    AND c.created_at BETWEEN p.starts_at AND COALESCE(p.ends_at, '2023-12-31')
LEFT JOIN downloaded_clips dc ON p.user_id = dc.user_id 
    AND dc.created_at BETWEEN p.starts_at AND COALESCE(p.ends_at, '2023-12-31')
LEFT JOIN (
    SELECT user_id, COUNT(*) as clip_count 
    FROM clips 
    GROUP BY user_id
) total_clips ON p.user_id = total_clips.user_id
WHERE p.starts_at >= '2023-05-01' AND p.starts_at <= '2023-12-31'
GROUP BY DATE_FORMAT(p.starts_at, '%Y-%m')
ORDER BY month DESC;

-- 5. MONITORING QUERIES FOR ALERTS
-- Joins: clips + downloaded_clips 
-- Purpose: ALERT QUERY: Detect declining download rates
SELECT 
    'Download Rate Alert' as alert_type,
    DATE(c.created_at) as date,
    COUNT(c.id) as clips_created,
    COUNT(DISTINCT dc.clip_id) as clips_downloaded,
    ROUND(COUNT(DISTINCT dc.clip_id) * 100.0 / COUNT(c.id), 2) as download_rate
FROM clips c
LEFT JOIN downloaded_clips dc ON c.id = dc.clip_id
WHERE c.created_at >= '2023-05-01' AND c.created_at <= '2023-12-31'
GROUP BY DATE(c.created_at)
HAVING download_rate < 30.0  -- Alert if download rate drops below 30%
ORDER BY date DESC;


