-- First point of view: Data related to dogs
-- 1.Do dogs with different breeds or breed groups complete more tests?

-- Effect of breed group on completion of tests?


-- 2. Is there any dimesnion affect test completion rate?

SELECT DISTINCT dimension AS Dog_dimension
FROM dogs

-- The results show 11 different dimensions including None value which in NULL

SELECT DISTINCT
  d.dog_guid AS DogID,
  d.dimension AS Dog_dimension,
  count(c.created_at) AS Num_tests_completed
FROM dogs d INNER JOIN complete_tests c
ON d.dog_guid = c.dog_guid
GROUP BY d.dog_guid
ORDER BY Num_tests_completed DESC

-- The last query shows every unique dog id completed tests but not a summary
-- for all tests related to each dog dimension. HINT: I'll use trmp tables to
-- get the average of tests number

SELECT
  tmp_tble.dimension AS Dog_dimension,
  AVG(tmp_tble.num_test) As Avg_tests_completed
FROM(
SELECT DISTINCT d.dog_guid, d.dimension, count(c.created_at) as num_test
FROM dogs d INNER JOIN complete_tests c
ON d.dog_guid = c.dog_guid
GROUP BY d.dog_guid) AS tmp_tble
GROUP BY Dog_dimension
-- The results show that there is no difference between

-- From the results there are NULL values that completed on average 6.9 and
-- there is empty stings that completes 9.5 tests on average
-- so it needs to be discovered
SELECT
  dimension AS Dog_dimension,
  COUNT(DISTINCT dog_guid) As num_dogs
  FROM(
    SELECT  d.dog_guid , d.dimension, count(c.created_at) as num_test
    FROM dogs d INNER JOIN complete_tests c
      ON d.dog_guid = c.dog_guid
    WHERE d.dimension IS NULL OR d.dimension = ''
    GROUP BY d.dog_guid) AS tmp_tble
GROUP BY tmp_tble.dimension

-- The NULL values are no problem because the user has to complete 20 tests in
-- order to have dimension values, but the empty string needs to be invistigated
-- more

SELECT
    dimension,
    breed,
    weight,
    exclude,
    MIN(c.created_at) As First_test_time,
    MAX(c.created_at) AS Last_test_time,
    COUNT(c.created_at) AS Num_tests
FROM dogs d INNER JOIN complete_tests c
    ON d.dog_guid = c.dog_guid
WHERE d.dimension = ''
GROUP BY d.dog_guid

-- The last query shows that the exclude values are 1 for almost all the values
-- So, Dognition team decided to exclue these values which makes the first query
-- needs to exclude them

SELECT
    tmp_tble.dimension AS Dog_dimension,
    AVG(tmp_tble.num_tests_completed) AS Avg_tests_completed,
    COUNT(DISTINCT dog_guid) AS Num_dogs,
    tmp_tble.num_tests_completed AS Num_test_completed
FROM(
    SELECT
        d.dog_guid,
        d.dimension,
        count(c.created_at) as num_tests_completed
    FROM dogs d INNER JOIN complete_tests c
      ON d.dog_guid = c.dog_guid
    WHERE (d.dimension IS NOT NULL AND d.dimension != '')
      AND (d.exclude IS NULL OR d.exclude = 0)
    GROUP BY d.dog_guid) AS tmp_tble
GROUP BY Dog_dimension
ORDER BY Avg_tests_completed

-- The results show the same as first query, no dimension is different from
-- other, almost all of them complete 22 or 23 tests on average.
