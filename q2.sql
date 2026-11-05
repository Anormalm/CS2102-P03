-- A container must either be on a ship or in a yard (but not both).
-- We only need to check that it is not on both stored_at and loaded_on
-- as combined with the trigger from q1 we gurantee that the container is either
-- on a ship or on a yard

CREATE OR REPLACE FUNCTION verify_container_not_both()
RETURNS TRIGGER
AS
$$
BEGIN
    IF EXISTS (SELECT 1 FROM stored_at s WHERE s.iso_6346 = NEW.iso_6346) 
		AND EXISTS (SELECT 1 FROM loaded_on l WHERE l.iso_6346 = NEW.iso_6346) THEN
		RAISE EXCEPTION 'Container % cannot be both on a ship or at a yard', NEW.iso_6346;
	END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER modified_stored_at_not_both
AFTER INSERT OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_not_both();

CREATE CONSTRAINT TRIGGER modified_loaded_on_not_both
AFTER INSERT OR UPDATE ON loaded_on
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_not_both();