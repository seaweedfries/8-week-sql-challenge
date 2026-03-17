/* --------------------
   Case Study Questions
   --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_amount
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) as days_visited
FROM dannys_diner.sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH EarliestOrder AS (
	SELECT s.customer_id, MIN(s.order_date) AS earliest_order
	FROM dannys_diner.sales s
	GROUP BY s.customer_id
)
SELECT customer_id, product_name
FROM dannys_diner.sales s1
LEFT JOIN dannys_diner.menu m ON s1.product_id = m.product_id
WHERE (s1.customer_id, s1.order_date) IN (
	SELECT customer_id, earliest_order
    FROM EarliestOrder
)
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT s.product_id, m.product_name, COUNT(order_date) as times_ordered
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY times_ordered DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH CustomerRankings AS (
	SELECT s1.customer_id, s1.product_id, m.product_name, times_ordered_per_product, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY times_ordered_per_product desc) as customer_ranking
	FROM (
		SELECT customer_id, product_id, COUNT(product_id) OVER (PARTITION BY customer_id, product_id) as times_ordered_per_product
		FROM dannys_diner.sales s
	) AS s1
	LEFT JOIN dannys_diner.menu m ON s1.product_id = m.product_id
)
SELECT customer_id, product_name, times_ordered_per_product
FROM CustomerRankings
WHERE customer_ranking = 1
GROUP BY customer_id, product_name, times_ordered_per_product;

-- 6. Which item was purchased first by the customer after they became a member?
WITH FirstOrder AS (
	SELECT customer_id, MIN(order_date) as first_order_date
	FROM (
		SELECT s.customer_id, s.order_date, s.product_id, members.join_date
		FROM dannys_diner.sales s
		LEFT JOIN dannys_diner.members members ON s.customer_id = members.customer_id
		WHERE members.join_date <= s.order_date
	) AS s1
	GROUP BY customer_id
)
SELECT customer_id, order_date, product_name
FROM dannys_diner.sales s1
LEFT JOIN dannys_diner.menu ON s1.product_id = menu.product_id
WHERE (s1.customer_id, s1.order_date) IN (
	SELECT customer_id, first_order_date
    FROM FirstOrder
    );

-- 7. Which item was purchased just before the customer became a member?
WITH LastOrder AS (
	SELECT customer_id, MAX(order_date) AS last_order_date
	FROM (
		SELECT s.customer_id, s.order_date, s.product_id, members.join_date
		FROM dannys_diner.sales s
		LEFT JOIN dannys_diner.members members ON s.customer_id = members.customer_id
		WHERE members.join_date > s.order_date
	) AS s1
	GROUP BY customer_id
)
SELECT customer_id, order_date, product_name
FROM dannys_diner.sales s1
LEFT JOIN dannys_diner.menu ON s1.product_id = menu.product_id
WHERE (s1.customer_id, s1.order_date) IN (
	SELECT customer_id, last_order_date
    FROM LastOrder
    );

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT customer_id, COUNT(price) as total_items, SUM(price) AS total_amount
FROM (
	SELECT s.customer_id, s.order_date, s.product_id, members.join_date, menu.price
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.members members ON s.customer_id = members.customer_id
	LEFT JOIN dannys_diner.menu menu ON s.product_id = menu.product_id
	WHERE members.join_date > s.order_date
    ) AS s1
GROUP BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points) as total_points
FROM (
	SELECT s.customer_id, s.order_date, s.product_id, members.join_date, menu.product_name, menu.price, CASE WHEN s.product_id = 1 THEN menu.price*20 ELSE menu.price*10 END AS points
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.members members ON s.customer_id = members.customer_id
	LEFT JOIN dannys_diner.menu menu ON s.product_id = menu.product_id
	WHERE members.join_date <= s.order_date OR members.join_date IS NULL
) AS s1
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT customer_id, SUM(points) as total_points
FROM (
	SELECT s.customer_id, 
    s.order_date, 
    s.product_id, 
    members.join_date, 
    menu.product_name, 
    menu.price, 
    CASE 
		WHEN DATEDIFF(order_date, join_date) < 7 THEN menu.price*20
		WHEN s.product_id = 1 THEN menu.price*20 
        ELSE menu.price*10 
	END AS points
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.members members ON s.customer_id = members.customer_id
	LEFT JOIN dannys_diner.menu menu ON s.product_id = menu.product_id
	WHERE members.join_date <= s.order_date AND s.order_date <= '2021-01-31'
) AS s1
GROUP BY customer_id;

-- Bonus question: join all the things
USE `dannys_diner`;
CREATE TABLE joinallthings (
  customer_id VARCHAR(1),
  order_date DATE,
  product_name VARCHAR(500),
  price INTEGER,
  `member` VARCHAR(1)
);

INSERT INTO dannys_diner.joinallthings (customer_id, order_date, product_name, price, `member`)
SELECT s.customer_id, s.order_date, menu.product_name, menu.price, CASE WHEN members.join_date <= s.order_date THEN 'Y' ELSE 'N' END AS `member`
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.members members ON s.customer_id = members.customer_id
LEFT JOIN dannys_diner.menu menu ON s.product_id = menu.product_id;

SELECT *
FROM dannys_diner.joinallthings;
    
-- Bonus question: rank all the things
USE `dannys_diner`;
CREATE TABLE rankallthings (
  customer_id VARCHAR(1),
  order_date DATE,
  product_name VARCHAR(500),
  price INTEGER,
  `member` VARCHAR(1),
  ranking INTEGER
);

INSERT INTO dannys_diner.rankallthings (customer_id, order_date, product_name, price, `member`, ranking)
SELECT *, 
	CASE 
		WHEN `member` ='N' THEN NULL 
        ELSE DENSE_RANK() OVER (PARTITION BY customer_id, `member` ORDER BY order_date) 
        END 
	AS ranking
FROM dannys_diner.joinallthings;

SELECT *
FROM dannys_diner.rankallthings;