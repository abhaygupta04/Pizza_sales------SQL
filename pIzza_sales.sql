CREATE DATABASE pizzahuts;

USE pizzahuts;

CREATE TABLE orders (
    order_id INT NOT NULL PRIMARY KEY,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL
);

CREATE TABLE order_details (
    order_details_id INT NOT NULL PRIMARY KEY,
    order_id INT NOT NULL,
    pizza_id TEXT NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
); 

-- 1.Retrieve the total number of orders placed.

SELECT 
    COUNT(order_id) AS total_order
FROM
    orders;

-- 2. Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(order_details.quantity * pizzas.price),
            2) AS total_revenue
FROM
    pizzas
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
;

-- 3.Identify the highest-priced pizza
SELECT 
    pizza_types.name, MAX(price) AS price
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY price DESC
LIMIT 1;

-- 4.Identify the most common pizza size ordered.
SELECT 
    pizzas.size AS pizza_size,
    COUNT(order_details.order_id) AS common_ordered_pizza
FROM
    pizzas
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_size
ORDER BY common_ordered_pizza DESC;

-- 5.List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pizza_types.name AS pizza_name,
    SUM(order_details.quantity) AS quantity_sum
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_name
ORDER BY quantity_sum DESC
LIMIT 5;

-- 6.Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT pizza_types.category , SUM(order_details.quantity) AS quantity
FROM pizza_types JOIN pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.category
ORDER BY quantity DESC;

-- 7.Determine the distribution of orders by hour of the day.
SELECT HOUR(order_time) AS hours, COUNT(order_id) as order_count
FROM orders
GROUP BY hours
ORDER BY order_count DESC ;

-- 8. Join relevant tables to find the category-wise distribution of pizzas.
SELECT category, COUNT(name) AS pizzas
FROM pizza_types
GROUP BY category;


-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    ROUND(AVG(no_of_pizzas), 0)
FROM
    (SELECT 
        order_date AS date,
            SUM(order_details.quantity) AS no_of_pizzas
    FROM
        orders
    JOIN order_details ON orders.order_id = order_details.order_id
    GROUP BY order_date) AS a;

-- 10. Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    pizzas.pizza_type_id AS pizza_type,
    SUM(order_details.quantity * pizzas.price) AS revenue
FROM
    pizzas
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_type
ORDER BY revenue DESC
LIMIT 3;

-- 11. Calculate the percentage contribution of each pizza type to total revenue
SELECT 
    pizzas.pizza_type_id AS pizza_type,
    SUM(order_details.quantity * pizzas.price) AS revenue,
    ROUND(
        100.0 * SUM(order_details.quantity * pizzas.price) / 
        (SELECT SUM(order_details.quantity * pizzas.price)
         FROM pizzas
         JOIN order_details ON pizzas.pizza_id = order_details.pizza_id), 2
    ) AS percentage_contribution
FROM pizzas
JOIN order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizzas.pizza_type_id
ORDER BY revenue DESC;

-- 12. Analyze the cumulative revenue generated over time
SELECT 
    o.order_date,
    SUM(od.quantity * p.price) AS daily_revenue,
    SUM(SUM(od.quantity * p.price)) OVER (ORDER BY o.order_date) AS cumulative_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY o.order_date
ORDER BY o.order_date;

-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT 
    category,
    pizza_name,
    revenue
FROM (
    SELECT 
        pizza_types.category AS category,
        pizza_types.name AS pizza_name,
        ROUND(SUM(order_details.quantity * pizzas.price), 0) AS revenue,
        RANK() OVER (PARTITION BY pizza_types.category ORDER BY SUM(order_details.quantity * pizzas.price) DESC) AS rn
    FROM pizza_types
    JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
    JOIN order_details ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY pizza_types.category, pizza_types.name
) ranked
WHERE rn <= 3
ORDER BY category, revenue DESC;

