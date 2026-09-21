CREATE DATABASE company_db;
USE company_db;

CREATE TABLE customers(
customer_id INT,
customer_name VARCHAR(100),
gender VARCHAR(100),
age INT,
city VARCHAR(100),
state VARCHAR(100),
signup_date DATE);

CREATE TABLE orders(
order_id INT,
customer_id INT,
order_date DATE,
product_id INT,
quantity INT,
selling_price DECIMAL,
discount DECIMAL,
payment_method VARCHAR(100),
order_status VARCHAR(100));

CREATE TABLE products( 
product_id INT,
product_name VARCHAR(100),
category VARCHAR(100),
sub_category VARCHAR(100),
cost_price DECIMAL);

CREATE TABLE returns_(
return_id INT,
order_id INT,
return_date DATE,
return_reason VARCHAR(100)
);
CREATE TABLE marketing_campaigns(
camapign_id INT,
campaign_name VARCHAR(100),
start_date DATE,
end_date DATE,
marketing_cost DECIMAL);

SELECT count(*) from customers;  #500

select count(*) from orders; #3000

SELECT SUM(quantity) from orders; #5022

SELECT SUM(quantity*selling_price*(1-discount))  as total_revenue from orders
where order_status='delivered';

SELECT products.product_name,
ROUND(SUM(quantity*selling_price*(1-discount)),0)  as total_revenue
from orders  join products on orders.product_id = products.product_id
GROUP BY products.product_id,products.product_name ORDER BY  total_revenue DESC 
limit 10;

SELECT products.category,
ROUND(SUM(quantity*selling_price*(1-discount)),0)  as total_revenue
from orders join products on orders.product_id = products.product_id
GROUP BY products.category;

SELECT ROUND( AVG(quantity*selling_price*(1-discount)),0)  as Average_ordervalue from orders
where order_status='delivered';

SELECT products.product_name,
SUM(quantity*selling_price*(1-discount)) as total_revenue,
ROUND(SUM(orders.quantity*products.cost_price),0) as total_cost,
ROUND(SUM(quantity*selling_price*(1-discount)),0)-ROUND(SUM(orders.quantity*products.cost_price),0)as Profit,
(ROUND(SUM(quantity*selling_price*(1-discount)),0)-ROUND(SUM(orders.quantity*products.cost_price),0))/(ROUND(SUM(quantity*selling_price*(1-discount)),0))*100 as Profit_Margin
from orders  join products on orders.product_id = products.product_id
GROUP BY products.product_id,products.product_name,products.cost_price ORDER BY  total_revenue DESC; 


SELECT customers.customer_name,
COUNT(DISTINCT orders.order_id) AS total_orders,
ROUND(SUM(quantity * selling_price * (1 - discount)), 0) AS total_revenue
FROM orders JOIN customers ON orders.customer_id = customers.customer_id
GROUP BY customers.customer_name
ORDER BY total_revenue DESC
LIMIT 10;

SELECT customers.state,
ROUND(SUM(quantity*selling_price*(1-discount)),0)as revenue from orders join customers on orders.customer_id=customers.customer_id 
group by customers.state order by revenue DESC ; 


SELECT DISTINCT(products.product_name) from products Left join orders on products.product_id=orders.product_id
WHERE orders.product_id=NULL;


SELECT products.category,
count(DISTINCT returns_.order_id)/COUNT(DISTINCT orders.order_id)*100 as return_rate from products
join orders on products.product_id=orders.product_id 
left join returns_ on orders.order_id=returns_.order_id 
group by products.category;


select  MONTHNAME(orders.order_date) as month,
ROUND(SUM(quantity*selling_price*(1-discount)),0)as revenue,
COUNT(DISTINCT orders.order_id) as orders,
COUNT(orders.customer_id) AS  customers,
ROUND(SUM(quantity*selling_price*(1-discount)),0)-ROUND(SUM(orders.quantity*products.cost_price),0)as Profit
from orders inner join products on orders.product_id=products.product_id
where orders.order_status='delivered'
GROUP BY  
MONTH(orders.order_date),
MONTHNAME(orders.order_date)
ORDER BY MONTH(orders.order_date);

select MONTHNAME(orders.order_date) as month,
ROUND(SUM(quantity*selling_price*(1-discount)),0)as revenue
LAG(revenue)OVER( ORDER BY MONTH(orders.order_date)) ORDER BY MONTH(orders.order_date) 
AS previous_monthrevenue,
ROUND(SUM(quantity*selling_price*(1-discount)),0)-LAG(revenue)OVER( ORDER BY MONTH(orders.order_date))/ROUND(SUM(quantity*selling_price*(1-discount)),0)*100 as growth_percent 
from orders inner join products on orders.product_id=products.product_id
where orders.order_status='delivered'
GROUP BY  
MONTH(orders.order_date),
MONTHNAME(orders.order_date)
ORDER BY MONTH(orders.order_date);


WITH monthly_sales AS
(SELECT
MONTH(orders.order_date) AS month_number,
MONTHNAME(orders.order_date) AS month,
ROUND( SUM(orders.quantity * orders.selling_price * (1 - orders.discount)), 0) AS revenue
FROM orders INNER JOIN products ON orders.product_id = products.product_id
WHERE orders.order_status = 'delivered'
GROUP BY
MONTH(orders.order_date),
MONTHNAME(orders.order_date)),
monthly_growth AS 
(SELECT month_number,month,revenue,LAG(revenue) OVER(ORDER BY month_number)
AS previous_month_revenue  FROM monthly_sales)
SELECT month,revenue,previous_month_revenue,
ROUND((revenue - previous_month_revenue)/ previous_month_revenue * 100,2)AS growth_percentage
FROM monthly_growth
ORDER BY month_number;

WITH customer_ranking AS 
(SELECT customers.customer_name,
ROUND( SUM(orders.quantity * orders.selling_price * (1 - orders.discount)), 0) AS revenue
from orders inner join customers on  orders.customer_id = customers.customer_id
WHERE orders.order_status = 'delivered'
GROUP BY customers.customer_name)
SELECT customer_name,revenue,DENSE_RANK() OVER(ORDER BY revenue DESC) as Rank_ 
from customer_ranking ;

WITH customer_orders AS (
SELECT customer_id,
COUNT(DISTINCT order_id) AS total_orders FROM orders
GROUP BY customer_id)
SELECT ROUND(100 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)/ COUNT(*),2)
AS repeat_customer_percentage
FROM customer_orders;


WITH number_orders AS 
(SELECT customers.customer_name,
ROUND( SUM(orders.quantity * orders.selling_price * (1 - orders.discount)), 0) AS revenue,
COUNT(DISTINCT orders.order_id) AS Number_of_orders
from customers inner join orders on  orders.customer_id = customers.customer_id
WHERE orders.order_status = 'delivered'
GROUP BY customers.customer_name)
SELECT customer_name,revenue,Number_of_orders,
ROUND(revenue/Number_of_orders,0) as Average_order_value from number_orders WHERE Number_of_orders >3;


WITH customers_ AS 
(SELECT customers.customer_name,
ROUND( SUM(orders.quantity * orders.selling_price * (1 - orders.discount)), 0) AS revenue
from customers inner join orders on  orders.customer_id = customers.customer_id
GROUP BY customers.customer_name )
SELECT customer_name,revenue, 
CASE WHEN revenue>50000 THEN 'High Value'
     WHEN revenue BETWEEN 20000 AND 50000 THEN 'Medium Value'
     WHEN revenue <20000 THEN 'Low value'
     END AS Customer_segmentation 
from customers_ ;
 
SELECT customers.customer_name,
MAX(orders.order_date) as Last_order, 
DATEDIFF(CURDATE(),MAX(orders.order_date)) as Days_Since_Purchase 
from customers inner join orders on customers.customer_id = orders.customer_id 
GROUP BY customer_name 
ORDER BY Days_Since_Purchase DESC;


WITH Inactive_customers AS(
SELECT customers.customer_name,
MAX(orders.order_date) as Last_order, 
DATEDIFF(CURDATE(),MAX(orders.order_date)) as Days_Since_Purchase 
from customers inner join orders on customers.customer_id = orders.customer_id 
GROUP BY customer_name 
ORDER BY Days_Since_Purchase)
SELECT customer_name,
CASE WHEN Days_Since_Purchase>90 THEN 'INACTIVE'
     ELSE 'ACTIVE'
END AS cutomers_
from Inactive_customers;


WITH product_revenue AS (
SELECT products.product_id,products.category,products.product_name,
ROUND( SUM(orders.quantity * orders.selling_price * (1 - orders.discount)), 0) AS revenue
from orders INNER JOIN products On orders.product_id = products.product_id 
GROUP BY products.product_id, products.category,products.product_name),
ranked_products AS (
SELECT product_id,category,product_name,revenue,
ROW_NUMBER() OVER ( PARTITION BY category ORDER BY revenue DESC) AS product_rank
FROM product_revenue)
SELECT category,product_name,revenue 
FROM ranked_products 
WHERE product_rank = 1;

SELECT products.product_name,products.category,
ROUND(SUM(orders.quantity * orders.selling_price * (1 - orders.discount)), 0) AS revenue,
ROUND(SUM(orders.quantity * orders.selling_price * (1 - orders.discount)- orders.quantity * products.cost_price),0)
AS profit,
ROUND(100 * SUM(
            orders.quantity * orders.selling_price * (1 - orders.discount)
            - orders.quantity * products.cost_price)/ NULLIF(
            SUM(orders.quantity * orders.selling_price * (1 - orders.discount)),0),2) AS profit_margin
FROM orders JOIN products ON orders.product_id = products.product_id
GROUP BY
    products.product_id,
    products.product_name,
    products.category
ORDER BY profit_margin ASC;











WITH product_revenue AS(
SELECT products.product_id,products.product_name,
ROUND(SUM(orders.quantity * orders.selling_price * (1 - orders.discount)), 0) AS revenue
 FROM orders
    INNER JOIN products
        ON orders.product_id = products.product_id
    WHERE orders.order_status = 'delivered'
    GROUP BY products.product_name),
running_revenue AS (
SELECT product_id,product_name,revenue,
SUM(revenue)OVER (ORDER BY revenue DESC) AS Cumulative_revenue, 
SUM(revenue)OVER() AS Total_revenue from product_revenue)
SELECT
    product_name,
    revenue,
    cumulative_revenue,
    ROUND(
        cumulative_revenue / total_revenue * 100,
        2
    ) AS cumulative_revenue_percentage
FROM running_revenue
ORDER BY revenue DESC;

WITH product_revenue AS(
SELECT products.product_id,products.product_name,
ROUND(SUM(orders.quantity * orders.selling_price * (1 - orders.discount)),0)
AS revenue  from orders INNER JOIN products on products.product_id=orders.product_id
WHERE orders.order_status = 'delivered'
GROUP BY products.product_id,products.product_name),
running_revenue AS(
SELECT product_id,product_name,revenue,
SUM(revenue) OVER(ORDER BY revenue DESC) AS cumulative_revenue,
SUM(revenue) OVER () AS total_revenue FROM product_revenue)
SELECT product_name,revenue,cumulative_revenue,
ROUND(cumulative_revenue/total_revenue*100,2) AS revenue_percentage 
FROM running_revenue
ORDER BY revenue DESC;

WITH customer_cohort AS (
    SELECT
        customer_id,
        signup_date,
        DATE_FORMAT(signup_date, '%Y-%m') AS signup_month
    FROM customers
)
SELECT
    signup_month,

    COUNT(*) AS customers,

    SUM(
        EXISTS (
            SELECT 1
            FROM orders o
            WHERE o.customer_id = c.customer_id
              AND o.order_status = 'delivered'
              AND o.order_date >= DATE_ADD(c.signup_date, INTERVAL 1 MONTH)
              AND o.order_date < DATE_ADD(c.signup_date, INTERVAL 2 MONTH)
        )
    ) AS month_1,

    SUM(
        EXISTS (
            SELECT 1
            FROM orders o
            WHERE o.customer_id = c.customer_id
              AND o.order_status = 'delivered'
              AND o.order_date >= DATE_ADD(c.signup_date, INTERVAL 2 MONTH)
              AND o.order_date < DATE_ADD(c.signup_date, INTERVAL 3 MONTH)
        )
    ) AS month_2,

SUM(
EXISTS (
SELECT 1
FROM orders o
WHERE o.customer_id = c.customer_id
AND o.order_status = 'delivered'
AND o.order_date >= DATE_ADD(c.signup_date, INTERVAL 3 MONTH)
AND o.order_date < DATE_ADD(c.signup_date, INTERVAL 4 MONTH))) AS month_3,
SUM(EXISTS(SELECT 1 FROM orders o
            WHERE o.customer_id = c.customer_id
              AND o.order_status = 'delivered'
              AND o.order_date >= DATE_ADD(c.signup_date, INTERVAL 6 MONTH)
              AND o.order_date < DATE_ADD(c.signup_date, INTERVAL 7 MONTH))) AS month_6
FROM customer_cohort c
GROUP BY signup_month
ORDER BY signup_month;








        


