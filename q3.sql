-- A container in a yard cannot be stacked higher than the maximum tier of that yard.

CREATE OR REPLACE FUNCTION verify_max_tiers()
RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM stored_at s
        JOIN yard y ON s.code = y.code
        JOIN category c ON y.category_type = c.category_type
        WHERE s.tier > c.max_tier
    ) THEN
        RAISE EXCEPTION 'Container cannot be stored at a tier higher than the maximum tier allowed for its yard category.';
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_max_tier_stored_at
AFTER INSERT OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_max_tiers();

CREATE CONSTRAINT TRIGGER check_max_tier_yard
AFTER UPDATE ON yard
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_max_tiers();

CREATE CONSTRAINT TRIGGER check_max_tier_category
AFTER UPDATE ON category
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_max_tiers();
