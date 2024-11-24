/* ============================= */
/*         Data Cleaning        */
/* ============================= */

/* 1. What is the total number of rows and unique employees? */
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT employee_id) AS unique_employees
FROM dbo.employee_performance;

/* 2. How can we identify duplicate records? */
SELECT *
FROM dbo.employee_performance
WHERE employee_id IN (
    SELECT employee_id
    FROM dbo.employee_performance
    GROUP BY employee_id
    HAVING COUNT(*) > 1
)
ORDER BY employee_id;

/* 3. Create a back-up file to remove duplicate and error row */
SELECT *
INTO dbo.employee_performance_backup
FROM dbo.employee_performance;

SELECT DISTINCT *
INTO dbo.employee_performance_staging
FROM dbo.employee_performance;

DELETE FROM dbo.employee_performance_staging
WHERE employee_id = 64573;

SELECT COUNT(*) AS total_records
FROM dbo.employee_performance_staging;

DELETE FROM dbo.employee_performance; 
INSERT INTO dbo.employee_performance
SELECT *
FROM dbo.employee_performance_staging;

DROP TABLE dbo.employee_performance_staging;

/* ============================= */
/*    Employee Overview          */
/* ============================= */

/* 4. What is the employee distribution across departments? */
SELECT department, 
       COUNT(employee_id) AS total_emp, 
       SUM(COUNT(employee_id)) OVER () AS total_emp_comp, 
       ROUND(CAST(COUNT(employee_id) AS FLOAT) / SUM(COUNT(employee_id)) OVER (), 2) AS percentage
FROM dbo.employee_performance
GROUP BY department
ORDER BY total_emp;

/* 5. How is gender distributed across departments? */
SELECT department, 
       COUNT(employee_id) AS total_employee, 
       COUNT(CASE WHEN gender='m' THEN 1 END) AS male_count, 
       COUNT(CASE WHEN gender='f' THEN 1 END) AS female_count, 
       ROUND(CAST(COUNT(CASE WHEN gender='m' THEN 1 END) AS FLOAT) / COUNT(employee_id), 2) AS male_ratio, 
       ROUND(CAST(COUNT(CASE WHEN gender='f' THEN 1 END) AS FLOAT) / COUNT(employee_id), 2) AS female_ratio
FROM dbo.employee_performance
GROUP BY department;

/* 6. What is the average age of employees in each department? */
SELECT department, 
       MIN(age) AS min_age, 
       MAX(age) AS max_age, 
       AVG(age) AS average_age
FROM dbo.employee_performance
GROUP BY department;

/* ============================= */
/*         KPIs Analysis         */
/* ============================= */

/* 7. What is the correlation between KPIs met (>80%) and awards won? */
SELECT KPIs_met_more_than_80, 
       SUM(awards_won) AS num_awards
FROM dbo.employee_performance
GROUP BY KPIs_met_more_than_80;

/* 8. How do KPI performances and awards differ by department? */
SELECT department, 
       COUNT(employee_id) AS num_emp, 
       SUM(KPIs_met_more_than_80) AS num_over_80, 
       SUM(awards_won) AS awards_won, 
       ROUND(CAST(SUM(KPIs_met_more_than_80) AS FLOAT) / COUNT(employee_id), 2) AS per_over_80, 
       ROUND(CAST(SUM(awards_won) AS FLOAT) / (SELECT SUM(awards_won) FROM dbo.employee_performance), 2) AS per_won
FROM dbo.employee_performance
GROUP BY department
ORDER BY per_over_80 DESC, per_won DESC;

/* 9. What is the impact of training on KPI performance? */
WITH train AS (
    SELECT no_of_trainings, 
           KPIs_met_more_than_80, 
           COUNT(*) AS numb_emp, 
           SUM(COUNT(*)) OVER(PARTITION BY no_of_trainings) AS total
    FROM dbo.employee_performance
    GROUP BY no_of_trainings, KPIs_met_more_than_80
)
SELECT no_of_trainings, 
       KPIs_met_more_than_80, 
       numb_emp, 
       ROUND(CAST(numb_emp AS FLOAT) / total, 2) AS per_over_80
FROM train;

/* 10. How does length of service correlate with KPI performance? */
SELECT length_of_service, 
       COUNT(employee_id) AS emp, 
       SUM(KPIs_met_more_than_80) AS kpi_over_80, 
       ROUND(CAST(SUM(KPIs_met_more_than_80) AS FLOAT) / COUNT(employee_id), 2) AS perc
FROM dbo.employee_performance
GROUP BY length_of_service
ORDER BY length_of_service, perc DESC;

/* 11. How does age affect KPI and awards performance? */
SELECT age, 
       COUNT(employee_id) AS emp, 
       SUM(KPIs_met_more_than_80) AS kpi_over_80, 
       ROUND(CAST(SUM(KPIs_met_more_than_80) AS FLOAT) / (SELECT SUM(KPIs_met_more_than_80) FROM dbo.employee_performance), 2) AS per
FROM dbo.employee_performance
GROUP BY age
ORDER BY per DESC;

/* 12. What is the relationship between education and KPI achievement? */
SELECT COALESCE(education, 'Unknown') AS education, 
       SUM(KPIs_met_more_than_80) AS num_emp, 
       SUM(SUM(KPIs_met_more_than_80)) OVER () AS tot_emp, 
       CAST(SUM(awards_won) AS FLOAT) / SUM(SUM(awards_won)) OVER () AS award_ratio, 
       CAST(SUM(KPIs_met_more_than_80) AS FLOAT) / SUM(SUM(KPIs_met_more_than_80)) OVER () AS ratio
FROM dbo.employee_performance
GROUP BY education
ORDER BY ratio DESC;

/* ============================= */
/*      Company Ratings          */
/* ============================= */

/* 13. How did employees rate the company last year? */
SELECT previous_year_rating, 
       COUNT(*) AS total_emp, 
       ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM dbo.employee_performance), 2) AS per_emp, 
       (SELECT ROUND(AVG(CAST(previous_year_rating AS FLOAT)), 2) FROM dbo.employee_performance) AS avg_rating
FROM dbo.employee_performance
GROUP BY previous_year_rating;

/* 14. How do gender and department correlate with ratings? */
SELECT CASE WHEN gender='f' THEN 'Female' 
            WHEN gender='m' THEN 'Male' END AS gender, 
       ROUND(AVG(CAST(previous_year_rating AS FLOAT)), 2) AS avg_rating
FROM dbo.employee_performance
GROUP BY gender;

/* 15. What is the rating distribution of each department? */
SELECT department, 
       ROUND(AVG(CAST(previous_year_rating AS FLOAT)), 2) AS avg_rating
FROM dbo.employee_performance
GROUP BY department;

/* 16. How does education correlate with ratings? */
WITH cte AS (
    SELECT department, gender, 
           AVG(CAST(previous_year_rating AS FLOAT)) AS avg_rating, 
           COUNT(previous_year_rating) AS num_emp
    FROM dbo.employee_performance
    WHERE previous_year_rating <= 2 AND previous_year_rating IS NOT NULL
    GROUP BY department, gender
)
SELECT *, 
       SUM(num_emp) OVER (PARTITION BY department) AS total_emp, 
       CAST(num_emp AS FLOAT) / SUM(num_emp) OVER () AS perc
FROM cte
ORDER BY total_emp DESC;

/* 17. What is the relationship between education level and ratings? */
SELECT COALESCE(education, 'Unknown') AS education, 
       ROUND(AVG(CAST(previous_year_rating AS FLOAT)), 2) AS avg_rating
FROM dbo.employee_performance
GROUP BY education;

/* ============================= */
/*     Company Recruitment       */
/* ============================= */

/* 18. How many employees were hired through different recruitment channels? */
SELECT recruitment_channel, 
       COUNT(recruitment_channel) AS num_emp, 
       CAST(COUNT(recruitment_channel) AS FLOAT) / (SELECT COUNT(*) FROM dbo.employee_performance) AS perc
FROM dbo.employee_performance
GROUP BY recruitment_channel
ORDER BY num_emp DESC;

/* 19. What is the education distribution from different hiring sources? */
SELECT recruitment_channel, education, 
       COUNT(*) AS num_emp
FROM dbo.employee_performance
GROUP BY recruitment_channel, education
ORDER BY num_emp DESC;

/* ============================= */
/*          KEY FINDINGS         */
/* ============================= */

/* 

**1. Employee Diversity:**
   - **Workforce Distribution:** The company has a total of 17,417 employees across 9 departments, with the largest share (31%) working in Sales and Marketing.
   - **Gender Imbalance:** Males dominate in most departments, while females are more concentrated in Procurement, HR, and Operations.
   - **Age Diversity:** The company has a wide range of age groups, with employees ranging from 20 to 60 years old, reflecting strong demographic diversity across departments.

**2. KPI Performance:**
   - **Overall KPI Achievement:** Only 36% of employees consistently meet KPIs above 80%, indicating a gap in performance expectations across the workforce.
   - **R&D Performance vs. Rewards:** Despite having the highest KPI achievement rate at 45%, R&D receives only 1% of the company’s total awards, suggesting a disconnect between KPI performance and recognition.
   - **Impact of Training on Performance:** Over 40% of employees achieve their KPIs during their first training session, and this number increases with additional training, highlighting the importance of continued development for KPI success.
   - **Age and KPI Achievement:** Employees in the 27-37 age range perform better than other age groups, achieving or exceeding their KPI targets more consistently.
   - **Education and KPI Performance:** Bachelor's degree holders outperform others, achieving 65% of their KPI targets, while master's degree holders only meet 29%. This indicates that the level of education may influence KPI success rates.

**3. Employee Ratings:**
   - **Overall Satisfaction:** The company’s average employee rating was 3.35 last year. The lowest ratings (1-2 stars) were primarily from the Sales and Marketing department, where 18% of employees gave low scores, pointing to potential dissatisfaction in that area.

**4. Recruitment Channels:**
   - **Balanced Education Levels:** Education levels are fairly consistent across the different recruitment channels for each department.
   - **Recruitment Source:** The majority of new hires come through online resources, while a very small percentage (1.8%) are recruited through referrals, suggesting an opportunity to increase referral-based recruitment and possibly leverage existing employees’ networks. 

*/
