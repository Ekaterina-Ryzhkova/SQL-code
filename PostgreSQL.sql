--=============== РАБОТА С POSTGRESQL =======================================

SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим 
--так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

select *,
	row_number () over (order by payment_date)
from payment

select *,
	row_number () over (partition by customer_id  order by payment_date)
from payment

select payment_id ,customer_id ,payment_date ,amount ,
	sum(amount) over (partition by customer_id order by payment_date, amount)
from payment

select payment_id ,customer_id ,payment_date ,amount ,
	dense_rank () over (partition by customer_id order by amount desc)
from payment


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.

select customer_id ,payment_date ,amount ,
	lag(amount, 1, 0.) over (partition by customer_id order by payment_date) "last amount"
from payment

--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select customer_id ,payment_date ,amount ,
	(amount - lead(amount, 1, 0.) over (partition by customer_id order by payment_date)) "difference"
from payment


--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

select customer_id,amount ,payment_id , payment_date
from (select customer_id,amount ,payment_id , payment_date, 
	first_value(payment_id) over (partition by customer_id order by payment_date desc)
	from payment) f
where payment_id= first_value 

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

select staff_id, payment_date::date, sum(amount),
	sum(sum(amount)) over (partition by staff_id order by payment_date::date)
from payment 
where payment_date::date between '01.08.2005' and '31.08.2005'
group by staff_id,payment_date::date

--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

select customer_id 
from
	(select customer_id,
	row_number () over (order by payment_date::date)
	from payment
	where payment_date::date = '02.08.2005') t
where row_number % 100 = 0

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

with c1 as (
	select c.customer_id, count(i.film_id), sum(p.amount), max(r.rental_date), c.address_id
	from customer c
	join rental r on r.customer_id = c.customer_id
	join inventory i on i.inventory_id = r.inventory_id
	join payment p on p.rental_id = r.rental_id
	group by c.customer_id),
c2 as (
	select c1.customer_id, c2.country_id, c1.count, c1.sum, c1.max,
		max(c1.count) over (partition by c2.country_id) rc,
		max(c1.sum) over (partition by c2.country_id) rs,
		max(c1.max) over (partition by c2.country_id) rm
	from c1
	join address a on c1.address_id = a.address_id
	join city c2 on c2.city_id = a.city_id)
select c.country, 
	string_agg(c2.customer_id::text, ', ') filter (where count = rc),
	string_agg(c2.customer_id::text, ', ') filter (where sum = rs),
	string_agg(c2.customer_id::text, ', ') filter (where max = rm)
from country c
left join c2 on c2.country_id = c.country_id
group by c.country

--=============== POSTGRESQL =======================================

SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

explain analyze--67.50
select title, special_features 
from film
where special_features && array ['Behind the Scenes']


--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

explain analyze--77.50
select title, special_features 
from film
where 'Behind the Scenes' = any (special_features)

explain analyze--67.50
select title, special_features
from film
where array_position(special_features,'Behind the Scenes') is not null


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

explain analyze--741
with cte as (
	select title, special_features,film_id  
from film
where 'Behind the Scenes' = any (special_features))
select c.customer_id,count(c.customer_id)
from cte
	join inventory i on i.film_id = cte.film_id
	join rental r on r.inventory_id = i.inventory_id 
	join customer c on c.customer_id = r.customer_id
group by c.customer_id



--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

explain analyze--691
select c.customer_id,count(c.customer_id)
from 
	(select title, special_features, film_id 
	from film
	where special_features && array ['Behind the Scenes']) t
	join inventory i on i.film_id = t.film_id
	join rental r on r.inventory_id = i.inventory_id 
	join customer c on c.customer_id = r.customer_id
group by c.customer_id


--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

explain analyze--1407
create materialized view task as
	select c.customer_id,count(c.customer_id)
	from 
		(select title, special_features, film_id 
		from film
		where special_features && array ['Behind the Scenes']) t
	join inventory i on i.film_id = t.film_id
	join rental r on r.inventory_id = i.inventory_id 
	join customer c on c.customer_id = r.customer_id
group by c.customer_id
	
refresh materialized view task



--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее

	Оператор array ускоряет запрос.
	
--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса

	Вариант вычисления с подзапросом работает быстрее


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии
	
	explain analyze--1090
	select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.

select *
from	(select *,
	 row_number () over (partition by staff_id order by payment_date)
	from payment p) t
where  row_number = 1

