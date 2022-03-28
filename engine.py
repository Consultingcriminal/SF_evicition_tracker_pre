import mysql.connector

def run_sql_script(path):
    host_args = {
    "host": "localhost",
    "database":"sf_raw",
    "user": "root",
    "password": "hero@123"
    }

    con = mysql.connector.connect(**host_args)

    cur = con.cursor(dictionary=True)

    with open(path, 'r') as sql_file:
        result_iterator = cur.execute(sql_file.read(), multi=True)
    for res in result_iterator:
        print("Running query: ", res)  # Will print out a short representation of the query
        print(f"Affected {res.rowcount} rows" )

    con.commit()  # Remember to commit all your changes!


if __name__ == '__main__':

    #run_sql_script('sql_scripts/full_load.sql')
    run_sql_script('sql_scripts/full_load_prod.sql')
