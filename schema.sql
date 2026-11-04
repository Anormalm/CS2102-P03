CREATE TABLE category (
	category_type VARCHAR(50) PRIMARY KEY,
	max_tier INTEGER NOT NULL CHECK (max_tier >= 1)
);

CREATE TABLE yard (
	code VARCHAR(50) PRIMARY KEY,
	category_type VARCHAR(50) NOT NULL
	    REFERENCES category(category_type)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE position(
	bay INTEGER CHECK (bay >= 0),
	row INTEGER CHECK (row >= 0),

	-- Tier should be limited to the max_tier of category,
	-- but this cannot be enforced without creating a foreign key to a non-minimal primary key
	-- since category_type is the minimal primary key of category.
	tier INTEGER CHECK (tier >= 1),
	code VARCHAR(50)
	    REFERENCES yard(code)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
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
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
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
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE berth (
	longitude NUMERIC(8, 5) NOT NULL CHECK (longitude >= -180 AND longitude <=180),
	latitude NUMERIC(8, 5) NOT NULL CHECK (latitude >= -90 AND latitude <=90),
	
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
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE
);

-- Unable to enforce that container must be in either ship or yard.
CREATE TABLE container (
	iso_6346 VARCHAR(15) PRIMARY KEY, 
	content VARCHAR(50) NOT NULL,
	
	company_code VARCHAR(50) NOT NULL,	
	
	FOREIGN KEY (company_code)
	    REFERENCES company (company_code)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,

	-- Ownership is indicated by the first three letters of the
	-- container's ISO identification.
	CHECK (SUBSTRING(iso_6346 FROM 1 FOR 3) = company_code)
);

-- Unable to enforce that container cannot be stacked higher than the max tier of the yard,
-- and unable to enforce that a container is either on the ground or on top of another container.
CREATE TABLE stored_at (
	iso_6346 VARCHAR(15) PRIMARY KEY,
	FOREIGN KEY (iso_6346)
	    REFERENCES container (iso_6346)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
	
	bay INTEGER NOT NULL,
	row INTEGER NOT NULL,
	tier INTEGER NOT NULL,
	code VARCHAR(50) NOT NULL,

	FOREIGN KEY (bay, row, tier, code)
	    REFERENCES position (bay, row, tier, code)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
	
	CONSTRAINT yard_pos UNIQUE (bay, row, tier, code)
	
);

CREATE TABLE loaded_on (
	iso_6346 VARCHAR(15) PRIMARY KEY,
	FOREIGN KEY (iso_6346)
	    REFERENCES container (iso_6346)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE,
	
	mmsi VARCHAR(9) NOT NULL,
	
	FOREIGN KEY (mmsi)
	    REFERENCES ship (mmsi)
	    ON UPDATE CASCADE
	    ON DELETE CASCADE
	    DEFERRABLE INITIALLY IMMEDIATE
);




