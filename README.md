# HR Employee Performance Analysis

## Overview

This project addresses three main areas: KPI performance, employee ratings, and recruitment channels. It offers insights and actionable recommendations to assist the HR department in identifying key challenges and developing strategies to enhance KPI performance, boost employee ratings, and optimize recruitment processes.

## Data Source

The data for this analysis is sourced from Kaggle: [Employee Performance Dataset](https://www.kaggle.com/datasets/sanjanchaudhari/employees-performance-for-hr-analytics).

## List of Business Problems

#### Employee Distribution by Gender, Department, Age

#### KPI Performance
1. What is the overall KPI achievement rate across the organization?
2. How do KPIs correlate with awards won by employees?
3. Which departments have the highest and lowest KPI performance?
4. What is the impact of training on KPI achievement?
5. How does the length of service affect KPI performance?
6. Which age groups achieve the highest KPIs?
7. How does education level relate to KPI performance?

#### Employee Ratings
8. What is the average employee rating within the company?
9. How do gender and department correlate with employee ratings?
10. Which department has the lowest average rating?
11. What percentage of low ratings (1 and 2 stars) come from specific departments?

#### Recruitment Channels
12. How many employees were hired through different recruitment channels?
13. What is the distribution of education levels across various recruitment sources? 

---

## Analysis Process

1. **Identify Business Problems:** Define key business challenges and objectives.
2. **Data Cleaning:** Profile the data to identify issues, then clean and transform the dataset for analysis.
3. **Data Analysis:** Analyze the data to address the identified problems and derive insights.
4. **Document Findings:** Record key findings and formulate actionable recommendations.

---

### Data cleaning 

- The dataset contained duplicates and entry errors. I created a backup table for future reference, then cleaned the data by removing duplicates and errors in a new staging table. This was transformed into the main table for analysis. 

--> The table was reduced from 17,417 rows to 17,413 by removing 2 duplicate rows and 2 entry errors for employee ID 64573.

---

## Key Findings

### Employee Overview
- The company has 17,417 employees across 9 departments; Sales and Marketing account for 31% of the workforce.
- Males dominate each department, with females mainly in Procurement, HR, and Operations.
- Average age varies by department, indicating demographic diversity.

### KPI Analysis
- Only 36% of employees meet KPIs above 80%.
- Employees who meet KPIs win more awards.
- R&D has the highest KPI rate at 45%, but only 1% of awards are given to this department.
- Training effectiveness varies on KPI achievement.
- Employees with 1-10 years of service achieve KPIs at 30%-40%.
- Employees aged 27-37 perform best on KPIs.
- Bachelor's degree holders achieve 65% KPI performance, while master's holders achieve only 29%.

### Employee Ratings Last Year
- Average employee rating is 3.35; 18% rated low (1-2 stars), particularly in Sales and Marketing.

### Recruitment Channels
- Over 50% of hires come from "other" channels; only 1.8% from referrals.
- Education levels are balanced across channels.

---

## Recommendations

### Enhance Gender Diversity
- Ensure that interview panels include members of different genders to minimize bias and provide a more balanced perspective.

### Strengthen Performance Management
- Implement performance improvement plans.
- Align award criteria with KPI achievement.
- Re-evaluate award distribution practices.
- Promote effective training programs.
- Provide ongoing training for long-tenured staff.
- Develop support programs for younger and older employees.
- Investigate performance factors and offer role-specific training.

### Address Employee Satisfaction
- Conduct surveys to gather feedback and improve job satisfaction.

### Optimize Recruitment Processes
- Optimize sourcing strategies and enhance the referral program.

---

## Conclusion

- This project offers a detailed analysis of employee performance and satisfaction.
- Key strategies for improvement include:
  - **Promoting Gender Diversity:** Foster a more inclusive workplace.
  - **Strengthening Performance Management:** Align awards with KPI achievement and provide ongoing training.
  - **Improving Employee Satisfaction:** Gather feedback through surveys to enhance job satisfaction.
  - **Optimizing Recruitment Processes:** Enhance sourcing strategies and referral programs.

- Implementing these strategies will enhance workforce effectiveness and drive long-term success.

## License

MIT license

Copyright (c) [2024] [Aimee Le]
