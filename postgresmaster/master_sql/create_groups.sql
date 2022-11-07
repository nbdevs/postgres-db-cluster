-- create group
DO
$do$
DECLARE 
    m TEXT;
    i INTEGER := 0;
    groupings TEXT[] := ARRAY['limitedmodaccess', 'readonlyaccess'];
BEGIN
   FOREACH m IN ARRAY groupings
   LOOP
   i := i+1;
    IF EXISTS ( 
        SELECT FROM pg_group
        WHERE  groname = m) THEN
        RAISE NOTICE 'Group % already exists. Skipping.', m;
    ELSIF NOT EXISTS (
        SELECT FROM pg_group
        WHERE  groname = m) THEN
        CASE i
            WHEN 1 THEN
                CREATE GROUP limitedmodaccess;
            WHEN 2 THEN 
                CREATE GROUP readonlyaccess WITH REPLICATION;
        END CASE;
    END IF;
   END LOOP;
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'Group % was just created by a concurrent transaction. Skipping.', m;
END
$do$;

