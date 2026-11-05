-- A container in a yard cannot be stacked higher than the maximum tier of that yard.
-- when inserting into stored_at, should check that the new tier is less than or equal to the maximum tier of the matching yard
-- when updating maximum tier of a yard and is an increase, should check that all containers stored in yard are stacked less than or equal to new tier
-- since updates to yard cascades to update trigger to stored_at, can simply add trigger to stored_at  
-- yard changes will cascade to stored_at due to FK rule change, so don't need specific trigger for that 1 table

CREATE OR REPLACE FUNCTION verify_max_tier()
RETURNS TRIGGER AS
$$
BEGIN
	IF EXISTS (SELECT * FROM stored_at s, yard y, category c WHERE s.code = y.code AND y.category_type = c.type AND s.tier > c.max_tier) THEN
		RAISE EXCEPTION 'Container in a yard cannot be in a state where it is stacked higher than the maximum tier of that yard';
	END IF;

	RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER on_stored_at_modified
AFTER INSERT OR UPDATE ON stored_at
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_max_tier();

CREATE CONSTRAINT TRIGGER on_category_updated
AFTER UPDATE ON category
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_max_tier();

--Lifan: 1. imo the triggers need verify on stored_at, category and yard right
