/* ============================= */
/*         Data Cleaning        */
/* ============================= */

-- DATA PROFILING
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT employee_id) AS unique_employees
FROM dbo.employee_performance;

/* 
The dataset contains 17,417 rows with 17,414 unique employees.
*/

-- Identifying duplicate records

SELECT *
FROM dbo.employee_performance
WHERE employee_id IN (
    SELECT employee_id
    FROM dbo.employee_performance
    GROUP BY employee_id
    HAVING COUNT(*) > 1
)
ORDER BY employee_id;

/* 
There are 3 duplicate records for employee ID 49584 need removal, and 2 records for employee ID 64573 suggest there may be two distinct employees, indicating a possible data entry error. 
Due to project focus, I will remove the duplicates and continue with the analysis while noting potential issues from this error.
*/

-- DATA TRANSFORMATION
-- Step 1: Create a Backup of the Original Table to ensures we have the original data in case we need to revert changes.
SELECT *
INTO dbo.employee_performance_backup
FROM dbo.employee_performance;


-- Step 2: Create a Staging Table with distinct rows to help remove duplicates to isolate unique employee records for cleanup
SELECT DISTINCT *
INTO dbo.employee_performance_staging
FROM dbo.employee_performance;

-- Step 3: Delete erroneous record for employee ID 64573 to ensure data accuracy from staging table 
DELETE FROM dbo.employee_performance_staging
WHERE employee_id = 64573;

-- Step 4: Review Changes 
SELECT COUNT(*) AS total_records
FROM dbo.employee_performance_staging;

/* Current total records is now 17,413 after dropping 4 rows (2 duplicates and 2 erroneous) */

-- Step 5: Update Main Table 

DELETE FROM dbo.employee_performance; -- Clear the original table

INSERT INTO dbo.employee_performance -- Insert corrected records from the staging table
SELECT *
FROM dbo.employee_performance_staging;

-- Step 6: Drop the Staging Table as no longer needed
DROP TABLE dbo.employee_performance_staging;

/*  Dropping the staging table as it's no longer needed after the cleanup process */

--> Now the data is ready for analysis. 

/* ============================= */
/*         Overview             */
/* ============================= */

-- Analyzing employee distribution across departments.

SELECT department, 
       COUNT(employee_id) AS total_emp, 
       SUM(COUNT(employee_id)) OVER () AS total_emp_comp, 
       ROUND(CAST(COUNT(employee_id) AS FLOAT) / SUM(COUNT(employee_id)) OVER (), 2) AS percentage
FROM dbo.employee_performance
GROUP BY department
ORDER BY total_emp;

/* The company has a total of 17,417 employees across 9 departments, with Sales and Marketing being the largest, accounting for approximately 31% of the workforce.*/
 
-- Examining gender distribution across different departments.

SELECT department, 
       COUNT(employee_id) AS total_employee, 
       COUNT(CASE WHEN gender='m' THEN 1 END) AS male_count, 
       COUNT(CASE WHEN gender='f' THEN 1 END) AS female_count, 
       ROUND(CAST(COUNT(CASE WHEN gender='m' THEN 1 END) AS FLOAT) / COUNT(employee_id), 2) AS male_ratio, 
       ROUND(CAST(COUNT(CASE WHEN gender='f' THEN 1 END) AS FLOAT) / COUNT(employee_id), 2) AS female_ratio
FROM dbo.employee_performance
GROUP BY department;

/* Male employees constitute more than 50% of the total workforce in each department. Female employees are predominantly found in Procurement, HR, and Operations, where they make up over 40% of the workforce in each department.*/

-- Calculating the average age of employees in each department.

SELECT department, 
       MIN(age) AS min_age, 
       MAX(age) AS max_age, 
       AVG(age) AS average_age
FROM dbo.employee_performance
GROUP BY department;

/* The average age varies by department, providing insights into the workforce demographics.*/

/* ============================= */
/*         KPIs Analysis         */
/* ============================= */

-- Reviewing data by department, gender, education, age, recruitment channel, length_of_service, previous_year_rating, no_training, avg_training_score, and region where employees work. */

-- Correlation between KPIs met (>80%) and awards won.

SELECT KPIs_met_more_than_80, 
       SUM(awards_won) AS num_awards
FROM dbo.employee_performance
GROUP BY KPIs_met_more_than_80;

/* Employees meeting more than 80% of their KPIs have higher chance of winning awards.*/

-- Analyzing KPI performance and awards won by department.

SELECT department, 
       COUNT(employee_id) AS num_emp, 
       SUM(KPIs_met_more_than_80) AS num_over_80, 
       SUM(awards_won) AS awards_won, 
       ROUND(CAST(SUM(KPIs_met_more_than_80) AS FLOAT) / COUNT(employee_id), 2) AS per_over_80, 
       ROUND(CAST(SUM(awards_won) AS FLOAT) / (SELECT SUM(awards_won) FROM dbo.employee_performance), 2) AS per_won
FROM dbo.employee_performance
GROUP BY department
ORDER BY per_over_80 DESC, per_won DESC;

/* The R&D department has the highest KPI achievement rate at 45%, but awards won are only 1% of the total. Sales & Marketing has the lowest KPI achievement but the highest awards won, indicating a disconnect between KPI achievement and awards.*/

-- Analyzing the impact of training on KPI performance.

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

/* Training sessions have varying impacts on KPI achievement, with certain sessions showing significant effectiveness.*/

-- Length of service and KPI performance analysis.

SELECT length_of_service, 
       COUNT(employee_id) AS emp, 
       SUM(KPIs_met_more_than_80) AS kpi_over_80, 
       ROUND(CAST(SUM(KPIs_met_more_than_80) AS FLOAT) / COUNT(employee_id), 2) AS perc
FROM dbo.employee_performance
GROUP BY length_of_service
ORDER BY length_of_service, perc DESC;

/*  Employees with 1 to 10 years of service achieve KPIs over 80% at rates between 30% and 40%, while performance declines after 10 years.*/

-- Age with KPI and awards analysis.

SELECT age, 
       COUNT(employee_id) AS emp, 
       SUM(KPIs_met_more_than_80) AS kpi_over_80, 
       ROUND(CAST(SUM(KPIs_met_more_than_80) AS FLOAT) / (SELECT SUM(KPIs_met_more_than_80) FROM dbo.employee_performance), 2) AS per
FROM dbo.employee_performance
GROUP BY age
ORDER BY per DESC;

/* Employees aged 27 to 37 show the best KPI performance, while younger and older employees struggle to achieve high KPIs. */

-- Education and KPI achievement analysis.

SELECT COALESCE(education, 'Unknown') AS education, 
       SUM(KPIs_met_more_than_80) AS num_emp, 
       SUM(SUM(KPIs_met_more_than_80)) OVER () AS tot_emp, 
       CAST(SUM(awards_won) AS FLOAT) / SUM(SUM(awards_won)) OVER () AS award_ratio, 
       CAST(SUM(KPIs_met_more_than_80) AS FLOAT) / SUM(SUM(KPIs_met_more_than_80)) OVER () AS ratio
FROM dbo.employee_performance
GROUP BY education
ORDER BY ratio DESC;

/* Employees with a bachelor's degree achieve the highest KPI performance, indicating a positive correlation between education level and performance.*/

/* ============================= */
/*      Company Ratings          */
/* ============================= */

-- Company ratings by employees
SELECT previous_year_rating, 
       COUNT(*) AS total_emp, 
       ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM dbo.employee_performance), 2) AS per_emp, 
       (SELECT ROUND(AVG(CAST(previous_year_rating AS FLOAT)), 2) FROM dbo.employee_performance) AS avg_rating
FROM dbo.employee_performance
GROUP BY previous_year_rating;

/*  Result shows that the average rating last year of the company was 3.35. The majority of employees rated fairly at 3 stars, while some rated higher. 
There was 18% expressing dissatisfaction with ratings of 1 and 2, highlighting the need to investigate departmental issues, management, and job satisfaction. */

-- How gender and department correlate with ratings. 

SELECT CASE WHEN gender='f' THEN 'Female' 
            WHEN gender='m' THEN 'Male' END AS gender, 
       ROUND(AVG(CAST(previous_year_rating AS FLOAT)), 2) AS avg_rating
FROM dbo.employee_performance
GROUP BY gender;

/* There is equal rating between female and male employees, indicating no bias in terms of ratings. */

-- Rating distribution of each department.

SELECT department, 
       ROUND(AVG(CAST(previous_year_rating AS FLOAT)), 2) AS avg_rating
FROM dbo.employee_performance
GROUP BY department;

/* The results indicate that the Sales and Marketing department received the lowest ratings from employees. */

-- Education correlation with the rating.
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

/* 
The analysis reveals that a significant portion of low ratings (1 and 2 stars) comes from the Sales and Marketing (S&M) department, with 36% attributed to dissatisfied male employees and 9% from female employees. Similarly, these groups represent 45% of the department's total ratings. 
To enhance overall employee satisfaction and improve the company's reputation, it is essential to focus on addressing the concerns of these groups. Conducting surveys and performing a thorough analysis of areas for improvement will be crucial for fostering a better workplace environment and promoting long-term sustainability.
*/

-- Rating correlateed with education level
SELECT COALESCE(education, 'Unknown') AS education, 
       ROUND(AVG(CAST(previous_year_rating AS FLOAT)), 2) AS avg_rating
FROM dbo.employee_performance
GROUP BY education;

/* Rating scores range from 3.1 to 3.63, with those below secondary education having the highest scores.  However, the "unknown" education category has the lowest scores, indicating a need for further investigation to understand the underlying reasons.*/

/* ============================= */
/*     Company Recruitment       */
/* ============================= */

SELECT recruitment_channel, 
       COUNT(recruitment_channel) AS num_emp, 
       CAST(COUNT(recruitment_channel) AS FLOAT) / (SELECT COUNT(*) FROM dbo.employee_performance) AS perc
FROM dbo.employee_performance
GROUP BY recruitment_channel
ORDER BY num_emp DESC;

/* Over half of employees were hired through various methods, with 42% sourced and only 1.8% via referrals. The company should enhance its employee referral program and optimize sourcing strategies to improve recruitment quality and diversify talent acquisition. */

-- Education from different channels. 
SELECT recruitment_channel, education, 
       COUNT(*) AS num_emp
FROM dbo.employee_performance
GROUP BY recruitment_channel, education
ORDER BY num_emp DESC;

/*It shows a balanced spread of education levels from different hiring sources,  indicating that there is no bias in how candidates are chosen.*/

/* ============================= */
/*          KEY FINDINGS         */
/* ============================= */

-- Males make up 91% of the workforce, highlighting a gender disparity, while the Sales and Marketing department has the largest employee count, indicating a need for targeted recruitment initiatives to attract female talent.

-- Only 36% of employees achieve KPIs above 80%, suggesting the necessity for enhanced performance management, while training programs have varying impacts on KPI achievement, emphasizing the importance of identifying effective training strategies.

-- Recruitment is primarily through "other" channels and direct sourcing, with referrals being minimal; this underscores the need to optimize recruitment processes and strengthen the employee referral program to improve overall hiring quality.
