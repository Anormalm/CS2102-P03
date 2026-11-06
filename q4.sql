-- A container in a yard is either on the ground or on top of another container
-- We just need to check that after the transaction, for every yard, every bay and row must have
-- the maximum tier equal the number of containers in that bay and row. This works because since bay
-- row and code are equal, tiers must be unique.

CREATE OR REPLACE FUNCTION verify_grounded_container()
RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM stored_at s
        GROUP BY s.code, s.bay, s.row
        HAVING MAX(s.tier) <> COUNT(s.tier)
    ) THEN
        RAISE EXCEPTION 'Container in a yard must either be on the ground or on top of another container';
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER stored_at_all_grounded
AFTER INSERT OR UPDATE OR DELETE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_grounded_container();

-- old execution fails because if you swap out a container with a new container at the same spot it will fail
-- old execution also does not check that the yard is the same
