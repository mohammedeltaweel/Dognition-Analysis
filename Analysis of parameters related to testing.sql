-- Final arc of analysis accorging to the plan
-- Do testing circumstances affect completion rate of tests?
-- The resulted insights from this analysis will be very effective in making
-- decision about what, where, and when to target our audience via Emails, notifications
-- or promotions.
--1. When do users complete more tests? which day of the week? at which hour?

SELECT
    DAYNAME(c.created_at) AS day_of_week,
    COUNT(c.created_at) AS num_test_completed
FROM complete_tests c INNER JOIN dogs d
    ON c.dog_guid = d.dog_guid
WHERE d.exclude <> 1 OR d.exclude IS NULL
GROUP BY day_of_week
ORDER BY num_test_completed DESC
-- As expected, most of dognition tests were taken on Sundays, while the lowest
-- number of tests were taken on Friday

-- Are these results replicated when joining tables together?
SELECT
    DAYNAME(c.created_at) AS day_of_week,
    COUNT(c.created_at) AS num_test_completed
FROM complete_tests c INNER JOIN
(
  SELECT DISTINCT
    d.dog_guid
  FROM dogs d INNER JOIN users u
      ON d.user_guid = u.user_guid
  WHERE (u.exclude = 0 OR u.exclude IS NULL) AND
  (d.exclude = 0 OR d.exclude IS NULL)
) AS tmp_tbl
  ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY day_of_week
ORDER BY num_test_completed DESC
-- The results are still the same, so it is more likely to be correct

-- Do these results replicate if we seperated each year of the given data?
%%sql
SELECT
    DAYNAME(c.created_at) AS day_of_week,
    YEAR(c.created_at) AS Year,
    COUNT(c.created_at) AS num_test_completed
FROM complete_tests c INNER JOIN
(
  SELECT DISTINCT d.dog_guid
  FROM dogs d INNER JOIN users u
      ON d.user_guid = u.user_guid
  WHERE (u.exclude = 0 OR u.exclude IS NULL)
   AND (d.exclude = 0 OR d.exclude IS NULL)
) AS tmp_tbl
  ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY day_of_week, Year
ORDER BY Year, num_test_completed DESC
-- Again, on years 2013, 2014, 2015 Sundays are top each year, Fridays are almost
-- always the bottom.
-- So, it may be good idea to send notifications/mails/promotions on Sundays

-- During which hour more tests were completed?
SELECT
    country,
    state,
    DATE_SUB(c.created_at, INTERVAL 6 HOUR) AS corrected_date,
    HOUR(DATE_SUB(c.created_at, INTERVAL 6 HOUR)) AS HOUR_OF_DAY,
    COUNT(c.created_at) AS num_test_completed
FROM complete_tests c INNER JOIN
(
  SELECT DISTINCT
    d.dog_guid,
    u.country,
    u.state
  FROM dogs d INNER JOIN users u
    ON d.user_guid = u.user_guid
  WHERE (u.exclude = 0 OR u.exclude IS NULL) AND
    (d.exclude = 0 OR d.exclude IS NULL) AND u.country = 'US'
    AND u.state <> 'HI' AND u.state <> 'AK') AS tmp_tbl
    ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY HOUR_OF_DAY
ORDER BY num_test_completed DESC

-- The most traffic hours of the day are 18, 19, 17 respectively.

-- Final conclusion about day and time:
-- Promotions and notifications should be done on Sundays and Mondays
-- from 5 to 7 P.M in the US time zone

-- Let's discover which country has more customers
SELECT country
	,COUNT(DISTINCT tmp_tbl.user_guid) AS number_of_customers
FROM complete_tests c
INNER JOIN (
	SELECT DISTINCT d.dog_guid
		,u.user_guid
		,u.country
	FROM dogs d
	INNER JOIN users u ON d.user_guid = u.user_guid
	WHERE (
			u.exclude = 0
			OR u.exclude IS NULL
			)
		AND (
			d.exclude = 0
			OR d.exclude IS NULL
			)
	) AS tmp_tbl ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY country
ORDER BY number_of_customers DESC

-- As it was expected, U.S has the largest amount of users, the next country has
-- more than all other coutries combined
SELECT CASE
		WHEN country = 'US'
			THEN 'United States'
		WHEN country = 'N/A'
			THEN 'Not Applicable'
		ELSE 'Other'
		END AS Country_classification
	,COUNT(DISTINCT tmp_tbl.user_guid) AS number_of_customers
FROM complete_tests c
INNER JOIN (
	SELECT DISTINCT d.dog_guid
		,u.user_guid
		,u.country
	FROM dogs d
	INNER JOIN users u ON d.user_guid = u.user_guid
	WHERE (
			u.exclude = 0
			OR u.exclude IS NULL
			)
		AND (
			d.exclude = 0
			OR d.exclude IS NULL
			)
	) AS tmp_tbl ON c.dog_guid = tmp_tbl.dog_guid
WHERE tmp_tbl.country IS NOT NULL
GROUP BY Country_classification
ORDER BY number_of_customers DESC
-- The US has nearly 9000 users, while other countries have approx. 1200 users,
-- while 5000 users have no country. So the company should target US users only

-- If dognition will target US users only, which state has more completion rate
-- than others?
SELECT country
	,STATE
	,COUNT(DISTINCT tmp_tbl.user_guid) AS number_of_customers
	,COUNT(c.created_at) / COUNT(DISTINCT tmp_tbl.dog_guid) AS Avg_num_tests
FROM complete_tests c
INNER JOIN (
	SELECT DISTINCT d.dog_guid
		,u.user_guid
		,u.country
		,u.STATE
	FROM dogs d
	INNER JOIN users u ON d.user_guid = u.user_guid
	WHERE (
			u.exclude = 0
			OR u.exclude IS NULL
			)
		AND (
			d.exclude = 0
			OR d.exclude IS NULL
			)
		AND u.country = 'US'
		AND u.STATE <> 'HI'
		AND u.STATE <> 'AK'
	) AS tmp_tbl ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY country
	,STATE
HAVING number_of_customers > 50
ORDER BY Avg_num_tests DESC LIMIT 10

-- For states that have more than 50 customers, average number of 
--tests completed is the same

-- Final conclustion about states and countries: 
-- First, US should be the main target for any cmpaigns targeting new users
-- or driving old users to complete more tests
-- Second, there is no state that should be targeted more than other stats.
