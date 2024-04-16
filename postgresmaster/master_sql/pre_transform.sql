CREATE OR REPLACE FUNCTION preprocess.copy_expert(
    table_name TEXT,
    csv_path TEXT,
    column_count INTEGER
)
RETURNS VOID AS
$$
DECLARE
col TEXT;
col_first TEXT;
iter INTEGER;
BEGIN
    RAISE NOTICE 'CREATING LANDING TABLE';
    --stage 1 
    EXECUTE FORMAT("CREATE TABLE %I ();", table_name); -- creating landing table
    FOR iter IN 1..column_count
    LOOP -- loop through and populate table based on 
        EXECUTE FORMAT("ALTER TABLE %I ADD COLUMN col_%s TEXT;", table_name, iter);
    END LOOP;
    RAISE NOTICE 'ADDED COLUMNS TO LANDING TABLE';
    -- stage 2
    EXECUTE FORMAT("COPY %I FROM %L WITH (FORMAT CSV, DELIMITER ',', HEADER);", table_name, csv_path);

    FOR col IN EXECUTE FORMAT('SELECT UNNEST(string_to_array(TRIM(%s::text, ''()''), '','')) FROM %s WHERE col_1 = %L', table_name, table_name, col_first)
    LOOP
        EXECUTE FORMAT("ALTER TABLE %I RENAME COLUMN col_%s TO %s", table_name, iter, col);
        iter := iter + 1; -- increment counter
    END LOOP;
    -- delete the columns row
    EXECUTE FORMAT('DELETE FROM %I WHERE %s = %L', table_name, col_first, col_first);

END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION preprocess.etl_setup(
    csv_file_path TEXT, 
    number_of_columns INTEGER, 
    array_of_files TEXT[]
)
RETURNS VOID AS
$$
DECLARE
file_name_ VARCHAR(20);
no_of_files INTEGER; -- getting the total length of records in a file
iter INTEGER;
BEGIN   
    INSERT INTO no_of_files
    SELECT CARDINALITY(id) FROM array_of_files;

    CREATE TEMP TABLE tmp(csv_file_name VARCHAR(20));
    
    -- inserting filenames into tmp table from array retrieved from python code
    FOR iter IN 1..no_of_files
    LOOP
        INSERT INTO tmp (csv_file_name) 
        SELECT array_of_files[i];
    END LOOP;

    -- for as long as there is a filename within the temporary table loop through
    WHILE(SELECT COUNT(*) FROM tmp WHERE csv_file_name IS NOT NULL) > 0
    LOOP
        SELECT *
        FROM tmp
        WHERE file_name_ = csv_file_name
        ORDER BY csv_file_name ASC
        LIMIT 1;

         -- loading staging tables with data from csv files
        EXECUTE FORMAT('CALL preprocess.copy_expert(%I, %I, %I)', file_name_, csv_file_path, number_of_columns);
        DELETE FROM tmp WHERE csv_file_name = file_name_; -- delete the filename from the table 
    END LOOP;

    -- create tables dynamically, based on input of table names variable
    -- set loose records with no data typing just to get data into tables 

     -- use the file directory where the csv files are stored 
     -- loop through directory for each file and create table 
     -- use shell command to do so

     --THEN STAGE 1  or separate stored procedure 
     -- CREATE 15 columns within table and then change the column names to be the first row of records in csv
     -- separate these values by ',' to get the text content only 
     --
     --stage 2 or call a separate stored procedure for this 
     -- copy from file directory to the database table directly 

END;
$$ LANGUAGE plpgsql;

REVOKE ALL ON FUNCTION preprocess.etl_setup(csv_file_path TEXT, number_of_columns INTEGER, array_of_files TEXT[]) FROM dwdev, dba, airflow, postgres, pgbouncer; -- remove access to etl_setup function for all users
GRANT EXECUTE ON FUNCTION preprocess.etl_setup(csv_file_path TEXT, number_of_columns INTEGER, array_of_files TEXT[]) TO dbdev;

REVOKE ALL ON FUNCTION preprocess.copy_expert(table_name TEXT, csv_path TEXT, column_count INTEGER) FROM dwdev, dba, airflow, postgres, pgbouncer; -- remove access to copy_expert function for all users
GRANT EXECUTE ON FUNCTION preprocess.copy_expert(table_name TEXT, csv_path TEXT, column_count INTEGER) TO dbdev;
