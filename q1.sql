-- there is no container that is neither on a ship nor in a yard
CREATE OR REPLACE FUNCTION verify_container_is_stored()
RETURNS TRIGGER
AS
$$
DECLARE
    target_iso VARCHAR(15);
BEGIN
    IF TG_OP = 'INSERT' THEN
        target_iso := NEW.iso_6346;
    ELSE
        target_iso := OLD.iso_6346;
    END IF;


    IF EXISTS (SELECT 1 FROM container c WHERE c.iso_6346 = target_iso) THEN
        IF NOT EXISTS (SELECT 1 FROM stored_at s WHERE s.iso_6346 = target_iso) 
           AND NOT EXISTS (SELECT 1 FROM loaded_on l WHERE l.iso_6346 = target_iso) THEN
            RAISE EXCEPTION 'Container % is neither on a ship nor in a yard', target_iso;
        END IF;
        
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER inserted_container_is_stored
AFTER INSERT ON container
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();

CREATE CONSTRAINT TRIGGER delete_stored_on_is_still_stored
AFTER UPDATE OR DELETE ON stored_at			
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();

CREATE CONSTRAINT TRIGGER delete_loaded_on_is_still_stored
AFTER UPDATE OR DELETE ON loaded_on
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_is_stored();
