
-- Populate District Dimension

INSERT INTO sf_staging.dim_district(district)
SELECT DISTINCT COALESCE(`supervisor_district`,'Unknown')
FROM sf_raw.soda_evictions;    

-- Populate Neighborhood Dimension
INSERT INTO sf_staging.dim_neighborhood(neighborhood)
SELECT DISTINCT COALESCE(`neighborhoods_-_analysis_boundaries`,'Unknown')
FROM sf_raw.soda_evictions;      

-- Populate Location Dimension

INSERT INTO sf_staging.dim_location (location_key, city, state, eviction_notice_source_zipcode)
SELECT 0, 'Unknown', 'Unknown', 'Unknown';

INSERT INTO sf_staging.dim_location (city, state, eviction_notice_source_zipcode)
SELECT DISTINCT
	COALESCE(`city`, 'Unknown') as city,
	COALESCE(`state`, 'Unknown') as state,
	COALESCE(`eviction_notice_source_zipcode`, 'Unknown') as zip_code
FROM sf_raw.soda_evictions
WHERE 
city IS NOT NULL OR state IS NOT NULL OR eviction_notice_source_zipcode IS NOT NULL;

-- Populate Reason

INSERT INTO sf_staging.dim_mod_reason(reason_desc)
WITH extract_reason AS (SELECT
	eviction_id,
	CASE WHEN `non_payment` = 1 THEN 'non_payment|' ELSE '' END as concat_reason1,
	CASE WHEN `breach` = 1 THEN 'breach|' ELSE '' END as concat_reason2,
	CASE WHEN `nuisance` = 1 THEN 'nuisance|' ELSE '' END as concat_reason3,
	CASE WHEN `illegal_use` = 1 THEN 'illegal_use|' ELSE '' END as concat_reason4, 
	CASE WHEN `failure_to_sign_renewal` = 1 THEN 'failure_to_sign_renewal|' ELSE '' END as concat_reason5,
	CASE WHEN `access_denial` = 1 THEN 'access_denial|' ELSE '' END as concat_reason6,
	CASE WHEN `unapproved_subtenant` = 1 THEN 'unapproved_subtenant|' ELSE '' END as concat_reason7,
	CASE WHEN `owner_move_in` = 1 THEN 'owner_move_in|' ELSE '' END as concat_reason8,
	CASE WHEN `demolition` = 1 THEN 'demolition|' ELSE '' END as concat_reason9,
	CASE WHEN `capital_improvement` = 1 THEN 'capital_improvement|' ELSE '' END as concat_reason10,
	CASE WHEN `substantial_rehab` = 1 THEN 'substantial_rehab|' ELSE '' END as concat_reason11,
	CASE WHEN `ellis_act_withdrawal` = 1 THEN 'ellis_act_withdrawal|' ELSE '' END as concat_reason12,
	CASE WHEN `condo_conversion` = 1 THEN 'condo_conversion|' ELSE '' END as concat_reason13,
	CASE WHEN `roommate_same_unit` = 1 THEN 'roommate_same_unit|' ELSE '' END as concat_reason14,
	CASE WHEN `other_cause` = 1 THEN 'other_cause|' ELSE '' END as concat_reason15,
	CASE WHEN `late_payments` = 1 THEN 'late_payments|' ELSE '' END as concat_reason16,
	CASE WHEN `lead_remediation` = 1 THEN 'lead_remediation|' ELSE '' END as concat_reason17,
	CASE WHEN `development` = 1 THEN 'development|' ELSE '' END as concat_reason18,
	CASE WHEN `good_samaritan_ends` = 1 THEN 'good_samaritan_ends' ELSE '' END as concat_reason19
	FROM sf_raw.soda_evictions),
    
 comb_reason AS (
 SELECT eviction_id,concat(concat_reason1,concat_reason2,concat_reason3,concat_reason4,concat_reason5,concat_reason6,
			concat_reason7,concat_reason8,concat_reason9,concat_reason10,concat_reason11,concat_reason12,
			concat_reason13,concat_reason14,concat_reason15,concat_reason16,concat_reason17,
			concat_reason18,concat_reason19) AS concat_reason
FROM extract_reason),

un_comb_reason AS (
SELECT eviction_id,TRIM(TRAILING '|' FROM (CASE WHEN concat_reason = '' THEN 'Unknown' ELSE concat_reason END)) 
as concat_reason 
FROM comb_reason)
SELECT DISTINCT concat_reason FROM un_comb_reason;


-- Populate Date

INSERT INTO sf_staging.dim_date
(`date`,`year`,`month`,`month_name`,`day`,`day_of_year`,`weekday_name`,`calendar_week`,`formatted_date`,`quartal`,`year_quartal`,`yea_month`,`year_calendar_week`,`weekend`,`us_holiday`,`period`,`cw_start`,`cw_end`,`month_start`,`month_end`)
SELECT  
	DISTINCT `file_date` AS date,
    YEAR(`file_date`) AS year,
    MONTH(`file_date`) AS month,
    monthname(`file_date`) AS month_name,
    day(`file_date`) AS day,
    dayofyear(`file_date`) AS day_of_year,
    dayname(`file_date`) AS weekday_name,
    weekofyear(`file_date`) AS calendar_week,
    CONVERT(DATE(`file_date`),char) as formatted_date,
    CONCAT("Q",quarter(`file_date`)) AS quartal,
	CONCAT(YEAR(`file_date`),"/Q",quarter(`file_date`)) AS year_quartal,
    CONCAT(YEAR(`file_date`),"/M",MONTH(`file_date`)) AS yea_month,
    CONCAT(YEAR(`file_date`),"/W",weekofyear(`file_date`)) AS year_calendar_week,
    IF(dayname(`file_date`) IN ('Saturday','Sunday'), "YES", "NO") AS weekend,
	IF (DATE_FORMAT(`file_date`,'%m%d') IN ('0101', '0704', '1225', '1226'),"Holiday","Working") AS us_holiday,
    CASE WHEN DATE_FORMAT(`file_date`,'%m%d') BETWEEN '0701' AND '0831' THEN 'Summer break'
	     WHEN DATE_FORMAT(`file_date`,'%m%d')BETWEEN '1115' AND '1225' THEN 'Christmas season'
	     WHEN DATE_FORMAT(`file_date`,'%m%d') > '1225' OR DATE_FORMAT(`file_date`,'%m%d') <= '0106' THEN 'Winter break'
		 ELSE 'Normal' END as period,
	DATE(`file_date` + INTERVAL ( - WEEKDAY(`file_date`)) DAY) as cw_start, 
	DATE(`file_date` + INTERVAL (6 - WEEKDAY(`file_date`)) DAY) as cw_end,
    DATE(DATE_SUB(`file_date`,INTERVAL DAY(`file_date`)-1 DAY)) AS month_start,
    LAST_DAY(`file_date`) AS month_end
FROM sf_raw.soda_evictions;

-- Temp_Reason For Fact Table

CREATE TABLE IF NOT EXISTS `sf_staging`.`temp_reason` (
  `eviction_id` tinytext,
  `concat_reason` text
);

-- Populating Temp_Reason

INSERT INTO `sf_staging`.`temp_reason`
(`eviction_id`,
`concat_reason`)
WITH extract_reason AS (SELECT
	eviction_id,
	CASE WHEN `non_payment` = 1 THEN 'non_payment|' ELSE '' END as concat_reason1,
	CASE WHEN `breach` = 1 THEN 'breach|' ELSE '' END as concat_reason2,
	CASE WHEN `nuisance` = 1 THEN 'nuisance|' ELSE '' END as concat_reason3,
	CASE WHEN `illegal_use` = 1 THEN 'illegal_use|' ELSE '' END as concat_reason4, 
	CASE WHEN `failure_to_sign_renewal` = 1 THEN 'failure_to_sign_renewal|' ELSE '' END as concat_reason5,
	CASE WHEN `access_denial` = 1 THEN 'access_denial|' ELSE '' END as concat_reason6,
	CASE WHEN `unapproved_subtenant` = 1 THEN 'unapproved_subtenant|' ELSE '' END as concat_reason7,
	CASE WHEN `owner_move_in` = 1 THEN 'owner_move_in|' ELSE '' END as concat_reason8,
	CASE WHEN `demolition` = 1 THEN 'demolition|' ELSE '' END as concat_reason9,
	CASE WHEN `capital_improvement` = 1 THEN 'capital_improvement|' ELSE '' END as concat_reason10,
	CASE WHEN `substantial_rehab` = 1 THEN 'substantial_rehab|' ELSE '' END as concat_reason11,
	CASE WHEN `ellis_act_withdrawal` = 1 THEN 'ellis_act_withdrawal|' ELSE '' END as concat_reason12,
	CASE WHEN `condo_conversion` = 1 THEN 'condo_conversion|' ELSE '' END as concat_reason13,
	CASE WHEN `roommate_same_unit` = 1 THEN 'roommate_same_unit|' ELSE '' END as concat_reason14,
	CASE WHEN `other_cause` = 1 THEN 'other_cause|' ELSE '' END as concat_reason15,
	CASE WHEN `late_payments` = 1 THEN 'late_payments|' ELSE '' END as concat_reason16,
	CASE WHEN `lead_remediation` = 1 THEN 'lead_remediation|' ELSE '' END as concat_reason17,
	CASE WHEN `development` = 1 THEN 'development|' ELSE '' END as concat_reason18,
	CASE WHEN `good_samaritan_ends` = 1 THEN 'good_samaritan_ends' ELSE '' END as concat_reason19
	FROM sf_raw.soda_evictions),
    
 comb_reason AS (
 SELECT eviction_id,concat(concat_reason1,concat_reason2,concat_reason3,concat_reason4,concat_reason5,concat_reason6,
			concat_reason7,concat_reason8,concat_reason9,concat_reason10,concat_reason11,concat_reason12,
			concat_reason13,concat_reason14,concat_reason15,concat_reason16,concat_reason17,
			concat_reason18,concat_reason19) AS concat_reason
FROM extract_reason),

un_comb_reason AS (
SELECT eviction_id,TRIM(TRAILING '|' FROM (CASE WHEN concat_reason = '' THEN 'Unknown' ELSE concat_reason END)) 
as concat_reason 
FROM comb_reason)
SELECT eviction_id,concat_reason 
FROM un_comb_reason u;


-- Populating Fact_Table

 SET SQL_MODE='ALLOW_INVALID_DATES';
 INSERT INTO `sf_staging`.`fact_evictions`(`eviction_key`,`location_key`,
 `district_key`,`neighborhood_key`,`reason_group_key`,`file_date_key`,
 `constraints_date_key`,`street_address`,`latitude`,`longitude`)
WITH extract_fact AS (
SELECT 
	f.eviction_id as eviction_key,
    COALESCE(l.location_key, -1) as location_key,
    COALESCE(d.district_key, -1) as district_key,
	COALESCE(n.neighborhood_key, -1) as neighborhood_key,
    dmr.reason_key as reason_key,
	COALESCE(dt1.date_key, -1) as file_date_key,
	COALESCE(dt2.date_key, -1) as constraints_date_key,
    f.address as street_address,
	f.latitude as latitude,
	f.longitiude as longitude
FROM sf_raw.soda_evictions f
LEFT JOIN sf_staging.dim_district d ON f.supervisor_district = d.district
LEFT JOIN sf_staging.dim_neighborhood n ON f.`neighborhoods_-_analysis_boundaries`= n.neighborhood
LEFT JOIN sf_staging.dim_location l 
	ON COALESCE(f.city, 'Unknown') = l.city
	AND COALESCE(f.state, 'Unknown') = l.state
	AND COALESCE(f.eviction_notice_source_zipcode, 'Unknown') = l.eviction_notice_source_zipcode
LEFT JOIN sf_staging.dim_date dt1 ON f.file_date = dt1.date
LEFT JOIN sf_staging.dim_date dt2 ON f.constraints_date = dt2.date
LEFT JOIN sf_staging.temp_reason tr ON f.eviction_id = tr.eviction_id
LEFT JOIN sf_staging.dim_mod_reason dmr ON tr.concat_reason = dmr.reason_desc)

SELECT * FROM extract_fact;
    
    
-- Truncate Temp_Reason

TRUNCATE TABLE `sf_staging`.`temp_reason`;



