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

/* 3. What steps are taken for data cleaning? */
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
Employee Diversity
- The company has 17,417 employees across 9 departments; Sales and Marketing account for 31% of the workforce.
- Males dominate each department, with females mainly in Procurement, HR, and Operations.
- Average age varies by department, indicating demographic diversity.
KPI Analysis
- Only 36% of employees meet KPIs above 80%.
- Employees who meet KPIs win more awards.
- R&D has the highest KPI rate at 45%, but only 1% of awards are given to this department.
- Training effectiveness varies on KPI achievement.
- Employees with 1-10 years of service achieve KPIs at 30%-40%.
- Employees aged 27-37 perform best on KPIs.
- Bachelor's degree holders achieve 65% KPI performance, while master's holders achieve only 29%.
Employee Ratings Last Year
- Average employee rating is 3.35; 18% rated low (1-2 stars), particularly in Sales and Marketing.
Recruitment Channels
- Over 50% of hires come from "other" channels; only 1.8% from referrals.
- Education levels are balanced across channels.
*/
