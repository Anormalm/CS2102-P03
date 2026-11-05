-- there is no container that is neither on a ship nor in a yard
CREATE OR REPLACE FUNCTION verify_container_is_stored()
RETURNS TRIGGER
AS
$$
BEGIN
	
	IF NOT EXISTS (SELECT * FROM stored_at s WHERE s.iso_6346 = NEW.iso_6346) AND NOT EXISTS (SELECT * FROM loaded_on loaded where loaded.iso_6346 = NEW.iso_6346) THEN
		RAISE EXCEPTION 'Container is neither on a ship nor in a yard';
	END IF;

	RETURN NULL;
END;
$$
LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER on_insert_container
AFTER INSERT ON container -- delete or update on container will not threaten illegal state; only insert
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();


--Lifan: Some issues
--1. Deletion and Updating WILL threaten illegal state cuz technically in this case:
-- container - A    stored_at - A  loaded_on - NULL   
-- then we do DELETE FROM stored_at WHERE iso_6346 = 'A';   this will violate cuz A is in neither location but still exist. So its possible to do two separate constraint trigger on loaded and stored
--2. NEW.iso_6346 can just not exist where the container is NULL right.....? we can do a separate var like c in container where c.iso = NEW.iso.
