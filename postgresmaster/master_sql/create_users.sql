-- create users
CREATE OR REPLACE PROCEDURE fps.user_init(pass1 TEXT, pass2 TEXT, pass3 TEXT, pass4 TEXT)
LANGUAGE PLPGSQL
AS $$
DECLARE 
    m TEXT;
    users TEXT[] := ARRAY['dbdev', 'dwdev', 'postgres', 'pgbouncer', 'airflow'];
    x INTEGER := 0;
    pass TEXT;
BEGIN
    FOREACH m IN ARRAY users
    LOOP
    x := x+1;
        IF EXISTS ( 
            SELECT * FROM pg_catalog.pg_roles
            WHERE  rolname = m) THEN
            RAISE NOTICE 'USER % already exists. Progressing to next user...', m;
        ELSE
            CASE x  
                WHEN 1 THEN 
                    -- creating variable for password 
                    SELECT pass1 INTO pass;
                    --create dw developer and alter access privileges, providing passwords for users 
                    EXECUTE FORMAT('CREATE ROLE "dbdev" WITH NOSUPERUSER NOCREATEDB LOGIN CONNECTION LIMIT 30 ENCRYPTED PASSWORD %L', pass);
                    --grant access for select, insert, update on db and create within schema
                    REVOKE ALL PRIVILEGES ON SCHEMA public FROM dbdev;
                    REVOKE ALL PRIVILEGES ON SCHEMA preprocess FROM dbdev;
                    REVOKE ALL PRIVILEGES ON SCHEMA fps FROM dbdev;
                    GRANT USAGE ON SCHEMA fps TO limitedmodaccess;
                    GRANT USAGE ON SCHEMA preprocess TO limitedmodaccess;
                    GRANT CREATE ON SCHEMA preprocess TO limitedmodaccess;
                    GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA fps TO limitedmodaccess;
                    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA preprocess TO limitedmodaccess;
                    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA fps TO dbdev;
                    GRANT USAGE ON SCHEMA preprocess TO dbdev;
                    ALTER ROLE dbdev SET search_path = preprocess; -- set the location for the init db command to be sent to
                    GRANT CONNECT ON DATABASE prod_db TO limitedmodaccess;
                    GRANT limitedmodaccess TO dbdev;
                    ALTER ROLE dbdev SET search_path = preprocess; -- set location for queries
                WHEN 2 THEN
                    -- creating variable for password 
                    SELECT pass2 INTO pass;
                    --create dw developer and alter access privileges, providing passwords for user 
                    EXECUTE FORMAT('CREATE ROLE "dwdev" WITH NOSUPERUSER REPLICATION LOGIN CONNECTION LIMIT 30 NOCREATEDB ENCRYPTED PASSWORD %L', pass);

                    REVOKE ALL PRIVILEGES ON SCHEMA preprocess FROM dwdev;
                    REVOKE ALL PRIVILEGES ON SCHEMA public FROM dwdev;
                    GRANT SELECT ON ALL TABLES IN SCHEMA fps TO readonlyaccess;
                    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonlyaccess;
                    ALTER USER readonlyaccess SET default_transaction_read_only = on;
                    GRANT CONNECT ON DATABASE prod_db TO readonlyaccess;
                    GRANT readonlyaccess TO dwdev;
                    ALTER ROLE dwdev SET search_path = fps; -- set location for queries
                WHEN 3 THEN 
                    --create super user postgres 
                    EXECUTE FORMAT('CREATE ROLE "postgres" SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN NOREPLICATION BYPASSRLS');
                WHEN 4 THEN
                    -- creating variable for password 
                    SELECT pass3 INTO pass;
                    --create pgbouncer and alter access privileges, providing passwords for user
                    EXECUTE FORMAT('CREATE ROLE "pgbouncer" NOSUPERUSER NOCREATEROLE LOGIN NOREPLICATION ENCRYPTED PASSWORD %L', pass);

                    CREATE SCHEMA pgbouncer AUTHORIZATION pgbouncer; -- create schema for pgbouncer authentication query 
                    REVOKE ALL PRIVILEGES ON SCHEMA preprocess FROM pgbouncer;
                    REVOKE ALL PRIVILEGES ON SCHEMA public FROM pgbouncer;
                    REVOKE ALL PRIVILEGES ON SCHEMA fps FROM pgbouncer;
                WHEN 5 THEN
                    -- creating variable for password 
                    SELECT pass4 INTO pass;
                    --create airflow and alter access privileges providing passwords for user
                    EXECUTE FORMAT('CREATE ROLE "airflow" NOSUPERUSER NOCREATEROLE LOGIN NOREPLICATION ENCRYPTED PASSWORD %L', pass);

                    REVOKE ALL PRIVILEGES ON SCHEMA preprocess FROM airflow;
                    REVOKE ALL PRIVILEGES ON SCHEMA public FROM airflow;
                    REVOKE ALL PRIVILEGES ON SCHEMA fps FROM airflow;
                    CREATE SCHEMA airflow AUTHORIZATION airflow;-- airflow schema for task and dag metadata and xcoms
                    ALTER ROLE airflow SET search_path = airflow; -- set the location for the init db command to be sent to
                    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA airflow TO airflow;
                    GRANT USAGE ON SCHEMA airflow TO airflow;
                END CASE;
        END IF;
    END LOOP;
EXCEPTION
    WHEN duplicate_alias THEN
        RAISE NOTICE 'USER % was just created by a concurrent transaction. Error.', m;
END;
$$;

--create replication slot on prod-db
SELECT * FROM pg_create_physical_replication_slot('replication_slot_dwdev');
SELECT pg_reload_conf();
