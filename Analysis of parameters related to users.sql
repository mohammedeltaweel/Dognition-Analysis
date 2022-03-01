-- The second route/path to analysis is discovering data related to users

-- 1.Does promotion make users complete more tests?
-- Answering this question will be pretty insightful about how the company should
-- manage its promotion strategy!

SELECT
    CASE
    WHEN is_start_free = 0 THEN 'Not Free Start'
    WHEN is_start_free = 1 THEN 'Free Start'
    END AS Free_start_classification,
    COUNT(c.created_at) AS num_test_completed,
    COUNT(c.created_at) / COUNT(DISTINCT c.dog_guid) AS Avg_test_completed
FROM
  complete_tests c INNER JOIN
    (SELECT DISTINCT d.dog_guid, u.free_start_user AS is_start_free
     FROM dogs d INNER JOIN users u
      ON d.user_guid = u.user_guid
     WHERE (u.exclude = 0 OR u.exclude IS NULL) AND
      (d.exclude = 0 OR d.exclude IS NULL)) AS tmp_tbl
      ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY is_start_free
ORDER BY 1
-- This query result is interesting. The subscribed users complete on average
-- 4 tests more than free start users, which is indication that company needs to
-- revise is free start policy!!


-- This result needs more emphasis, so let's discover the same question but about
-- subscribed users only
SELECT
    CASE
    WHEN subscribed = 0 THEN 'NOT SUBSCRIBED'
    WHEN subscribed = 1 THEN 'SUBSCRIBED'
    END AS Is_Subscribed,
    CASE
    WHEN is_start_free = 0 THEN 'Not Free Start'
    WHEN is_start_free = 1 THEN 'Free Start'
    END AS Free_start_classification,
    COUNT(c.created_at) AS num_test_completed,
    COUNT(c.created_at) / COUNT(DISTINCT c.dog_guid) AS Avg_test_completed
FROM
  complete_tests c INNER JOIN
    (SELECT DISTINCT
        d.dog_guid,
        u.free_start_user AS is_start_free,
        u.subscribed
     FROM dogs d INNER JOIN users u
      ON d.user_guid = u.user_guid
     WHERE (u.exclude = 0 OR u.exclude IS NULL) AND
      (d.exclude = 0 OR d.exclude IS NULL) AND u.subscribed =1) AS tmp_tbl
        ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY is_start_free, Is_Subscribed
ORDER BY 1

-- The same result as the previous query is repeated again but the difference is
-- only two tests on average. This is also good difference but it need further
-- investigation in promotion policy!!!

-- 2. Data related to users and thier relation with dogs.
--2.1 Do users that have more than one dog complete more tests?
SELECT
    user_id,
    max_dogs_no,
    COUNT(c.created_at) AS num_test_completed,
    COUNT(c.created_at) / max_dogs_no AS Num_test_per_dog
FROM complete_tests c INNER JOIN
  (SELECT DISTINCT u.user_guid AS user_id, d.dog_guid, u.max_dogs AS max_dogs_no
    FROM dogs d INNER JOIN users u
      ON d.user_guid = u.user_guid
      WHERE (u.exclude = 0 OR u.exclude IS NULL) AND
      (d.exclude = 0 OR d.exclude IS NULL) AND u.country = 'US') AS tmp_tbl
        ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY user_id
ORDER BY 2 DESC, 3
LIMIT 100;

-- After testing the first 20 row, it appers there is no relation between total
-- completed tests and number of dogs owned

--2.2 Are users who are more interested in dogs complete more tests?
-- In order to know if users are interested in dogs more than others I'll user dna_tested
-- column from dogs table to guess. I'm assuming that users who tested thier dogs
-- are more interesed in dogs more than other users.
SELECT
    CASE
    WHEN DNA = 0 THEN 'Dna Tested'
    WHEN DNA = 1 THEN 'Not DNA Tested'
    END AS Is_Dna_Tested,
    COUNT(c.created_at) AS num_test_completed,
    COUNT(c.created_at) / COUNT(DISTINCT c.dog_guid) AS Avg_test_completed
FROM complete_tests c INNER JOIN
  (SELECT DISTINCT u.user_guid AS user_id, d.dog_guid, d.dna_tested AS DNA
   FROM dogs d INNER JOIN users u
    ON d.user_guid = u.user_guid
   WHERE (u.exclude = 0 OR u.exclude IS NULL) AND
   (d.exclude = 0 OR d.exclude IS NULL) AND d.dna_tested IS NOT NULL) AS tmp_tbl
    ON c.dog_guid = tmp_tbl.dog_guid
GROUP BY DNA;

-- The difference on Average is less than one test completed, so this hypothesis
-- might not be effective.
