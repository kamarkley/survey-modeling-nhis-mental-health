# ==============================================================================
# Title: Evaluating Complementary & Alternative Medicine (CAM) Exposures 
#        on Population Mental Health via NHIS Complex Survey Layouts
# Framework: R (ipumsr, survey)
# ==============================================================================

library(ipumsr)
library(survey)

# --- STEP 1: DATA INGESTION & SCHEMATIC EXTRACTION ---
# Note: Raw data data file (nhis_00001.xml) omitted from version control via .gitignore
ddi <- read_ipums_ddi("nhis_00001.xml")
data <- read_ipums_micro(ddi)

vars_keep <- c(
  "AGE", "SEX", "MARSTCUR", "RACENEW", "HISPETH", "EDUCREC2", "INCFAM07ON", "HEALTH", 
  "AEFFORT", "AFEELINT1MO", "AHOPELESS", "ANERVOUS", "ARESTLESS", "ASAD", "AWORTHLESS", 
  "WORFREQ", "WORRX", "DEPFREQ", "DEPRX", "DEPFEELEVL",
  "COMYR", "COMUSEYR", "COMEXNO", "DITATKINYR", "DITMACYR", "DITORNYR", 
  "DITPRITYR", "DITVEGYR", "DITEXNO", "EHTYR", "EHTUSEYR", "EHTEXNO", 
  "HOMYR", "HOMUSEYR", "HOMEXNO", "YTQYOGYR", "YTQTAIYR", "YTQIGYR", "YTQEXNO",
  "STRATA", "PSU", "PERWEIGHT"
)
nhis <- data[, vars_keep]

# --- STEP 2: METRIC FEATURE ENGINEERING ---
# Compute clinical K6 Psychological Distress scale score
k6_components <- c("AEFFORT", "AWORTHLESS", "AHOPELESS", "ANERVOUS", "ARESTLESS", "ASAD")
nhis$K6_total <- rowSums(nhis[, k6_components], na.rm = TRUE)

# Establish clinical benchmarks and binary exposure profiles
nhis$High_PD  <- ifelse(nhis$K6_total >= 13, 1, 0)
nhis$Anx_med  <- ifelse(nhis$WORRX == 1, 1, 0)
nhis$Dep_med  <- ifelse(nhis$DEPRX == 1, 1, 0)
nhis$Poor_MH  <- ifelse(nhis$K6_total >= 13 | nhis$WORRX == 1 | nhis$DEPRX == 1, 1, 0)

# Normalize Demographics
nhis$EDU    <- nhis$EDUCREC2
nhis$INCOME <- nhis$INCFAM07ON

# Harmonize multi-variable CAM modality exposures
nhis$Chiro_use  <- ifelse(nhis$COMYR == 1 | nhis$COMUSEYR == 1, 1, 0)
nhis$Chiro_freq <- nhis$COMEXNO

nhis$Energy_use  <- ifelse(nhis$EHTYR == 1 | nhis$EHTUSEYR == 1, 1, 0)
nhis$Energy_freq <- nhis$EHTEXNO

nhis$Homeo_use  <- ifelse(nhis$HOMYR == 1 | nhis$HOMUSEYR == 1, 1, 0)
nhis$Homeo_freq <- nhis$HOMEXNO

diet_vars        <- c("DITATKINYR", "DITMACYR", "DITORNYR", "DITPRITYR", "DITVEGYR")
nhis$DietCAM_use <- ifelse(rowSums(nhis[, diet_vars] == 1, na.rm = TRUE) > 0, 1, 0)
nhis$Atkins_use  <- nhis$DITATKINYR
nhis$Macbio_use  <- nhis$DITMACYR
nhis$Ornish_use  <- nhis$DITORNYR
nhis$Pritikin_use <- nhis$DITPRITYR
nhis$Veg_use     <- nhis$DITVEGYR
nhis$Diet_freq   <- nhis$DITEXNO

yoga_vars        <- c("YTQYOGYR", "YTQTAIYR", "YTQIGYR")
nhis$YogaCAM_use <- ifelse(rowSums(nhis[, yoga_vars] == 1, na.rm = TRUE) > 0, 1, 0)
nhis$Yoga_use    <- nhis$YTQYOGYR
nhis$TaiChi_use  <- nhis$YTQTAIYR
nhis$QiGong_use  <- nhis$YTQIGYR
nhis$Yoga_freq   <- nhis$YTQEXNO

# --- STEP 3: COMPLEX SURVEY DESIGN SPECIFICATION ---
# Instantiating sample weights, clustering variables (PSU), and stratification loops
nhis_design <- svydesign(
  id = ~PSU,
  strata = ~STRATA,
  weights = ~PERWEIGHT,
  data = nhis,
  nest = TRUE
)

# --- STEP 4: MULTIVARIABLE STRATIFIED SURVEY GLM MODELING ---
# Fitting multi-variable quasibinomial GLMs to account for survey layout inflation
fit_chiro <- svyglm(Poor_MH ~ Chiro_use + AGE + SEX + EDU + INCOME, 
                    design = nhis_design, family = quasibinomial())

fit_use   <- svyglm(Poor_MH ~ Chiro_use + DietCAM_use + YogaCAM_use + Homeo_use + Energy_use +
                    AGE + SEX + EDU + INCOME, design = nhis_design, family = quasibinomial())

# --- STEP 5: POST-ESTIMATION EXPORTER ---
# Custom transformation function to convert log-odds to interpretative Odds Ratios (OR)
get_OR_CI <- function(model) {
  coef_est <- coef(model)
  se       <- sqrt(diag(vcov(model)))
  OR       <- exp(coef_est)
  CI_lower <- exp(coef_est - 1.96 * se)
  CI_upper <- exp(coef_est + 1.96 * se)
  
  data.frame(
    Variable = names(OR),
    Odds_Ratio = OR,
    CI_Lower = CI_lower,
    CI_Upper = CI_upper,
    row.names = NULL
  )
}

# Print target post-estimation parameter metrics
print(get_OR_CI(fit_chiro))