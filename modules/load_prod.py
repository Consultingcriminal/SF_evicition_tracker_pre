import pandas as pd
import mysql.connector
from sqlalchemy import create_engine

class prod_layer:
    
    def __init__(self,schema_status):
        self.schema_status = schema_status
    
    def execute_query(self,query):
        try:
            self.connection = mysql.connector.connect(host='localhost',user='root',password='###')
            self.cursor = self.connection.cursor()

            if self.schema_status == False:
                self.create_raw =  "CREATE SCHEMA sf_prod"
                self.cursor.execute(self.create_raw)
                self.schema_status = True
            
            result = self.cursor.execute(query)
            print("Query Executed successfully")

        except mysql.connector.Error as error:
            print("Failed to execute in MySQL: {}".format(error))

        finally:
            if self.connection.is_connected():
                self.cursor.close()
                self.connection.close()
                print("MySQL connection is closed")        

    def dim_location(self):
        
        query = """
        CREATE TABLE sf_prod.dim_location (
	    location_key serial PRIMARY KEY,
	    city text,
	    state text,
	    eviction_notice_source_zipcode text
        );
        """

        self.execute_query(query)
        print("End")

    	 
    def dim_date(self):
        query = """
        CREATE TABLE sf_prod.dim_date (
	    date_key serial PRIMARY KEY,
        date date,
        year int,
        month int,
        month_name text,
        day int,
        day_of_year int,
        weekday_name text,
        calendar_week int,
        formatted_date text,
        quartal text,
        year_quartal text,
        yea_month text,
        year_calendar_week text,
        weekend text,
        us_holiday text,
        period text,
        cw_start date,
        cw_end date,
        month_start date,
        month_end date
        );
        """

        self.execute_query(query)
        print("End")

    def dim_district(self):
        ## Indexing Left
        query = """
        CREATE TABLE sf_prod.dim_district (
	    district_key serial PRIMARY KEY,
	    district text
        );
        """
        self.execute_query(query)
        print("End")   

    def dim_neighborhood(self):
        ## Indexing Left
        query = """ 
        CREATE TABLE sf_prod.dim_neighborhood (
	    neighborhood_key serial PRIMARY KEY,
	    neighborhood text
        );
        """
        self.execute_query(query)
        print("End") 

    def mod_reason(self):

        query = """
        CREATE TABLE sf_prod.dim_mod_reason (
	    reason_key serial PRIMARY KEY,
	    reason_desc text
        );
        """
        self.execute_query(query)
        print("End")    

    def fact_eviction(self):
        query = """
        CREATE TABLE sf_prod.fact_evictions (
        eviction_key VARCHAR(7) PRIMARY KEY,
        location_key int,
        district_key int,
        neighborhood_key int,
        reason_group_key int,
        file_date_key int,
        constraints_date_key int,
        street_address text,
        latitude text,
        longitude text
        );
        """
        self.execute_query(query)

        
if __name__ == '__main__':

    pl = prod_layer(schema_status = False)   
    pl.dim_location()
    pl.dim_date()
    pl.dim_district()
    pl.dim_neighborhood()
    pl.fact_eviction()
    pl.mod_reason()

