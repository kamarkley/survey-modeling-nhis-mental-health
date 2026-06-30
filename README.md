# Population Health Metrics: Modeling CAM Modalities and Mental Health Outcomes via NHIS Complex Survey Designs

## Project Overview
This repository contains the stratified biostatistical pipeline engineered to evaluate the relationship between Complementary and Alternative Medicine (CAM) exposures—such as Chiropractic care, Energy Healing, Homeopathy, Special Diets, and Yoga/Tai Chi—and population mental health outcomes.

Using microdata from the National Health Interview Survey (**NHIS**), this study handles complex sample architectures by deploying variance-estimation frameworks that account for population stratification, clustering, and sample weights.

---

## Tech Stack & Statistical Framework
* **Language:** R 4.3+
* **Core Libraries:** `survey` (for complex sample design calibration), `ipumsr` (for hierarchical microdata ingestion)
* **Methodology:** Multivariable Complex Survey Logistic Regression (`svyglm`) utilizing a `quasibinomial` family mapping to compute valid standard errors across inflated population weights.

---

## 📊 Data Engineering & Variable Design

The data processing architecture translates raw survey responses into standardized clinical and exposure benchmarks:
* **The K6 Mental Health Index:** Aggregates 6 non-specific psychological distress markers (`AEFFORT`, `AWORTHLESS`, `AHOPELESS`, `ANERVOUS`, `ARESTLESS`, `ASAD`) scored via a vector summation loop. 
* **Clinical Endpoints (`Poor_MH`):** A binary indicator tracking individuals exhibiting severe psychological distress (K6 Score $\ge 13$) or currently requiring prescription interventions for anxiety (`WORRX`) or depression (`DEPRX`).
* **Exposure Coding:** Consolidated fragmented annual survey arrays into clean binary tracking arrays (e.g., `Chiro_use`, `DietCAM_use`, `YogaCAM_use`).

---

## Stratified Modeling & Post-Estimation Results

To isolate the true behavioral signal, models were adjusted for baseline social covariates: Age, Biological Sex, Institutional Education Level, and Household Income Brackets. 

When evaluating the **Chiropractic Utilization Model (`fit_chiro`)**, the post-estimation matrix yielded a highly significant protective signal:

| Predictor Variable | Odds Ratio (OR) | 95% CI Lower | 95% CI Upper | Statistical Interpretation |
| :--- | :---: | :---: | :---: | :--- |
| **(Intercept)** | 28.3489 | 25.8519 | 31.0871 | Population baseline log-odds logit scale |
| **Chiro_use** | **0.1475** | **0.1373** | **0.1584** | **Significant 85.2% lower odds of poor mental health outcomes.** |
| **AGE** | 0.9780 | 0.9769 | 0.9790 | Negligible structural drift per progressive age unit |
| **SEX** | 0.8706 | 0.8352 | 0.9075 | Notable gendered variation across strata |
| **EDU** | 0.9713 | 0.9697 | 0.9729 | Incremental reduction in risk per education bracket |
| **INCOME** | 1.0179 | 1.0179 | 1.0179 | Baseline income distribution index bound |

### Core Analytical Insight
By properly initializing the survey layout via `svydesign(id = ~PSU, strata = ~STRATA, weights = ~PERWEIGHT)`, the model avoids artificially deflated standard errors. 

The resulting outputs reveal a profound epidemiological narrative: individuals participating in Chiropractic care exhibited an **85.2% lower odds** of crossing clinical poor mental health markers ($OR = 0.147, 95\%\text{ CI: } [0.137, 0.158]$) compared to non-users, holding all demographic and socioeconomic adjustments perfectly constant.

---

## Repository Structure
* `nhis_mental_health_cam.R` - Cleaned, fully commented R pipeline covering variable engineering, survey design specification, and multivariable modeling loops.
* `.gitignore` - Configured to systematically exclude massive source data files (`*.xml`, `*.dat`) to preserve version control efficiency and comply with licensing guidelines.
