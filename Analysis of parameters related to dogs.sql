-- First  route in analysis: Data related to dogs

-- 1.Do dogs with different breeds or breed groups complete more tests?

--1.1 Effect of breed group on completion of tests.

SELECT DISTINCT breed_group
FROM dogs
-- There are 8 different breed groups and there are NULL values
-- Exploring these NULL valuse first before getting insights is better

SELECT
    d.dog_guid AS DogID,
    d.breed_group AS Breed_group,
    d.breed AS Breed,
    d.weight AS Weight,
    d.exclude AS Exclude,
    MIN(c.created_at) AS First_test_time,
    MAX(c.created_at) AS Last_test_time,
    COUNT(c.created_at) AS Num_tests
FROM dogs d INNER JOIN complete_tests c
    ON d.dog_guid = c.dog_guid
WHERE breed_group IS NULL
GROUP BY d.dog_guid
-- From above query there is no one feature that can descibe these NULL values
-- So, lets complete the analysis and see
SELECT
    tmp_tble.breed_group AS Breed_group,
    AVG(tmp_tble.num_tests_completed) AS Avg_tests_completed,
    COUNT(DISTINCT dog_guid) AS Num_dogs,
    tmp_tble.num_tests_completed AS Num_tests_completed
FROM(
    SELECT
        d.dog_guid,
        d.breed_group,
        count(c.created_at) as num_tests_completed
    FROM dogs d INNER JOIN complete_tests c
    ON d.dog_guid = c.dog_guid
    WHERE d.exclude IS NULL OR d.exclude = 0
    GROUP BY d.dog_guid) AS tmp_tble
GROUP BY Breed_group
ORDER BY Avg_tests_completed DESC

-- First look at the results, it appears that 'Terrier' and 'Toy' breeds complete
-- least number of tests, on the other hand, 'Herding', 'Sporting', and 'Working'
-- completed more tests on average
SELECT
    tmp_tble.breed_group AS Breed_group,
    AVG(tmp_tble.num_tests_completed) AS Avg_tests_completed,
    COUNT(DISTINCT dog_guid) AS Num_dogs
FROM(
    SELECT
        d.dog_guid,
        d.breed_group,
        count(c.created_at) as num_tests_completed
    FROM dogs d INNER JOIN complete_tests c
    ON d.dog_guid = c.dog_guid
    WHERE (d.exclude IS NULL OR d.exclude = 0) AND
      breed_group IN ('Sporting', 'Hound', 'Herding', 'Working')
    GROUP BY d.dog_guid) AS tmp_tble
GROUP BY Breed_group
ORDER BY Avg_tests_completed DESC
-- At first look, it might be reasonable to target these breed groups more than
-- others in emails, notifications, or advertisement campaign!!


--1.2 Effect of breed type on completion of tests.
-- Now, I'll discover difference in breed type completion rate.
SELECT DISTINCT breed_type AS 'Breed Type'
FROM dogs

-- There are four different breed types
-- How many tests on average each breed type completed?
SELECT
    tmp_tble.breed_type AS "Breed Type",
    AVG(tmp_tble.num_tests_completed) AS Avg_tests_completed,
    COUNT(DISTINCT dog_guid) AS num_dogs
FROM(
    SELECT
        d.dog_guid,
        d.breed_type,
        count(c.created_at) as num_tests_completed
    FROM dogs d INNER JOIN complete_tests c
    ON d.dog_guid = c.dog_guid
    WHERE d.exclude IS NULL OR d.exclude = 0
    GROUP BY d.dog_guid) AS tmp_tble
GROUP BY tmp_tble.breed_type
ORDER BY Avg_tests_completed

-- A look to results, there is no significant difference in average tests complteted
-- by each breed type. It is not a good idea to targer certain breed type
-- But lets discover if I divided breed from purity stand point where if breed
-- type is pure so it is 'Pure breed', otherwise it is 'Not pure breed'

%%sql
SELECT
    tmp_tble.breed_type AS Breed_Type,
    AVG(tmp_tble.num_tests_completed) AS Avg_tests_completed,
    COUNT(DISTINCT dog_guid) AS num_dogs,
    CASE
        WHEN breed_type = 'Pure Breed' THEN 'Pure Breed'
        WHEN breed_type != 'Pure Breed' THEN 'Not Pure Breed'
    END AS Is_pure_breed,
    tmp_tble.num_tests_completed AS Num_Tests_Completed
FROM(
    SELECT
        d.dog_guid,
        d.breed_type,
        d.dog_fixed,
        count(c.created_at) as num_tests_completed
    FROM dogs d INNER JOIN complete_tests c
    ON d.dog_guid = c.dog_guid
    WHERE d.exclude IS NULL OR d.exclude = 0
    GROUP BY d.dog_guid) AS tmp_tble
GROUP BY Is_pure_breed
ORDER BY Is_pure_breed

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

-- 3. Is neutered dogs complete more tests than non neutered?
-- The variable dog_fixed represents whether dog is neutered or not
-- 0 means not neutered, 1 means neutered
SELECT
  dog_fixed
FROM dogs
-- The results aren't helpful, let's use CASE to group
SELECT
  CASE
    WHEN dog_fixed = 0 THEN 'Not Neutered'
    WHEN dog_fixed = 1 THEN 'Neutered'
  END AS Is_neutered

-- using the latter query to classify and compare average number of tests completed


SELECT
    AVG(tmp_tble.num_tests_completed) AS Avg_tests_completed,
    CASE
        WHEN tmp_tble.dog_fixed = 0 THEN 'Not Neutered'
        WHEN tmp_tble.dog_fixed = 1 THEN 'Neutered'
    END AS Is_neutered,
    COUNT(DISTINCT dog_guid) AS num_dogs,
    tmp_tble.num_tests_completed AS Num_Tests_Completed
FROM(
    SELECT
        d.dog_guid,
        d.dog_fixed,
        count(c.created_at) as num_tests_completed
    FROM dogs d INNER JOIN complete_tests c
    ON d.dog_guid = c.dog_guid
    WHERE d.exclude IS NULL OR d.exclude = 0
    GROUP BY d.dog_guid) AS tmp_tble
GROUP BY Is_neutered
ORDER BY Is_neutered
-- The results suggests that Neutered dogs on average complete more tests than
-- Not Neutered dogs, but before jumping to conclusion more analysis by combining
-- neuterity and breed purity

SELECT
    tmp_tble.breed_type AS Breed_Type,
    AVG(tmp_tble.num_tests_completed) AS Avg_tests_completed,
    CASE
        WHEN tmp_tble.dog_fixed = 0 THEN 'Not Neutered'
        WHEN tmp_tble.dog_fixed = 1 THEN 'Neutered'
    END AS Is_neutered,
    COUNT(DISTINCT dog_guid) AS num_dogs,
    CASE
        WHEN breed_type = 'Pure Breed' THEN 'Pure Breed'
        WHEN breed_type != 'Pure Breed' THEN 'Not Pure Breed'
    END AS Is_pure_breed,
    tmp_tble.num_tests_completed AS Num_Tests_Completed
FROM(
    SELECT
        d.dog_guid,
        d.breed_type,
        d.dog_fixed,
        count(c.created_at) as num_tests_completed
    FROM dogs d INNER JOIN complete_tests c
    ON d.dog_guid = c.dog_guid
    WHERE d.exclude IS NULL OR d.exclude = 0
    GROUP BY d.dog_guid) AS tmp_tble
GROUP BY Is_pure_breed, Is_neutered
ORDER BY Is_neutered, Is_pure_breed

-- Again, the same results!!
-- It may be evident that neutered dogs complete more tests than non neutered ones!
-- Furthur exploration will be done but in the second path of analysis where
-- I explore relation between data related to users and number of tests complteted


-- 4. Does completion time affect average number of tests completed??
SELECT
    d.breed_type AS "Breed Type",
    AVG(TIMESTAMPDIFF(minute, e.start_time, e.end_time)) AS Avg_Completion_time,
    COUNT(c.created_at)/Count(DISTINCT d.dog_guid) AS Avg_tests
FROM dogs d INNER JOIN exam_answers e
ON d.dog_guid = e.dog_guid INNER JOIN complete_tests c
    ON e.dog_guid = c.dog_guid
WHERE TIMESTAMPDIFF(minute, e.start_time, e.end_time) > 0
GROUP BY d.breed_type

-- The results show that completion time has no effect on average number of tests
-- completed
-- But the values seems not logical, so let's explore further
SELECT d.breed_type AS breed_type,
  AVG(TIMESTAMPDIFF(minute,e.start_time,e.end_time)) AS AvgDuration,
  STDDEV(TIMESTAMPDIFF(minute,e.start_time,e.end_time)) AS StdDevDuration
FROM dogs d JOIN exam_answers e
  ON d.dog_guid=e.dog_guid
WHERE TIMESTAMPDIFF(minute,e.start_time,e.end_time)>0.
GROUP BY breed_type;
-- The standard deviation for average duration is very high, the values of the
-- columns contain outliers. It is good practice to use median insted of average
-- to get better results, but I'll do this in Tableau because it is easier and
-- more practical to get the median in it rather than SQL
