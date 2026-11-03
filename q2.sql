-- A container must either be on a ship or in a yard (but not both).
-- insertion to container table is logically handled by q1 trigger 
-- however, another violation of this constraint could be insertion, deletion or update of row in (ship) or (yard) 
-- this trigger should check whether if insert into ship whether container cannot exist in yard; if delete from ship container must exist in yard; if update to ship then container iso is affected

CREATE OR REPLACE FUNCTION verify_container_location()
RETURNS TRIGGER
AS
$$
BEGIN
	IF TG_OP = 'INSERT' THEN
	
		IF EXISTS (SELECT * FROM stored_at s WHERE s.iso_6346 = NEW.iso_6346) THEN
			RAISE EXCEPTION 'Container must not be in both ship or yard';
		END IF;
	
	ELSEIF (TG_OP = 'DELETE') THEN
		IF NOT EXISTS (SELECT * FROM stored_at s WHERE s.iso_6346 = NEW.iso_6346) THEN
			RAISE EXCEPTION 'Container must either be on a ship or in a yard';
		END IF;
	
	ELSE -- on update
		IF NEW.iso_6346 <> OLD.iso_6346 AND NOT EXISTS (SELECT * FROM stored_at s WHERE s.iso_6346 = OLD.iso_6346) THEN
			RAISE EXCEPTION 'Container must either be on a ship or in a yard';
		END IF;
		
	END IF;

END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER on_stored_at_modified
AFTER INSERT OR DELETE OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_location();