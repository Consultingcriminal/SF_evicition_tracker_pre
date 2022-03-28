INSERT INTO sf_prod.dim_district(district_key,district)
SELECT * 
FROM sf_staging.dim_district;

INSERT INTO sf_prod.dim_date(date_key,date,year,
month,month_name,day,day_of_year,weekday_name,
calendar_week,formatted_date,quartal,year_quartal,
yea_month,year_calendar_week,weekend,
us_holiday,period,cw_start,cw_end,month_start,month_end)
SELECT * 
FROM sf_staging.dim_date;


INSERT INTO sf_prod.dim_location(location_key,city,
state,eviction_notice_source_zipcode)
SELECT * 
FROM sf_staging.dim_location;

INSERT INTO sf_prod.dim_mod_reason(reason_key,reason_desc)
SELECT *
FROM sf_staging.dim_mod_reason;

INSERT INTO sf_prod.dim_neighborhood(neighborhood_key,neighborhood)
SELECT *
FROM sf_staging.dim_neighborhood;

INSERT INTO sf_prod.fact_evictions(eviction_key,location_key,
district_key,neighborhood_key,
reason_group_key,file_date_key,
constraints_date_key,street_address,latitude,longitude)
SELECT *
FROM sf_staging.fact_evictions;









