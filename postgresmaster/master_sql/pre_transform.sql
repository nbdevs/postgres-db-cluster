CREATE OR REPLACE PROCEDURE preprocess.copy_expert(
    table_name TEXT,
    csv_path VARCHAR(200),
    column_count INTEGER,
    table_name_less_date VARCHAR(30)
)
LANGUAGE PLPGSQL
AS $$
DECLARE
col TEXT;
col_first TEXT;
iter INTEGER := 1;
BEGIN
    RAISE NOTICE 'CREATING LANDING TABLE';
    --stage 1 
    EXECUTE FORMAT('CREATE TABLE IF NOT EXISTS preprocess.%s();', table_name); -- creating landing table
    
    RAISE NOTICE 'ADDING COLUMNS TO LANDING TABLE';
    FOR i IN 1..column_count
    LOOP -- loop through and populate table based on 
        EXECUTE FORMAT('ALTER TABLE preprocess.%s ADD COLUMN col_%s TEXT;', table_name, i);
    END LOOP;

   RAISE NOTICE 'COPYING CSV DATA INTO TABLE';
    -- stage 2
    EXECUTE FORMAT('COPY preprocess.%s FROM ''%s'' WITH (FORMAT CSV, DELIMITER '','');', table_name, csv_path);

    EXECUTE FORMAT('SELECT col_1 FROM preprocess.%s LIMIT 1;', table_name) INTO col_first; --first row containing column names

    RAISE NOTICE 'RENAMING COLUMN NAMES WITHIN TABLE';
  --  SET iter TO 1;
    FOR col IN EXECUTE FORMAT('SELECT UNNEST(string_to_array(TRIM(%s::text, ''()''), '','')) FROM preprocess.%s WHERE col_1 = ''%s'';', table_name, table_name, col_first) -- update column names to the correct names in col_first 
    LOOP
        EXECUTE FORMAT('ALTER TABLE preprocess.%s RENAME COLUMN col_%s TO %s;', table_name, iter, col);
        iter := iter + 1; -- increment counter
    END LOOP;
    RAISE NOTICE 'DELETING COLUMN FROM TABLE';
    -- delete the columns row
    EXECUTE FORMAT('DELETE FROM preprocess.%s WHERE %s = %L;', table_name, col_first, col_first);

END;
$$ SECURITY DEFINER; -- to bypass superuser permissions 

CREATE OR REPLACE PROCEDURE preprocess.etl_setup(
    no_tables INTEGER,
    number_of_columns INTEGER ARRAY, 
    array_of_files TEXT ARRAY,
    table_name_less_date TEXT ARRAY,
    array_of_csv TEXT ARRAY
)
LANGUAGE PLPGSQL
AS $$
DECLARE
file_name_ VARCHAR(30);
full_table_name_ VARCHAR(30);
csv_file_ VARCHAR(200);
number_ INTEGER;
record_count INTEGER;
BEGIN   

    RAISE NOTICE 'CREATING TEMP TABLE';
    -- creating temporary table to store files, filenames and csv file locations
    CREATE TEMP TABLE IF NOT EXISTS tmp(
        csv_file_name VARCHAR(30),
        full_table_name VARCHAR(30),
        csv_file_path VARCHAR(200)
    );
    
    RAISE NOTICE 'INSERTING RECORDS INTO TABLE';
    -- inserting filenames into tmp table from array retrieved from python code
    FOR i IN 1..no_tables -- ARRAYS START FROM 1 
    LOOP
        INSERT INTO tmp (csv_file_name, full_table_name, csv_file_path) 
        VALUES (array_of_files[i], table_name_less_date[i], array_of_csv[i]);
    END LOOP;

    FOR j IN 1..no_tables
    LOOP
        RAISE NOTICE 'CREATING PROCEDURE PARAMETERS';

        WITH file_names_ AS(
            SELECT csv_file_name
            FROM tmp
            LIMIT 1
        )
        SELECT * FROM file_names_ INTO file_name_; -- variable for file name
        
        WITH table_names_ AS(
            SELECT full_table_name
            FROM tmp 
            LIMIT 1
        )
        SELECT * FROM table_names_ INTO full_table_name_; -- variable for file path for table

        WITH csv_files AS(
            SELECT csv_file_path
            FROM tmp
            LIMIT 1
        )
        SELECT * FROM csv_files INTO csv_file_; -- variable for csv file directory

        WITH record_ AS(
            SELECT number_of_columns[j]::INTEGER
        )
        SELECT * FROM record_ INTO record_count;

        RAISE NOTICE 'CALLING COPY EXPERT FUNCTION';
        -- loading staging tables with data from csv files
        EXECUTE FORMAT('CALL preprocess.copy_expert(''%s'', ''%s'', ''%s'', ''%s'')', file_name_, csv_file_, record_count, full_table_name_);
        -- removing data from temp table
        DELETE FROM tmp WHERE csv_file_name = file_name_; -- delete the filename from the table 
        DELETE FROM tmp WHERE csv_file_path = csv_file_; -- delete the csv file from the table 
        DELETE FROM tmp WHERE full_table_name = full_table_name_; -- delete the table name including date from the table 
    END LOOP;
END;
$$ SECURITY DEFINER;

REVOKE ALL ON PROCEDURE preprocess.etl_setup(no_tables INTEGER, number_of_columns INTEGER ARRAY, array_of_files TEXT ARRAY, table_name_less_date TEXT ARRAY, array_of_csv TEXT ARRAY) FROM dwdev, dba, airflow, postgres, pgbouncer; -- remove access to etl_setup function for all users
GRANT EXECUTE ON PROCEDURE preprocess.etl_setup(no_tables INTEGER, number_of_columns INTEGER ARRAY, array_of_files TEXT ARRAY, table_name_less_date TEXT ARRAY, array_of_csv TEXT ARRAY) TO dbdev, postgres;

REVOKE ALL ON PROCEDURE preprocess.copy_expert(table_name TEXT, csv_path VARCHAR(110), column_count INTEGER, table_name_less_date VARCHAR(30)) FROM dwdev, dbdev, airflow, postgres, pgbouncer; -- remove access to copy_expert function for all users
GRANT EXECUTE ON PROCEDURE preprocess.copy_expert(table_name TEXT, csv_path VARCHAR(110), column_count INTEGER, table_name_less_date VARCHAR(30)) TO dbdev, postgres;
