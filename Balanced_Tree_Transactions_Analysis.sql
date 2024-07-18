USE balanced_tree;

-- No of unique transactions
SELECT COUNT(DISTINCT transaction_id) AS unique_txns
FROM balanced_tree.sales;

-- Average unique products purchased in each transaction
SELECT ROUND(AVG(unique_products),2) AS average_products_purchased 
FROM (SELECT transaction_id, 
			 COUNT(DISTINCT product_id) AS unique_products
		FROM balanced_tree.sales
		GROUP BY transaction_id
) AS unique_products_per_txn;

-- 25th, 50th and 75th percentile values for the revenue per transaction
WITH revenue_per_txn AS (
		SELECT transaction_id, 
			   SUM(quantity * price) AS revenue
		FROM balanced_tree.sales
		GROUP BY transaction_id
),
ordered_revenues AS (
    SELECT revenue,
           NTILE(4) OVER (ORDER BY revenue) AS quartile
    FROM revenue_per_txn
)
SELECT
    MAX(CASE WHEN quartile = 1 THEN revenue END) AS 25th_percentile,
    MAX(CASE WHEN quartile = 2 THEN revenue END) AS 50th_percentile,
    MAX(CASE WHEN quartile = 3 THEN revenue END) AS 75th_percentile
FROM ordered_revenues;

-- Average discount value per transaction
SELECT ROUND(AVG(total_discount),2) AS average_discount_value
FROM (SELECT transaction_id, 
				SUM(discount) AS total_discount
		FROM balanced_tree.sales
		GROUP BY transaction_id
) AS discount_per_txn;

-- Percentage split of all transactions for members vs non-members
WITH transaction_members AS (
		SELECT 
			DISTINCT(transaction_id),
			member_status
		FROM balanced_tree.sales
)
SELECT 
	COUNT(CASE WHEN member_status = 1 THEN 1 END) AS members_txn,
	COUNT(CASE WHEN member_status = 0 THEN 1 END) AS non_members_txn,
	(COUNT(CASE WHEN member_status = 1 THEN 1 END) / (SELECT COUNT(DISTINCT transaction_id) FROM balanced_tree.sales)) * 100 AS members_prcnt,
	(COUNT(CASE WHEN member_status = 0 THEN 1 END) / (SELECT COUNT(DISTINCT transaction_id) FROM balanced_tree.sales)) * 100 AS non_members_prcnt
FROM transaction_members;

-- Average revenue for member transactions and non-member transactions
WITH revenue_per_member AS (
		SELECT 
			DISTINCT(transaction_id),
			member_status,
			SUM(quantity * price) AS revenue
		FROM balanced_tree.sales
		GROUP BY transaction_id, member_status
)
SELECT 
	ROUND(AVG(CASE WHEN member_status = 1 THEN revenue END),2) AS avg_revenue_members,
	ROUND(AVG(CASE WHEN member_status = 0 THEN revenue END),2) AS avg_revenue_non_members
FROM revenue_per_member;
