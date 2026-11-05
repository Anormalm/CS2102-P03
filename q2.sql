-- A container must either be on a ship or in a yard (but not both).
-- insertion to at least ones is logically handled by q1 trigger 
-- this trigger should check whether if insert into container whether in both places

CREATE OR REPLACE FUNCTION verify_container_not_both()
RETURNS TRIGGER
AS
$$
BEGIN
	IF EXISTS (SELECT * from stored_at s WHERE s.iso_6346 = NEW.iso_6346) AND EXISTS (SELECT * from loaded_on ld WHERE ld.iso_6346 = NEW.iso_6346) THEN
		RAISE EXCEPTION 'Container must not be both on a ship and in a yard'
	END IF;
	RETURN NULL;
	
END;
$$
LANGUAGE plpgsql;


-- when container added, check not both
CREATE CONSTRAINT TRIGGER on_stored_at_modified
AFTER INSERT ON container
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_container_not_both();

--Lifan: 1. we dont need delete in Q2 right, technically when we delete its impossible to cause a container to be on both.
-- 2. is the first part equivalent using a two table JOIN?  or maybe im trippin
-- IF EXISTS (
--     SELECT 1
--     FROM stored_at s, loaded_on l
--     WHERE s.iso_6346 = l.iso_6346
-- ) THEN
--     RAISE EXCEPTION 'Container cannot be both on a ship and in a yard';
-- END IF;
