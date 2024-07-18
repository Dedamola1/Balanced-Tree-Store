USE balanced_tree;

-- Total quantity sold for all products
SELECT SUM(quantity) AS total_qty
FROM balanced_tree.sales;

-- Total generated revenue for all products before discounts
SELECT SUM(quantity * price) AS total_revenue 
FROM balanced_tree.sales;

-- Total generated revenue for all products after discounts
SELECT SUM((quantity * price) - discount) AS revenue
FROM balanced_tree.sales;

-- Total discount amount for all products
SELECT SUM(discount) AS total_discount
FROM balanced_tree.sales;

