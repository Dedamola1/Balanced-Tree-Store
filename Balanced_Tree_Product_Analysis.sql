USE balanced_tree;

-- Top 3 products by total revenue before discount'
SELECT p.product_name AS product,
		SUM(s.quantity * s.price) AS revenue
FROM sales s
JOIN product_details p
		ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 3;

-- Total quantity, revenue and discount for each segment
SELECT p.segment_name AS segment,
		SUM(quantity) AS total_quantity,
        SUM(s.quantity * s.price) AS total_revenue,
        SUM(discount) AS total_discount
FROM sales s
JOIN product_details p
		ON p.product_id = s.product_id
GROUP BY p.segment_name;

-- Top selling product for each segment
WITH ranked_products AS (
    SELECT 
        p.segment_name AS segment,
        p.product_name AS product,
        SUM(s.quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY p.segment_name ORDER BY SUM(s.quantity) DESC) AS row_num
    FROM sales s
    JOIN product_details p 
				ON p.product_id = s.product_id
    GROUP BY p.segment_name, p.product_name
)
SELECT 
    segment,
    product,
    total_quantity_sold
FROM ranked_products
WHERE row_num = 1;

-- Total quantity, revenue and discount for each category
SELECT p.category_name AS category,
		SUM(quantity) AS total_quantity,
        SUM(s.quantity * s.price) AS total_revenue,
        SUM(discount) AS total_discount
FROM sales s
JOIN product_details p
		ON p.product_id = s.product_id
GROUP BY p.category_name;

-- Top selling product for each category
WITH ranked_products AS (
    SELECT p.category_name AS category,
			p.product_name AS product,
			SUM(s.quantity) AS total_quantity_sold,
			ROW_NUMBER() OVER (PARTITION BY p.category_name ORDER BY SUM(s.quantity) DESC) AS row_num
    FROM sales s
    JOIN product_details p 
				ON p.product_id = s.product_id
    GROUP BY p.category_name, p.product_name
)
SELECT 
    category,
    product,
    total_quantity_sold
FROM ranked_products
WHERE row_num = 1;

-- Percentage split of revenue by product for each segment
WITH product_revenue AS (
    SELECT p.segment_name,
			p.product_name,
			SUM(s.quantity * s.price) AS revenue,
			ROW_NUMBER() OVER (PARTITION BY p.segment_name ORDER BY SUM(s.quantity * s.price) DESC) AS row_num
    FROM sales s
    JOIN product_details p 
				ON p.product_id = s.product_id
    GROUP BY p.segment_name, p.product_name
),
segment_totals AS (
		SELECT segment_name,
			SUM(revenue) AS total_revenue
		FROM product_revenue
		GROUP BY segment_name
)
SELECT 
    pr.segment_name,
    pr.product_name,
    pr.revenue,
    ROUND((CASE WHEN pr.row_num <= 3 THEN pr.revenue / st.total_revenue * 100 ELSE 0 END),2) AS percentage_split
FROM product_revenue pr
JOIN segment_totals st 
		ON pr.segment_name = st.segment_name;

-- Percentage split of revenue by segment for each category
WITH segment_revenue AS (
			SELECT category_name,
					segment_name,
					SUM(s.quantity * s.price) AS revenue,
					ROW_NUMBER() OVER (PARTITION BY p.category_name ORDER BY SUM(s.quantity * s.price) DESC) AS row_num
			FROM sales s
			JOIN product_details p 
						ON p.product_id = s.product_id
			GROUP BY category_name, segment_name
),
category_totals AS (
		SELECT category_name,
				SUM(revenue) AS total_revenue
		FROM segment_revenue
		GROUP BY category_name
)
SELECT s.category_name,
		s.segment_name,
        s.revenue,
        ROUND((CASE WHEN row_num <= 2 THEN s.revenue / ct.total_revenue * 100 ELSE 0 END),2) AS percentage_split
FROM segment_revenue s
JOIN category_totals ct
		ON ct.category_name = s.category_name;

-- Percentage split of total revenue by category
WITH category_revenue AS (
		SELECT p.category_name,
				SUM(s.quantity * s.price) AS revenue
		FROM sales s
		JOIN product_details p 
					ON p.product_id = s.product_id
		GROUP BY p.category_name
)
SELECT category_name,
		revenue,
        ROUND((revenue / (SELECT SUM(quantity * price) FROM balanced_tree.sales) * 100),2) AS percentage_split
FROM category_revenue;

-- Total transaction “penetration” for each product
WITH product_transactions AS (
			SELECT product_name,
					COUNT(transaction_id) AS transactions
			FROM sales s
			JOIN product_details p 
						ON p.product_id = s.product_id
			GROUP BY product_name
)
SELECT product_name,
		transactions,
		ROUND((transactions / (SELECT COUNT(DISTINCT transaction_id) FROM balanced_tree.sales) * 100),2) AS total_txn_penetration
FROM product_transactions
ORDER BY total_txn_penetration DESC;

