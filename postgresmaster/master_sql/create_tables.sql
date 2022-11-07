-- CREATING DOMAINS
BEGIN;
CREATE DOMAIN race_positions AS INTEGER
    CHECK(
         (0 < VALUE) AND (VALUE <= 20)
    );
CREATE DOMAIN win_format AS INTEGER
    CHECK(
        (0 < VALUE) AND (VALUE <= 20)
    );

SAVEPOINT first_category;

CREATE DOMAIN time_delta AS TEXT
    CHECK(
        (VALUE ~ '^[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9].*$') IS true
    AND (VALUE ~ '^[^0-9].*$') IS false
    AND (LENGTH(VALUE) > 12) IS false
    );
CREATE DOMAIN letter_format AS TEXT
    CHECK(
        (VALUE ~ '^[^a-zA-Z].*$') IS false
    AND (LENGTH(VALUE) BETWEEN 0 AND 25)  IS true
    );
CREATE DOMAIN name_format AS TEXT
    CHECK(
        (VALUE ~ '^[^a-zA-Z].*$') IS false
        );
CREATE DOMAIN only_letters AS TEXT
    CHECK(
        (VALUE ~ '^[^a-zA-Z].*$') IS false
    AND (LENGTH(VALUE) > 20) IS false
        );

SAVEPOINT second_category;

CREATE DOMAIN only_numbers AS INTEGER
    CHECK(
        (0 <= VALUE) AND (VALUE < 21)
    );
CREATE DOMAIN pos_format AS INTEGER
    CHECK(
        (0 <= VALUE) AND (VALUE < 20)
    );
COMMIT;

-- CREATING BASE TABLES 

CREATE TABLE IF NOT EXISTS fps.grid(
    grid_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    race_result_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    finishing_pos race_positions NOT NULL,
    pos_change pos_format NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.grid IS 'A table representing the grid of drivers for a race';
COMMENT ON COLUMN fps.grid.finishing_pos IS 'A variable for the finishing position ofthe driver';
COMMENT ON COLUMN fps.grid.pos_change IS 'A variable for the net position change of the driver from start to the end of the race';
COMMENT ON COLUMN fps.grid.created_at IS 'A variable which is used to audit tables during the etl process';
COMMENT ON COLUMN fps.grid.updated_on IS 'A variable which is used to audit updates to the table during batch loads.';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.driver(
    driver_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    team_id INTEGER NOT NULL,
    forename name_format NOT NULL,
    surname name_format NOT NULL CHECK(surname != forename),
    date_of_birth VARCHAR(15) NOT NULL,
    nationality name_format NOT NULL, 
    car_no VARCHAR(2) NOT NULL CHECK (LENGTH(car_no) < 3),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.driver IS 'A table which contains all details on drivers that were seated during the season';
COMMENT ON COLUMN fps.driver.forename IS 'An attribute for drivers first name';
COMMENT ON COLUMN fps.driver.surname IS 'An attribute for drivers last name';
COMMENT ON COLUMN fps.driver.date_of_birth IS 'An attribute for drivers date of birth';
COMMENT ON COLUMN fps.driver.nationality IS 'An attribute for drivers nationality';
COMMENT ON COLUMN fps.driver.car_no IS 'An attribute for drivers car number identifier';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.race_result(
    race_result_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    race_id INTEGER NOT NULL,
    season_year INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    lap_no INTEGER NOT NULL,
    fastest_lap time_delta NOT NULL,
    points FLOAT NOT NULL DEFAULT 0 CHECK ((0 <= points) AND (points < 26)),
    gap_to_lead time_delta NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.race_result IS 'A table which contains all the details about a race result';
COMMENT ON COLUMN fps.race_result.fastest_lap IS 'An attribute that represents the fastest lap of the race for a driver';
COMMENT ON COLUMN fps.race_result.points IS 'An attribute that shows the points scored by a driver';
COMMENT ON COLUMN fps.race_result.gap_to_lead IS 'An attribute that shows how far a driver finished off the lead in seconds at the end of a race';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.weather(
    weather_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    race_id INTEGER NOT NULL,
    season_year CHAR(4) NOT NULL,
    occur_of_rain_race BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.weather IS 'A table which contains all details about a championship';
COMMENT ON COLUMN fps.weather.occur_of_rain_race IS 'Whether it rained during the race';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.qualifying(
    qualifying_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    race_id INTEGER NOT NULL,
    event_id INTEGER NOT NULL,
    season_year CHAR(4) NOT NULL,
    weather_id INTEGER NOT NULL,
    best_q1 time_delta NOT NULL,
    best_q2 time_delta NOT NULL,
    best_q3 time_delta NOT NULL,
    quali_pos race_positions NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.qualifying IS 'A table containing all details surrounding qualifying for a sunday race';
COMMENT ON COLUMN fps.qualifying.best_q1 IS 'best time by a driver in q1';
COMMENT ON COLUMN fps.qualifying.best_q2 IS 'best time achieved by a driver in q2';
COMMENT ON COLUMN fps.qualifying.best_q3 IS 'best time achieved by a driver in q3';
COMMENT ON COLUMN fps.qualifying.quali_pos IS 'the final position of the driver in qualifying';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.team(
    team_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name_of_team letter_format NOT NULL,
    nationality letter_format NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.team IS 'a table about each team competing for the championship';
COMMENT ON COLUMN fps.team.name_of_team IS 'the name of the team';
COMMENT ON COLUMN fps.team.nationality IS 'the nationality of the team';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.status(
    status_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_status_update letter_format NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.status IS 'a table for status updates';
COMMENT ON COLUMN fps.status.driver_status_update IS 'details how the driver finished the race';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.season(
    season_year CHAR(4) NOT NULL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.season IS 'a table representing a season of racing';
COMMENT ON COLUMN fps.season.season_year IS 'a natural key for the year the season was held in which is alsi used as the primary key';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.race(
    race_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    team_id INTEGER NOT NULL,
    event_id INTEGER NOT NULL,
    season_year CHAR(4) NOT NULL,
    race_round INTEGER NOT NULL CHECK ((0 < race_round) AND (race_round <= 24)),
    race_name VARCHAR(25) NOT NULL,
    race_date DATE NOT NULL,
    race_time CHAR(8) NOT NULL,
    quali_date DATE NOT NULL,
    quali_time VARCHAR(12) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.race IS 'a table containing information about races';
COMMENT ON COLUMN fps.race.race_round IS 'the round of the championship this race represents';
COMMENT ON COLUMN fps.race.race_date IS 'the date the race was held on';
COMMENT ON COLUMN fps.race.race_time IS 'the time the race was held at';
COMMENT ON COLUMN fps.race.quali_date IS 'date qualifying was held on';
COMMENT ON COLUMN fps.race.quali_time IS 'time qualifying was held at';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.event(
    event_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_name only_letters NOT NULL,
    country only_letters NOT NULL,
    city only_letters NOT NULL,
    track_name VARCHAR(25) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.event IS 'a table containing information about all the event that host races and qualifying sessions.';
COMMENT ON COLUMN fps.event.event_name IS 'the name of the event ';
COMMENT ON COLUMN fps.event.country IS 'the country of the event';
COMMENT ON COLUMN fps.event.city IS 'the city the event is held in';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.pit(
    race_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_id INTEGER NOT NULL,
    no_pitstop INTEGER NOT NULL,
    season_year CHAR(4) NOT NULL,
    lap_no INTEGER NOT NULL DEFAULT 0 CHECK(lap_no < 85),
    time_in TIME NOT NULL,
    time_out TIME NOT NULL,
    pit_duration VARCHAR(12) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

BEGIN;
COMMENT ON TABLE fps.pit IS 'a table containing all of the pitstop information about a driver during a race';
COMMENT ON COLUMN fps.pit.lap_no IS 'the lap of the race at the time of pitstop';
COMMENT ON COLUMN fps.pit.time_in IS 'time entered the pits';
COMMENT ON COLUMN fps.pit.time_out IS 'time exited the pits';
COMMENT ON COLUMN fps.pit.pit_duration IS 'the total pit in the pits';
COMMENT ON COLUMN fps.pit.no_pitstop IS 'number of pitstops taken by driver';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.race_telemetry(
    race_id INTEGER GENERATED ALWAYS AS IDENTITY,
    driver_id INTEGER NOT NULL,
    lap_no INTEGER NOT NULL DEFAULT 0 CHECK(lap_no < 85),
    season_year CHAR(4) NOT NULL,
    speed INTEGER NOT NULL DEFAULT 0 CHECK((0 <= speed) AND (speed < 300)),
    gear_number INTEGER NOT NULL DEFAULT 0 CHECK((0 <= gear_number) AND (gear_number <= 100)),
    throttle_pressure INTEGER NOT NULL DEFAULT 0 CHECK((0 <= throttle_pressure) AND (throttle_pressure <= 100)),
    revs_per_min INTEGER NOT NULL DEFAULT 0 CHECK((0 <= revs_per_min) AND (revs_per_min <= 20000)),
    brake_trace INTEGER NOT NULL DEFAULT 0 CHECK((0 <= brake_trace) AND (brake_trace <=100)),
    compound VARCHAR(10) NOT NULL CHECK((compound ~ '[^a-zA-Z]') is false),
    tyre_life INTEGER NOT NULL DEFAULT 0,
    stint_number INTEGER NOT NULL DEFAULT 0, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT racetelem_pk 
        UNIQUE(race_id, driver_id, lap_no)
);

BEGIN;
COMMENT ON TABLE fps.race_telemetry IS 'a table containing all of the driver telemetry readings produced over a lap';
COMMENT ON COLUMN fps.race_telemetry.speed IS 'speed driven by the driver';
COMMENT ON COLUMN fps.race_telemetry.gear_number IS 'gear selected by the driver';
COMMENT ON COLUMN fps.race_telemetry.throttle_pressure IS 'amount of throttle pressure applied by driver';
COMMENT ON COLUMN fps.race_telemetry.revs_per_min IS 'revs per minute of the engine';
COMMENT ON COLUMN fps.race_telemetry.brake_trace IS 'brake pressure applied by the driver';
COMMENT ON COLUMN fps.race_telemetry.compound IS 'the current tyre compound used by the driver';
COMMENT ON COLUMN fps.race_telemetry.tyre_life IS 'the current age of the drivers tyres in laps';
COMMENT ON COLUMN fps.race_telemetry.stint_number IS 'the current driving stint of the driver';
COMMIT;

-- CREATING JOINING TABLES 

CREATE TABLE IF NOT EXISTS fps.driver_result(
    driver_id INTEGER NOT NULL,
    race_result_id INTEGER NOT NULL,
    CONSTRAINT fk_driverresult_driver_id
        FOREIGN KEY (driver_id)
        REFERENCES fps.driver(driver_id) 
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT fk_driverresult_rr_id
        FOREIGN KEY (race_result_id)
        REFERENCES fps.race_result(race_result_id) 
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

BEGIN;
-- creating index on driveresult 
CREATE INDEX IF NOT EXISTS fk_driverresult_idx ON fps.driver_result USING btree (driver_id, race_result_id);
COMMENT ON TABLE fps.driver_result IS 'a joining table which is used to manage the many to many relationship betweem driver and race_result';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.driver_qualifying(
    driver_id INTEGER NOT NULL,
    qualifying_id INTEGER NOT NULL,
    CONSTRAINT fk_driverqualifying_driver_id
        FOREIGN KEY (driver_id)
        REFERENCES fps.driver(driver_id) 
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT fk_driverqualifying_qualifying_id
        FOREIGN KEY (qualifying_id)
        REFERENCES fps.qualifying(qualifying_id) 
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

BEGIN;
--creating index on driverqualifying
CREATE INDEX IF NOT EXISTS fk_driverqualifying_idx ON fps.driver_qualifying USING btree (driver_id, qualifying_id);
COMMENT ON TABLE fps.driver_qualifying IS 'a joining table which is used to manage the many to many relationship betweem qualifying and driver';
COMMIT;

CREATE TABLE IF NOT EXISTS fps.race_team(
    race_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,
    CONSTRAINT fk_raceteam_driver_id
        FOREIGN KEY (race_id)
        REFERENCES fps.race(race_id) 
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT fk_raceteam_team_id
        FOREIGN KEY (team_id)
        REFERENCES fps.team(team_id) 
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

BEGIN;
-- create index on race_team
CREATE INDEX IF NOT EXISTS fk_raceteam_idx ON fps.race_team USING btree (race_id, team_id);
COMMENT ON TABLE fps.race_team IS 'a joining table which is used to manage the many to many relationship betweem race and team';
COMMIT;

-- creating foreign key constraints for base tables
BEGIN;
-- race_result table
ALTER TABLE fps.grid
ADD CONSTRAINT fk_grid_race_result_id
    FOREIGN KEY (race_result_id) 
    REFERENCES fps.race_result(race_result_id) 
    ON DELETE NO ACTION 
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_grid_driver_id
    FOREIGN KEY (driver_id) 
    REFERENCES fps.driver(driver_id) 
    ON DELETE NO ACTION 
    ON UPDATE CASCADE;

--driver table 
ALTER TABLE fps.driver
ADD CONSTRAINT fk_driver_team_id
    FOREIGN KEY (team_id)
    REFERENCES fps.team(team_id) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE;

--weather table 
ALTER TABLE fps.weather
ADD CONSTRAINT fk_weather_race_id
    FOREIGN KEY (race_id)
    REFERENCES fps.race(race_id) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_weather_season_id
    FOREIGN KEY (season_year)
    REFERENCES fps.season(season_year) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
    
--race table
ALTER TABLE fps.race_result
ADD CONSTRAINT fk_race_result_race_id
    FOREIGN KEY (race_id)
    REFERENCES fps.race(race_id) 
    ON DELETE NO ACTION 
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_race_result_status_id
    FOREIGN KEY (status_id)
    REFERENCES fps.status(status_id) 
    ON DELETE NO ACTION 
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_race_result_team_id
    FOREIGN KEY (team_id)
    REFERENCES fps.team(team_id) 
    ON DELETE NO ACTION 
    ON UPDATE CASCADE;

--qualifying table
ALTER TABLE fps.qualifying
ADD CONSTRAINT fk_qualifying_race_id
    FOREIGN KEY (race_id)
    REFERENCES fps.race(race_id) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_qualifying_season_year
    FOREIGN KEY (season_year)
    REFERENCES fps.season(season_year) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_qualifying_weather_id
    FOREIGN KEY (weather_id)
    REFERENCES fps.weather(weather_id) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE;

--race table 
ALTER TABLE fps.race 
ADD CONSTRAINT fk_race_team_id
    FOREIGN KEY (team_id)
    REFERENCES fps.team(team_id) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_race_season_year
    FOREIGN KEY (season_year)
    REFERENCES fps.season(season_year) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_race_event_id
    FOREIGN KEY (event_id)
    REFERENCES fps.event(event_id) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE;

--pit table
ALTER TABLE fps.pit
ADD CONSTRAINT fk_pit_season
    FOREIGN KEY (season_year)
    REFERENCES fps.season(season_year) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_pit_race
    FOREIGN KEY (race_id)
    REFERENCES fps.race(race_id) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE;


--driver telemetry table
ALTER TABLE fps.race_telemetry
ADD CONSTRAINT fk_racetelem_race_id
    FOREIGN KEY (race_id)
    REFERENCES fps.race(race_id) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
ADD CONSTRAINT fk_racetelem_season_year
    FOREIGN KEY (season_year)
    REFERENCES fps.season(season_year) 
    ON DELETE NO ACTION
    ON UPDATE CASCADE;

-- creating indexes 

-- grid table
CREATE INDEX IF NOT EXISTS fk__rrd_idx ON fps.grid USING btree (grid_id, driver_id);

-- driver table
CREATE INDEX IF NOT EXISTS fk_dteam_idx ON fps.driver USING btree (team_id);

-- race_result table
CREATE INDEX IF NOT EXISTS fk_rrrace_idx ON fps.race_result USING btree (race_id);
CREATE INDEX IF NOT EXISTS fk_rrstatus_idx ON fps.race_result USING btree (status_id);
CREATE INDEX IF NOT EXISTS fk_rrteam_idx ON fps.race_result USING btree (team_id);
CREATE INDEX IF NOT EXISTS fk_rrdrivertelem_idx ON fps.race_result USING btree (driver_id, lap_no);

--qualifying table 
CREATE INDEX IF NOT EXISTS fk_qevent_idx ON fps.qualifying USING btree (event_id);
CREATE INDEX IF NOT EXISTS fk_qweather_idx ON fps.qualifying USING btree (weather_id);

-- race table 
CREATE INDEX IF NOT EXISTS fk_rteam_idx ON fps.race USING btree (team_id);
CREATE INDEX IF NOT EXISTS fk_rseason_idx ON fps.race USING btree (season_year);
CREATE INDEX IF NOT EXISTS fk_revent_idx ON fps.race USING btree (event_id);

-- pit table 
CREATE INDEX IF NOT EXISTS fk_prace_idx ON fps.pit USING btree (race_id);
CREATE INDEX IF NOT EXISTS fk_pdriver_idx ON fps.pit USING btree (driver_id);

-- race telemetry table 
CREATE INDEX IF NOT EXISTS fk_rtrace_idx ON fps.race_telemetry USING btree (race_id, driver_id, season_year);

