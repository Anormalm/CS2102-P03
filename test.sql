-- Setup basic valid reference data for testing
INSERT INTO country (name, continent) VALUES ('GB', 'EUROPE');
INSERT INTO city (name, country_name) VALUES ('London', 'GB');
INSERT INTO company (company_code, name, address, postal_code, city_name, country_name) 
VALUES ('TST', 'TEST LTD', '123 St', '12345', 'London', 'GB');

INSERT INTO category (category_type, max_tier) VALUES ('Simple', 3);
INSERT INTO yard (code, category_type) VALUES ('NO1', 'Simple');
INSERT INTO position (bay, row, tier, code) VALUES 
(1, 1, 1, 'NO1'),
(1, 1, 2, 'NO1'),
(1, 1, 3, 'NO1');

INSERT INTO category (category_type, max_tier) VALUES ('Mini', 2);
INSERT INTO yard (code, category_type) VALUES ('NO2', 'Mini');
INSERT INTO position (bay, row, tier, code) VALUES 
(1, 1, 1, 'NO2'),
(1, 1, 2, 'NO2');

INSERT INTO berth (longitude, latitude, code) VALUES (103.8, 1.3, 'B1');
INSERT INTO ship (mmsi, imo_number, call_sign, name, width, length, berth_code) 
VALUES ('123456789', 'IMO123', 'CALL1', 'TestShip', 20.0, 100.0, 'B1');

--------------------------------------------------------------------------------
-- TEST 1: Container cannot be neither on a ship or in a yard
--------------------------------------------------------------------------------

-- Container with NEITHER ship nor yard should FAIL
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
END $$;

-- Inserting container and storing at a yard should SUCCEED
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
END $$;

-- Deleting from a yard without deleting the container should FAIL
DO $$
BEGIN
    DELETE FROM stored_at WHERE iso_6346 = 'TST1234567';
END $$;

-- Deleting from a yard and container should SUCCEED
DO $$
BEGIN
    DELETE FROM stored_at WHERE iso_6346 = 'TST1234567';
    DELETE FROM container WHERE iso_6346 = 'TST1234567';
END $$;

-- Inserting container and loading on ship should SUCCEED
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('TST1234567', '123456789');
END $$;

-- Deleting from a ship without deleting the container should FAIL
DO $$
BEGIN
    DELETE FROM loaded_on WHERE iso_6346 = 'TST1234567';
END $$;

-- Deleting from a ship and container should SUCCEED
DO $$
BEGIN
    DELETE FROM loaded_on WHERE iso_6346 = 'TST1234567';
    DELETE FROM container WHERE iso_6346 = 'TST1234567';
END $$;

-- Setup by storing at a yard first
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
END $$;
-- then transfering to a ship should SUCCEED
DO $$
BEGIN
    DELETE FROM stored_at WHERE iso_6346 = 'TST1234567';
	INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('TST1234567', '123456789');
END $$;
-- transferring back to a yard should SUCCEED
DO $$
BEGIN
    DELETE FROM loaded_on WHERE iso_6346 = 'TST1234567';
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
END $$;

-- Deleting the container should SUCCEED
DO $$
BEGIN
    DELETE FROM container WHERE iso_6346 = 'TST1234567';
END $$;

-- Setup by storing at a yard first
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
END $$;
-- Updating a iso at a yard without handling the old container should FAIL
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654321', 'Electronics', 'TST');
	UPDATE stored_at SET iso_6346 = 'TST7654321' WHERE iso_6346 = 'TST1234567';
END $$;

-- Updating a iso at a yard and deleting the container should SUCCEED
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654321', 'Electronics', 'TST');
	UPDATE stored_at SET iso_6346 = 'TST7654321' WHERE iso_6346 = 'TST1234567';
    DELETE FROM container WHERE iso_6346 = 'TST1234567';
END $$;

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Setup by storing at a yard first
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
END $$;
-- Updating a iso at a yard and moving the old container should SUCCEED
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654321', 'Electronics', 'TST');
	UPDATE stored_at SET iso_6346 = 'TST7654321' WHERE iso_6346 = 'TST1234567';
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 2, 'NO1');
END $$;

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Setup by loading on a ship first
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('TST1234567', '123456789');
END $$;
-- Updating a iso at a ship without handling the old container should FAIL
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654321', 'Electronics', 'TST');
	UPDATE loaded_on SET iso_6346 = 'TST7654321' WHERE iso_6346 = 'TST1234567';
END $$;

-- Updating a iso at a ship and deleting the container should SUCCEED
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654321', 'Electronics', 'TST');
	UPDATE loaded_on SET iso_6346 = 'TST7654321' WHERE iso_6346 = 'TST1234567';
    DELETE FROM container WHERE iso_6346 = 'TST1234567';
END $$;

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Setup by loading on a ship first
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('TST1234567', '123456789');
END $$;
-- Updating a iso at a yard and moving the old container should SUCCEED
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654321', 'Electronics', 'TST');
	UPDATE loaded_on SET iso_6346 = 'TST7654321' WHERE iso_6346 = 'TST1234567';
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 2, 'NO1');
END $$;







--------------------------------------------------------------------------------
-- TEST 2: Container cannot be both on a ship and in a yard
--------------------------------------------------------------------------------
-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Trying to load on ship and store at yard at the same time should FAIL
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('TST1234567', '123456789');
END $$;

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Setup by storing at a yard first
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
END $$;
-- Loading on a ship should FAIL
DO $$
BEGIN
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('TST1234567', '123456789');
END $$;

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Setup by loading on a ship first
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
    INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('TST1234567', '123456789');
END $$;
-- Storing at a yard should FAIL
DO $$
BEGIN
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
END $$;

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Setup by storing a container at a yard and a ship
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654321', 'Electronics', 'TST');
	INSERT INTO loaded_on (iso_6346, mmsi) 
    VALUES ('TST7654321', '123456789');
END $$;
-- Deleting the container at the ship and updating the other container to also to load on the ship should fail 
DO $$
BEGIN
    UPDATE loaded_on SET iso_6346 = 'TST1234567' WHERE iso_6346 = 'TST7654321';
    DELETE FROM container WHERE iso_6346 = 'TST7654321';
END $$;
-- Deleting the container at the yard and updating the other container to also to be stored at the yard should fail 
DO $$
BEGIN
    UPDATE stored_at SET iso_6346 = 'TST7654321' WHERE iso_6346 = 'TST1234567';
    DELETE FROM container WHERE iso_6346 = 'TST1234567';
END $$;


--------------------------------------------------------------------------------
-- TEST 3: Container cannot be stacked higher than the max tier
--------------------------------------------------------------------------------

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Setup by maxing out a yard first
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234565', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234565', 1, 1, 1, 'NO1');
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234566', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234566', 1, 1, 2, 'NO1');
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 3, 'NO1');
END $$;
-- Storing additional container should FAIL
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234568', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234568', 1, 1, 4, 'NO1');
END $$;

-- Maxout other yard
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654321', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST7654321', 1, 1, 1, 'NO2');
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST7654322', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST7654322', 1, 1, 2, 'NO2');
END $$;
-- Update existing container with tier too high to different yard with lower max_tier, should FAIL
DO $$
BEGIN
    UPDATE stored_at SET code = 'NO2' WHERE iso_6346 = 'TST1234568';
END $$;


-- Swap out category for smaller one when maxed out, should FAIL
DO $$
BEGIN
    UPDATE yard SET category_type = 'Mini'
    --DELETE FROM position WHERE code = "NO1" AND tier = "3"
END $$;

-- Delete highest tier element then swap category for smaller one when maxed out, should SUCCEED
DO $$
BEGIN
    DELETE FROM stored_at WHERE iso_6346 = 'TST1234567'
    UPDATE yard SET category_type = 'Mini' WHERE code = 'NO1'
    DELETE FROM position WHERE code = 'NO1' AND tier = 3
END $$;

-- Reset
DO $$
BEGIN
    DELETE FROM container;
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234565', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234565', 1, 1, 1, 'NO1');
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234566', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234566', 1, 1, 2, 'NO1');
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 3, 'NO1');
END $$;
-- Reduce max_tier while yard is full, should FAIL
DO $$
BEGIN
    UPDATE category SET max_tier = 2 WHERE category = 'Simple'
    --DELETE FROM position WHERE code = 'NO1' AND tier = 3
END $$;







--------------------------------------------------------------------------------
-- TEST 4: No "floating" containers (must be on ground or on top of another)
--------------------------------------------------------------------------------

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Try to insert floating container, should FAIL
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 2, 'NO1');
END $$;

-- Reset
DO $$
BEGIN
    DELETE FROM container;
END $$;
-- Stack containers in order, should SUCCEED
DO $$
BEGIN
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234567', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234567', 1, 1, 1, 'NO1');
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234565', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234565', 1, 1, 2, 'NO1');
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234566', 'Electronics', 'TST');
	INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234566', 1, 1, 3, 'NO1');
END $$;

-- Reorder containers, should SUCCEED
DO $$
BEGIN
    SET CONSTRAINTS yard_pos DEFERRED;
    UPDATE stored_at SET bay = 1, row = 1, tier = 1 WHERE iso_6346 = 'TST1234565';
    UPDATE stored_at SET bay = 1, row = 1, tier = 2 WHERE iso_6346 = 'TST1234566';
    UPDATE stored_at SET bay = 1, row = 1, tier = 3 WHERE iso_6346 = 'TST1234567';
END $$;

-- Remove first container, should FAIL
DO $$
BEGIN
    DELETE FROM container WHERE iso_6346 = 'TST1234565';
END $$;

-- Remove middle container, should FAIL
DO $$
BEGIN
    DELETE FROM container WHERE iso_6346 = 'TST1234566';
END $$;

-- Remove middle container but add another container to replace it, should SUCCEED
DO $$
BEGIN
    SET CONSTRAINTS yard_pos DEFERRED;
    DELETE FROM container WHERE iso_6346 = 'TST1234566';
    INSERT INTO container (iso_6346, content, company_code)
	VALUES ('TST1234563', 'Electronics', 'TST');
    INSERT INTO stored_at (iso_6346, bay, row, tier, code) 
    VALUES ('TST1234563', 1, 1, 2, 'NO1');
END $$;

-- Remove top container, should SUCCEED
DO $$
BEGIN
    DELETE FROM container WHERE iso_6346 = 'TST1234567';
END $$;