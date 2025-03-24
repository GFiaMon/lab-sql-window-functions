/*
## Introduction
Welcome to the Window Functions lab!
In this lab, you will be working with the [Sakila](https://dev.mysql.com/doc/sakila/en/) database on movie rentals. The goal of this lab is to help you practice and gain proficiency in using window functions in SQL queries.
Window functions are a powerful tool for performing complex data analysis in SQL. They allow you to perform calculations across multiple rows of a result set, without the need for subqueries or self-joins. This can greatly simplify your SQL code and make it easier to understand and maintain.
By the end of this lab, you will have a better understanding of how to use window functions in SQL to perform complex data analysis, assign rankings, and retrieve previous row values. These skills will be useful in a variety of real-world scenarios, such as sales analysis, financial reporting, and trend analysis.
*/
use sakila;
/*
## Challenge 1
This challenge consists of three exercises that will test your ability to use the SQL RANK() function. You will use it to rank films by their length, their length within the rating category, and by the actor or actress who has acted in the greatest number of films.
*/
select * from film;
-- 1. Rank films by their length and create an output table that includes the title, length, and rank columns only. Filter out any rows with null or zero values in the length column.

		-- 1
select title, length, DENSE_RANK() over(order by length desc) as Ranking from film;
select title, length, ROW_NUMBER() over(order by length desc) as Ranking from film;
		
        -- 2 final:
select title, length, DENSE_RANK() over(order by length desc) as Ranking from film
where title is not null
and length is not null
;

-- 2. Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only. Filter out any rows with null or zero values in the length column.

		-- 1
select title, length, rating, DENSE_RANK() over(order by length desc, rating) as Ranking from film
where title is not null
and length is not null
;
		-- 2 final:
select title, length, rating, 
	DENSE_RANK() over(partition by rating order by length desc) as Ranking 
from film
where title is not null
and length is not null
;

-- 3. Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, as well as the total number of films in which they have acted. *Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.*

	-- 1
select * from actor
join film_actor
using (actor_id)
join film
using (film_id)
;
	-- 2

select  actor_id, first_name, last_name, count(film_id) as nr_films from actor
join film_actor
using (actor_id)
join film
using (film_id)
group by actor_id
order by nr_films desc
;
	-- 3
select title, film_id, actor_id, first_name, last_name, count(film_id) over(partition by actor_id) from actor
join film_actor
using (actor_id)
join film
using (film_id)
-- group by actor_id
;
	-- 4
select  actor_id, first_name, last_name, count(film_id)as nr_films from actor
join film_actor
using (actor_id)
join film
using (film_id)
;

	-- 5 FINAL:
WITH Actor_film_count AS (
    SELECT 
        title, 
        film_id, 
        actor_id, 
        first_name, 
        last_name, 
        COUNT(film_id) OVER(PARTITION BY actor_id) AS nr_films
    FROM 
        actor
    JOIN 
        film_actor USING (actor_id)
    JOIN 
        film USING (film_id)
),
Ranked_Actors AS (
    SELECT
        title,
        film_id,
        actor_id,
        first_name,
        last_name,
        nr_films,
        DENSE_RANK() OVER(PARTITION BY film_id ORDER BY nr_films DESC) AS Ranking
    FROM
        Actor_film_count
)
SELECT 
    title,
    film_id,
    actor_id,
    first_name,
    last_name,
    nr_films
FROM 
    Ranked_Actors
WHERE 
    Ranking = 1;


/*
## Challenge 2

This challenge involves analyzing customer activity and retention in the Sakila database to gain insight into business performance. 
By analyzing customer behavior over time, businesses can identify trends and make data-driven decisions to improve customer retention and increase revenue.

The goal of this exercise is to perform a comprehensive analysis of customer activity and retention by conducting an analysis on the monthly percentage change in the number of active customers and the number of retained customers. Use the Sakila database and progressively build queries to achieve the desired outcome. 
*Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.*
*/
-- Step 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.
	-- 1
select customer_id, 
	date_format(rental_date, '%m') rental_month,  
	date_format(rental_date, '%y') rental_year
from rental;

	-- 2
select
	date_format(rental_date, '%Y-%m') rental_month,
    count(DISTINCT customer_id) as active_customers
from rental
group by rental_month
order by rental_month
; 

-- Step 2. Retrieve the number of active users in the previous month.
with monthly_customers as (
	select
		date_format(rental_date, '%Y-%m') rental_month,
		count(DISTINCT customer_id) as active_customers
	from rental
	group by rental_month
)
select
	rental_month,
	active_customers,
	LAG(active_customers) over (order by rental_month) as prev_month_active
from monthly_customers; 

-- Step 3. Calculate the percentage change in the number of active customers between the current and previous month.

WITH monthly_customers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY rental_month
)
SELECT
    rental_month,
    active_customers,
    LAG(active_customers) OVER (ORDER BY rental_month) AS prev_month_active,
    CASE 
        WHEN LAG(active_customers) OVER (ORDER BY rental_month) = 0 THEN NULL
        ELSE 
            ((active_customers - LAG(active_customers) OVER (ORDER BY rental_month)) * 100.0 / 
             LAG(active_customers) OVER (ORDER BY rental_month))
    END AS percentage_change
FROM 
    monthly_customers;

-- Step 4. Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.
    
WITH monthly_customers AS (
    SELECT
        customer_id,
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month
    FROM rental
    GROUP BY customer_id, rental_month
)
SELECT 
    current_month.rental_month,
    COUNT(DISTINCT current_month.customer_id) AS retained_customers
FROM 
    monthly_customers AS current_month
JOIN 
    monthly_customers AS previous_month 
ON 
    current_month.customer_id = previous_month.customer_id 
    AND current_month.rental_month = DATE_ADD(previous_month.rental_month, INTERVAL 1 MONTH)
GROUP BY 
    current_month.rental_month;