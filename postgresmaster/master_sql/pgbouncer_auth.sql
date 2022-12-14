-- reference postgresql high availability cookbook page 175: pgbouncer authentication
CREATE OR REPLACE FUNCTION pgbouncer.user_auth(in p_username TEXT) 
RETURNS TABLE(username TEXT, password TEXT) AS 
$$
BEGIN
    RAISE NOTICE '[PGBOUNCER] Authentication request: %', p_username;
    RETURN QUERY
    SELECT usename::TEXT, passwd::TEXT
        FROM pg_catalog.pg_shadow
    WHERE usename = p_username;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION pgbouncer.user_auth(p_username TEXT) FROM dwdev, dbdev, dba, airflow, postgres; -- remove access to pgbouncer function for all users
GRANT EXECUTE ON FUNCTION pgbouncer.user_auth(p_username TEXT) TO pgbouncer;
