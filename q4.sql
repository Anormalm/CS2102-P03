-- A container in a yard is either on the ground or on top of another container
-- insert container check if tier = ground or exists container with tier-1
-- delete container check if not exists container with tier + 1
-- update container check if tier = ground or exists container with tier - 1 and if not exists container with tier + 1

CREATE OR REPLACE FUNCTION verify_consecutive_containers()
RETURNS TRIGGER AS
$$
BEGIN
	IF TG_OP = 'INSERT' THEN
		IF NEW.tier <> 1 AND NOT EXISTS (SELECT * FROM stored_at s WHERE s.tier = NEW.tier - 1) THEN   --Lifan: should add yard, bay, row check or the tier = tier -1 comparison can accept a different stack same tier.
			RAISE EXCEPTION 'Container in a yard must either be on the ground or on top of another container';
		END IF;

	ELSEIF (TG_OP = 'DELETE') THEN
		IF EXISTS (SELECT * FROM stored_at s WHERE s.tier = OLD.tier + 1) THEN
			RAISE EXCEPTION 'Container in a yard must support a container on top of it, if there exists one such container';
		END IF;

	ELSE
		IF (NEW.tier <> 1 AND NOT EXISTS (SELECT * FROM stored_at s WHERE s.tier = NEW.tier - 1)) OR EXISTS(SELECT * FROM stored_at s WHERE s.tier = OLD.tier + 1) THEN
			RAISE EXCEPTION 'Container in a yard must either be on the ground or on top of another container, and must support a container on top of it, if there exists one such container';
		END IF;

	END IF;

	RETURN NULL;
END;
$$
LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER on_stored_at_loc_modifed
AFTER INSERT OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_consecutive_containers();

--Lifan: i havent tested but can DEFERRED and NEW OLD coexist, im kinda confused.
