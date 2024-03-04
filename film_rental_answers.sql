-- 1.	What is the total revenue generated from all rentals in the database? (2 Marks)
select sum(amount) as total_revenue from payment where rental_id in (select rental_id from rental);

-- 2.	How many rentals were made in each month_name? (2 Marks)
select monthname(rental_date) as month_name, count(*) as rental_count from rental group by month_name;

-- 3.	What is the rental rate of the film with the longest title in the database? (2 Marks)
select title, rental_rate , length(title) as titel_length from film where length(title) = (select max(length(title)) from film);

-- 4.	What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")? (2 Marks)
#my answer
select title, datediff(rental_date,"2005-05-05 22:04:30") as Difference,
avg(rental_rate) as avg_rent from film
left join inventory using(film_id)
left join rental using(inventory_id)
where datediff(rental_date,"2005-05-05 22:04:30") <= 30
group by 1,2 order by 1,2;

#sir answer
select rental_rate, rental_date from film
join inventory using(film_id)
join rental using(inventory_id) where rental_date between "2005-05-05 22:04:30" and date_add("2005-05-05 22:04:30", interval 30 day);

-- 5.	What is the most popular category of films in terms of the number of rentals? (3 Marks)
select name, count(*) as num_rental from rental join inventory using(inventory_id) join film using(film_id) 
join film_category using(film_id) join category using(category_id) 
group by name order by num_rental desc limit 1;

-- 6.	Find the longest movie duration from the list of films that have not been rented by any customer. (3 Marks)
with cte as
(select title, count(rental_id) as Rental_id_count from film f left join inventory i using(film_id)
left join rental r using(inventory_id) group by 1 order by Rental_id_count asc)
select f.*, i.length from cte f inner join film i using(title)
having Rental_id_count = 0 order by 3 desc limit 1;

-- 7.	What is the average rental rate for films, broken down by category? (3 Marks)
select name, title, avg(rental_rate) as avg_rate from film 
inner join film_category using(film_id)
inner join category using(category_id) group by name, title;

-- 8.	What is the total revenue generated from rentals for each actor in the database? (3 Marks)
select first_name, last_name, sum(amount) as total_revenue from payment 
inner join rental using(rental_id) 
inner join inventory using(inventory_id) 
inner join film using(film_id)
inner join film_actor using(film_id) 
inner join actor using(actor_id) group by first_name, last_name order by total_revenue desc;

-- 9.	Show all the actresses who worked in a film having a "Wrestler" in the description. (3 Marks)
select description from film;
select first_name, title, description from film join film_actor using(film_id) join actor using(actor_id) where description like '%Wrestler%';

-- 10.	Which customers have rented the same film more than once? (3 Marks)
#my answer
select customer_id, film_id, first_name, last_name, title, count(title) as rental_count from customer 
inner join rental using(customer_id)
inner join inventory using(inventory_id)
inner join film using(film_id) group by 1,2 having rental_count>1 order by rental_count desc; 

#sir Amswer
with cte1 as 
(select customer_id, film_id, count(film_id) over(partition by customer_id, film_id) as repeat_purchase from customer
join rental using(customer_id)
join inventory using(inventory_id)) 
select distinct customer_id, film_id from cte1 where repeat_purchase>1;

-- 11.	How many films in the comedy category have a rental rate higher than the average rental rate? (3 Marks)
#my answer
select name, count(film_id) as count_films from film join film_category using(film_id) join category using(category_id) where name='Comedy' and 
rental_rate>(select avg(rental_rate) from film);

#sir answer
with cte as
(select film_id, rental_rate, name, avg(rental_rate) over() as avg_rental_rate from film join film_category using(film_id)
join category using(category_id) where name='comedy')
select count(distinct film_id) from cte  where rental_rate>avg_rental_rate;

-- 12.	Which films have been rented the most by customers living in each city? (3 Marks)
#my answer
select title, city, count(*) as num_rentals from film
join inventory using(film_id)
join rental using(inventory_id)
join customer using(customer_id)
join address using(address_id)
join city using(city_id) group by city, title
having COUNT(*) = ( select MAX(num_rentals) from
(select city, title, COUNT(*) AS num_rentals from film
join inventory using(film_id)
join rental using(inventory_id)
join customer using(customer_id)
join address using(address_id)
join city using(city_id)
group by city, title) as rentals_by_city
where rentals_by_city.city =city);

#sir answer
with cte1 as
(with cte as
(select city_id, film_id, count(film_id) as rented_count from customer
join rental using(customer_id)
join inventory using(inventory_id)
join address using(address_id) group by city_id, film_id)
select city_id, film_id,rented_count, rank() over(partition by city_id order by rented_count desc) as rank_count from cte)
select city_id, film_id from cte1 where rank_count=1;

-- 13.	What is the total amount spent by customers whose rental payments exceed $200? (3 Marks)
select p.customer_id, first_name, sum(amount) as total_amount from customer c
join payment p using(customer_id) 
join rental r using(rental_id)
group by c.customer_id having total_amount>200;

-- 14.	Display the fields which are having foreign key constraints related to the "rental" table. [Hint: using Information_schema] (2 Marks)
describe rental;

select kcu.table_name, kcu.column_name
from information_schema.REFERENTIAL_CONSTRAINTS rc
join information_schema.KEY_COLUMN_USAGE kcu on rc.constraint_name = kcu.constraint_name
where rc.table_name = 'rental';

-- 15.	Create a View for the total revenue generated by each staff member, broken down by store city with the country name. (4 Marks)
create view v_staff_revenue as
select s.staff_id, s.first_name, s.last_name, c.city, co.country, SUM(p.amount) as total_revenue
from staff as s
join store as st on s.store_id = st.store_id
join address as a on st.address_id = a.address_id
join city as c on a.city_id = c.city_id
join country as co on c.country_id = co.country_id
join payment as p on s.staff_id = p.staff_id
group by s.staff_id, c.city, co.country;

select * from v_staff_revenue;

/*16.	Create a view based on rental information consisting of visiting_day, customer_name, the title of the film,  no_of_rental_days, 
the amount paid by the customer along with the percentage of customer spending. (4 Marks)*/
create view v_rental_info AS
select date(rental_date) as visiting_day, CONCAT(c.first_name, ' ', c.last_name) as customer_name, f.title,
DATEDIFF(return_date, rental_date) as no_of_rental_days, p.amount as amount_paid,
(p.amount / (select SUM(amount) from payment)) * 100 as percentage_of_customer_spending from payment p
inner join rental r on p.rental_id = r.rental_id
inner join inventory i on r.inventory_id = i.inventory_id
inner join customer c on r.customer_id = c.customer_id
inner join film f on i.film_id = f.film_id;

SELECT * FROM v_rental_info;


-- 17.	Display the customers who paid 50% of their total rental costs within one day. (5 Marks)
select c.first_name, c.last_name, p.amount, r.rental_date, r.return_date from customer c
inner join rental r on c.customer_id = r.customer_id
inner join payment p on r.rental_id = p.rental_id
where p.amount>=(select SUM(amount) * 0.5 from payment where rental_id = r.rental_id)
and DATEDIFF(r.return_date, r.rental_date)<=1; 

with cte as(
select film_id, rental_duration, rental_rate, rental_id, rental_date, payment_date, customer.customer_id, 
rental_duration*rental_rate as total_payable, amount,
amount/(rental_duration*rental_rate) as percentage_paid from film 
join inventory using( film_id) 
join rental using(inventory_id)
join customer using(customer_id) 
join payment using(rental_id))
select customer_id, rental_id from cte where percentage_paid>=0.5 ;

