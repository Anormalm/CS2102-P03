CREATE TABLE category (
	category_type VARCHAR(50) PRIMARY KEY,
	max_tier INTEGER NOT NULL CHECK (max_tier >= 1)
);

CREATE TABLE yard (
	code VARCHAR(50) PRIMARY KEY,
	category_type VARCHAR(50) NOT NULL REFERENCES category(category_type)
);

CREATE TABLE position(
	bay INTEGER CHECK (bay >= 0),
	row INTEGER CHECK (row >= 0),

	-- Tier should be limited to the max_tier of category,
	-- this cannot be enforced without creating a foreign key to a non-minimal primary key
	-- since category_type is the minimal primary key of category.
	tier INTEGER CHECK (tier >= 1),
	code VARCHAR(50) REFERENCES yard(code),
	PRIMARY KEY (bay, row, tier, code)
);

CREATE TABLE country (
	name VARCHAR(100) PRIMARY KEY, 
	continent VARCHAR(15) NOT NULL
);

CREATE TABLE city (
	name VARCHAR(200),
	country_name VARCHAR(60) 
		REFERENCES country (name)
		DEFERRABLE INITIALLY IMMEDIATE,
	
	PRIMARY KEY (name, country_name)
);

CREATE TABLE company (
	company_code VARCHAR(50) PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	address VARCHAR(50) NOT NULL, 
	postal_code VARCHAR(50) NOT NULL,
	city_name VARCHAR(200) NOT NULL,
	country_name VARCHAR(60) NOT NULL,
	
	FOREIGN KEY (city_name, country_name) 
		REFERENCES city (name, country_name)
		DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE berth (
	longitude NUMERIC(8, 5) CHECK (longitude >= -180 AND longitude <=180),
	latitude NUMERIC(8, 5) CHECK (latitude >= -90 AND latitude <=90),
	
	-- The specification describes berth codes as natural numbers,
	-- but the required operations explicitly use codes 'B1' and 'B2'.
	-- VARCHAR is therefore used to support the prescribed operations.
	code VARCHAR(50) PRIMARY KEY,
	
	CONSTRAINT berth_position UNIQUE (longitude, latitude)
);

CREATE TABLE ship (
	mmsi VARCHAR(9) PRIMARY KEY,
	imo_number VARCHAR(10) UNIQUE NOT NULL,
	call_sign VARCHAR(20) UNIQUE NOT NULL,
	name VARCHAR(100) NOT NULL,
	width DECIMAL(8, 2) NOT NULL CHECK (width > 0),
	length DECIMAL(8, 2) NOT NULL CHECK (length > 0),

	-- The dock relationship is represented by berth_code.
	berth_code VARCHAR(50) NOT NULL UNIQUE,
	
	FOREIGN KEY (berth_code) 
		REFERENCES berth (code)
		DEFERRABLE INITIALLY IMMEDIATE
);

-- stored_at and loaded_on are represented directly by nullable
-- foreign keys in container instead of separate relationship tables.
-- This allows the constraint that every container is in exactly one
-- yard position or on exactly one ship to be enforced using CHECK.

CREATE TABLE container (
	iso_6346 VARCHAR(15) PRIMARY KEY, 
	content VARCHAR(50) NOT NULL,
	company_code VARCHAR(50) NOT NULL,

	mmsi VARCHAR(9),
	bay INTEGER,
	row INTEGER,
	tier INTEGER,
	code VARCHAR(50),

	support_tier INTEGER,

	FOREIGN KEY (company_code)
		REFERENCES company (company_code)
		DEFERRABLE INITIALLY IMMEDIATE,

	FOREIGN KEY (mmsi)
		REFERENCES ship (mmsi)
		ON DELETE CASCADE
		DEFERRABLE INITIALLY IMMEDIATE,

	FOREIGN KEY (bay, row, tier, code)
		REFERENCES position (bay, row, tier, code)
		DEFERRABLE INITIALLY IMMEDIATE,
	
	-- Ownership is indicated by the first three letters of the
	-- container's ISO identification.
	CHECK (SUBSTRING(iso_6346 FROM 1 FOR 3) = company_code),
	
	-- A container must be in exactly one location:
	-- either on a ship or at one complete yard position.
	CHECK (
		(
			mmsi IS NOT NULL
			AND bay IS NULL
			AND row IS NULL
			AND tier IS NULL
			AND code IS NULL
		)
		OR
		(
			mmsi IS NULL
			AND bay IS NOT NULL
			AND row IS NOT NULL
			AND tier IS NOT NULL
			AND code IS NOT NULL
		)
	),

	-- At most one container may occupy a yard position.
	-- Containers loaded on ships have NULL position attributes.
	UNIQUE (bay, row, tier, code),

	-- A container above tier 1 must identify the tier immediately below it.
	CHECK (
		(mmsi IS NOT NULL AND support_tier IS NULL)
		OR
		(
			mmsi IS NULL
			AND (
				(tier = 1 AND support_tier IS NULL)
				OR
				(tier > 1 
				 AND support_tier = tier - 1 
				 AND support_tier IS NOT NULL)
			)
		)
	),

	-- The supporting position must be occupied by another container
	-- in the same yard, bay and row, rather than merely existing.
	FOREIGN KEY (bay, row, support_tier, code)
		REFERENCES container (bay, row, tier, code)
		DEFERRABLE INITIALLY IMMEDIATE
);




