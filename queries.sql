/*  Query1- query used for first insight   */

WITH t1 as
(
SELECT
	f.title as film_title,
	c.name as category_name,
    count(f.title) over (partition by f.film_id) as rentalcount

 FROM film f
JOIN film_category fc
ON f.film_id= fc.film_id
JOIN category c
ON fc.category_id=c.category_id
JOIN inventory i
ON i.film_id=f.film_id
JOIN rental r
ON r.inventory_id=i.inventory_id
  ),
t2 as
(
SELECT DISTINCT(film_title),category_name,rentalcount
FROM t1
 WHERE category_name IN ('Animation', 'Children' ,
'Classics' ,'Comedy' , 'Family' ,'Music')
ORDER BY category_name, film_title
)

SELECT category_name, sum(rentalcount) as total_rentalcount
FROM t2
GROUP BY 1
ORDER BY 1,2



/*Query2- query used for second insight */

WITH t1 as
(
SELECT
	f.title as title,
         ca.name as name,
	f.rental_duration as rental_duration
FROM category ca
JOIN film_category fc
ON ca.category_id=fc.category_id
JOIN film f
ON f.film_id=fc.film_id
),
t2 as
(
SELECT title,name,
       rental_duration,
       NTILE(4) OVER(ORDER BY rental_duration ) as standard_quartile
FROM t1
 WHERE name IN ('Animation', 'Children' ,
'Classics' ,'Comedy' , 'Family' ,'Music')
 )
SELECT (dname) cname, max(one) q1, max(two) q2,max(three) q3,max(four) q4
FROM(
SELECT dname,
       case when standard_quartile=1 then count end as "one",
       case when standard_quartile=2 then count end as "two",
       case when standard_quartile=3 then count end as "three",
       case when standard_quartile=4 then count end as "four"
FROM(SELECT
       DISTINCT(name) dname,
        standard_quartile,
       COUNT(standard_quartile) count
FROM t2
GROUP BY 1,2
order by 1,2
) as sub
)as sub1
GROUP BY sub1.dname


/*Query3- query used for third insight */

WITH t1 as
(SELECT r.rental_date,
        DATE_PART('month',r.rental_date) as month,
        DATE_PART('year',r.rental_date) as year,
        s.staff_id,
        s.store_id,
        r.rental_id
FROM rental r
JOIN staff s
ON s.staff_id=r.staff_id
 )
 SELECT CAST(month_year AS DATE) AS date1,max(storeid_one) stid1,max(storeid_two)stid2
 FROM(
SELECT CONCAT(year,'/',month,'/1') as month_year,
       count_rentals,
       case when store_id=1 then count_rentals end as "storeid_one",
       case when store_id=2 then count_rentals end as "storeid_two"
FROM(
SELECT
           month,
	   year,
	   store_id,
	   COUNT(rental_id) AS count_rentals
FROM t1
GROUP BY 1,2,3
ORDER BY 4 DESC
 )as sub
 )as sub1
 GROUP BY 1
 ORDER BY 1,2,3 ASC

/*Query4- query used for fourth insight */

WITH t1 as
(
SELECT c.customer_id,
       DATE_TRUNC('month',payment_date) as date,
       CONCAT(c.first_name,' ',c.last_name) as full_name,
       p.amount
FROM payment p
JOIN customer c
ON p.customer_id=c.customer_id
),

t2 as
(SELECT
        c.customer_id,
        CONCAT(c.first_name,' ',c.last_name) as full_name,
        SUM(p.amount) as totamt
FROM payment p
JOIN customer c
ON p.customer_id=c.customer_id
GROUP BY c.customer_id,full_name
ORDER BY totamt DESC
LIMIT 6
)
SELECT full_name, cast(avg(pay_countpermon) as int)  avgpay_countpermon,
       cast(avg(pay_amount) as int) avgpay_amount
FROM
(
SELECT
   t1.date AS pay_mon,
       t1. full_name,
       COUNT(t1.amount) as pay_countpermon,
       SUM(t1.amount) as pay_amount


FROM t1
JOIN t2
ON t1.full_name=t2.full_name
GROUP BY 1,2
ORDER BY 2
)AS sub
GROUP BY 1
ORDER BY 3 DESC
