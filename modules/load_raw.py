import pandas as pd
import mysql.connector
from sqlalchemy import create_engine
from get_data import get_evictions_data
  
def create_raw_schema():
    try:
        connection = mysql.connector.connect(host='localhost',
                                            user='root',
                                            password='hero@123')

        create_raw =  "CREATE SCHEMA sf_raw";                                   

        mySql_Create_Table_Query = """
        CREATE TABLE sf_raw.soda_evictions (
        raw_id serial PRIMARY KEY,
        eviction_id text,
        address text,
        city text,
        state text,
        eviction_notice_source_zipcode text,
        file_date timestamp,
        non_payment boolean,
        breach boolean,
        nuisance boolean,
        illegal_use boolean,
        failure_to_sign_renewal boolean,
        access_denial boolean,
        unapproved_subtenant boolean,
        owner_move_in boolean,
        demolition boolean,
        capital_improvement boolean,
        substantial_rehab boolean,
        ellis_act_withdrawal boolean,
        condo_conversion boolean,
        roommate_same_unit boolean,
        other_cause boolean,
        late_payments boolean,
        lead_remediation boolean,
        development boolean,
        good_samaritan_ends boolean,
        constraints_date timestamp,
        supervisor_district text,
        neighborhoods_-_analysis_boundaries text,
        latitude text,
        longitude text
        )
        """

        cursor = connection.cursor()
        cursor.execute(create_raw)
        result = cursor.execute(mySql_Create_Table_Query)
        print("Raw Table created successfully ")

    except mysql.connector.Error as error:
        print("Failed to create table in MySQL: {}".format(error))
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection is closed")        

def load_to_raw(evicition_df):
    engine = create_engine("mysql+pymysql://" + "root" + ":" + "hero@123" + "@" + "localhost" + "/" + "sf_raw")
    print("Opened database successfully")   
        
    try:
        eviction_df.to_sql("soda_evictions", con=engine,if_exists='append',index=False)
    except:
        print("Data already exists in the database")              
if __name__ == '__main__':
    
    eviction_df = get_evictions_data('2013-01-01')
    create_raw_schema()            
    load_to_raw(eviction_df)
