-- there is no container that is neither on a ship nor in a yard
CREATE OR REPLACE FUNCTION verify_container_is_stored()
RETURNS TRIGGER
AS
$$
BEGIN
	
	IF NOT EXISTS (SELECT * FROM stored_at s WHERE s.iso_6346 = NEW.iso_6346) OR EXISTS (SELECT * FROM loaded_on loaded where loaded.iso_6346 = NEW.iso_6346) THEN
		RAISE EXCEPTION 'Ccontainer is neither on a ship nor in a yard';
	END IF;

END;
$$
LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER on_insert_container
AFTER INSERT ON container -- delete or update on container will not threaten illegal state; only insert
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();