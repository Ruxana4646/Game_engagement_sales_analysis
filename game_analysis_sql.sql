CREATE DATABASE games_db_clean;
USE games_db_clean;

CREATE TABLE games_backup AS
SELECT * FROM games;


ALTER TABLE games ENGINE = InnoDB;
ALTER TABLE sales ENGINE = InnoDB;

ALTER TABLE games
ADD COLUMN games_id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE sales
ADD COLUMN game_id INT;

ALTER TABLE sales
ADD COLUMN sales_id INT AUTO_INCREMENT PRIMARY KEY;

UPDATE games
SET Title = TRIM(LOWER(Title));

UPDATE sales
SET Title = TRIM(LOWER(Title));

UPDATE sales s
JOIN games g
  ON s.Title = g.Title
SET s.game_id = g.games_id;

SELECT COUNT(*) AS unmatched_sales
FROM sales
WHERE game_id IS NULL;

DELETE FROM sales
WHERE game_id IS NULL;

ALTER TABLE sales
MODIFY game_id INT NOT NULL;

ALTER TABLE sales
ADD INDEX idx_sales_game_id (game_id);

ALTER TABLE sales
ADD CONSTRAINT fk_sales_games
FOREIGN KEY (game_id)
REFERENCES games(games_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

select * from sales;

select 
    SUM(title IS NULL) AS title_nulls,
    SUM('Release Date' IS NULL) AS date_nulls,
    SUM(Team IS NULL) AS Team_nulls,
    SUM(Rating IS NULL) AS Rating_nulls,
    SUM('Times Listed' IS NULL) AS Times_Listed_nulls,
    SUM('Number of Reviews' IS NULL) AS Reviews_nulls,
    SUM(Genres IS NULL) AS Genres_nulls,
    SUM(Summary IS NULL) AS Summary_nulls,
    SUM(Reviews IS NULL) AS Reviews_nulls,
    SUM(Wishlist IS NULL) AS Wishlist_nulls,
    SUM(Plays IS NULL) AS Plays_nulls,
    SUM(Playing IS NULL) AS Playing_nulls,
    SUM(Backlogs IS NULL) AS Backlogs_nulls
FROM games;

update games 
set Summary ='unknown'
where Summary is null or Summary ='';

CREATE TABLE games_dashboard_agg AS
SELECT 
    g.games_id,
    g.Title,
    g.Genres,
    g.Rating,
    g.`Release Date`,
    SUM(s.NA_Sales) AS NA_Sales,
    SUM(s.EU_Sales) AS EU_Sales,
    SUM(s.JP_Sales) AS JP_Sales,
    SUM(s.Other_Sales) AS Other_Sales,
    SUM(s.Global_Sales) AS Global_Sales
FROM games g
LEFT JOIN sales s
    ON g.games_id = s.game_id
GROUP BY g.games_id, g.Title, g.Genres, g.Rating, g.`Release Date`;

select * from games_dashboard_agg;

# Top 10 Rated game?
SELECT 
    Title,
    Genres,
    Rating,
    `Release Date`
FROM games
ORDER BY Rating DESC
LIMIT 10;

#Most common Generes
SELECT 
    Genres,
    COUNT(*) AS num_games
FROM games
GROUP BY Genres
ORDER BY num_games DESC;

# highest backlog compared to wishlist
SELECT 
    Title,
    Backlogs,
    Wishlist,
    (Backlogs - Wishlist) AS backlog_minus_wishlist,
    ROUND((Backlogs  / NULLIF(Wishlist,0)),2) AS backlog_to_wishlist_ratio
FROM games
ORDER BY backlog_minus_wishlist DESC
LIMIT 10;

# Game released Accross Year
SELECT 
    YEAR(`Release Date`) AS release_year,
    COUNT(*) AS num_games_released
FROM games
GROUP BY release_year
ORDER BY release_year;

# Top wishlisted
SELECT 
    Title,
    Genres,
    wishlist
FROM games
ORDER BY wishlist DESC
LIMIT 10;

# distribution of user Rating
SELECT 
    Rating,
    COUNT(*) AS num_games
FROM games
GROUP BY Rating
ORDER BY Rating DESC;

# top 10 best selling
SELECT 
    g.Title,
    g.Genres,
    SUM(s.Global_Sales) AS total_global_sales
FROM sales s
JOIN games g ON g.games_id = s.game_id
GROUP BY g.games_id, g.Title, g.Genres
ORDER BY total_global_sales DESC
LIMIT 10;

#Regional sales
SELECT 
    s.Platform,
    SUM(s.NA_Sales) AS NA_Sales,
    SUM(s.EU_Sales) AS EU_Sales,
    SUM(s.JP_Sales) AS JP_Sales,
    SUM(s.Other_Sales) AS Other_Sales
FROM sales s
GROUP BY s.Platform
ORDER BY s.Platform;

#market Evolution by platform over time
SELECT 
    CAST(SUBSTRING(g.`Release Date`, 1, 4) AS UNSIGNED) AS release_year,
    s.Platform,
    SUM(s.Global_Sales) AS total_sales
FROM sales s
JOIN games g ON g.games_id = s.game_id
GROUP BY release_year, s.Platform
ORDER BY release_year, s.Platform;

# User Engagement by Genre
SELECT 
    g.Genres,
    AVG(g.plays) AS avg_plays,
    AVG(g.playing) AS avg_playing,
    AVG(g.wishlist) AS avg_wishlist,
    AVG(g.backlogs) AS avg_backlogs
FROM games g
JOIN sales s ON g.games_id = s.game_id
GROUP BY g.Genres
ORDER BY avg_plays DESC;

# Top performing Generes and Platform Combination
SELECT 
    g.Genres,
    s.Platform,
    SUM(s.Global_Sales) AS total_sales,
    AVG(g.plays) AS avg_plays,
    AVG(g.playing) AS avg_playing,
    AVG(g.wishlist) AS avg_wishlist,
    AVG(g.backlogs) AS avg_backlogs
FROM sales s
JOIN games g ON g.games_id = s.game_id
GROUP BY g.Genres, s.Platform
ORDER BY total_sales DESC
LIMIT 10;

