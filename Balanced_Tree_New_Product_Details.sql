-- Create the new_product_details table if it doesn't exist
CREATE TABLE IF NOT EXISTS new_product_details (
    product_id VARCHAR(20),
    product_name VARCHAR(50),
    category_name VARCHAR(20),
    segment_name VARCHAR(20),
    price INT
);

-- Insert data into the new_product_details table
INSERT INTO new_product_details (product_id, product_name, category_name, segment_name, price)
WITH RECURSIVE new_hierarchy_CTE AS (
   SELECT 
        ph.id,
        ph.parent_id,
        ph.level_text AS product_name,
        CASE WHEN ph.level_name = 'Category' THEN ph.level_text ELSE NULL END AS category_name,
        CASE WHEN ph.level_name = 'Segment' THEN ph.level_text ELSE NULL END AS segment_name,
        ph.level_name,
        pp.price,
        pp.product_id,
        ph.id AS root_id
    FROM product_hierarchy ph
    LEFT JOIN product_prices pp 
			ON pp.id = ph.id
	UNION ALL
    SELECT 
			ph.id,
			ph.parent_id,
			ph.level_text AS product_name,
			CASE 
				WHEN ph.level_name = 'Category' THEN ph.level_text
				WHEN ph.level_name = 'Segment' THEN (
					SELECT level_text
					FROM product_hierarchy AS ph_segment
					WHERE ph_segment.id = ph.parent_id
				)
				WHEN ph.level_name = 'Style' THEN (
					SELECT parent_ph.level_text 
					FROM product_hierarchy AS parent_ph 
					WHERE parent_ph.id = (
						SELECT ph_segment.parent_id
						FROM product_hierarchy AS ph_segment
						WHERE ph_segment.id = ph.parent_id
					)
				)
			END AS category_name,
			CASE 
				WHEN ph.level_name = 'Segment' THEN ph.level_text
				WHEN hc.segment_name IS NOT NULL THEN hc.segment_name
				ELSE NULL
			END AS segment_name,
			ph.level_name,
            pp.price,
            pp.product_id,
			hc.root_id
		FROM product_hierarchy ph
		JOIN new_hierarchy_cte hc 
			ON ph.parent_id = hc.id
		LEFT JOIN product_prices pp 
			ON pp.id = ph.id
		
)
SELECT 
    DISTINCT product_id,
    CONCAT(product_name, " ", segment_name, " - ", category_name) AS product_name,
    category_name,
    segment_name,
    price
FROM new_hierarchy_CTE 
WHERE product_id IS NOT NULL AND
      category_name IS NOT NULL
;

-- View the new_product_details table
SELECT *
FROM new_product_details;

