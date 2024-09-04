--=============РАБОТА С БАЗАМИ ДАННЫХ============

--С помощью SQL-запроса выведите в результат таблицу, содержащую названия таблиц
--и названия ограничений первичных ключей в этих таблицах.

select table_name, constraint_name
from information_schema.table_constraints
where constraint_schema = 'public'and constraint_type = 'PRIMARY KEY'


--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
-- Выведите уникальные названия городов из таблицы городов.

select distinct city
from city

--ЗАДАНИЕ №2
-- Доработайте запрос из предыдущего задания, чтобы запрос выводил только те города, 
--названия которых начинаются на “L” и заканчиваются на “a”, и названия не содержат пробелов.

select distinct city
from city
where city like ('L%a') and city not like ('% %')

--ЗАДАНИЕ №3
--Получите из таблицы платежей за прокат фильмов информацию по платежам, 
--которые выполнялись в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно и стоимость 
--которых превышает 1.00. 
--Платежи нужно отсортировать по дате платежа.

select payment_id, payment_date, amount 
from payment
where payment_date::date between '17-06-2005' and '19-06-2005' and amount>=1
order by 2

--ЗАДАНИЕ №4
-- Выведите информацию о 10-ти последних платежах за прокат фильмов.

select payment_id, payment_date, amount 
from payment
order by 2 desc
limit 10

--ЗАДАНИЕ №5
-- Выведите следующую информацию по покупателям:
 	--1.Фамилия и имя (в одной колонке через пробел)
 	--2.Электронная почта
 	--3.Длину значения поля email
 	--4.Дату последнего обновления записи о покупателе (без времени)
  -- Каждой колонке задайте наименование на русском языке.

select concat(first_name, ' ', last_name) as "ФИО покупателя", email as "Электронная почта", 
character_length (email::text) as "Длина эл.почты", last_update::date as "Последнее обновление"
from customer

--ЗАДАНИЕ №6
-- Выведите одним запросом только активных покупателей, имена которых KELLY или WILLIE. 
--Все буквы в фамилии и имени из верхнего регистра должны быть переведены в нижний регистр.

select lower (first_name) as first_name, lower (last_name) as last_name, active
from customer
where (first_name = 'KELLY' or first_name = 'WILLIE') and active = 1

--========ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ==========

--ЗАДАНИЕ №1
--Выведите одним запросом информацию о фильмах, у которых рейтинг “R” и стоимость аренды указана от 0.00 до 3.00
--включительно, а также фильмы c рейтингом “PG-13” и стоимостью аренды больше или равной 4.00.

select film_id, title, description, rating, rental_rate
from film 
where rating::text like 'R' and (rental_rate >= '0.00' and rental_rate <= '3.00') 
or rating::text like 'PG-13' and rental_rate >= '4.00'

--ЗАДАНИЕ №2
--Получите информацию о трёх фильмах с самым длинным описанием фильма.

select film_id , title, description, character_length (description ::text)
from film
order by 4 desc
limit 3

--ЗАДАНИЕ №3
--Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки:

  - в первой колонке должно быть значение, указанное до @,
  - во второй колонке должно быть значение, указанное после @.

select customer_id, email, split_part(email, '@',1) as "Email до @", split_part(email, '@',2) as "Email после @"
from customer

--ЗАДАНИЕ №4
-- Доработайте запрос из предыдущего задания, скорректируйте значения в новых колонках: 
--первая буква должна быть заглавной, остальные строчными.

select customer_id, email, concat(upper (left(split_part(email, '@',1), 1)), lower (right(split_part(email, '@',1),-1))),
concat(upper (left(split_part(email, '@',2), 1)), lower (right(split_part(email, '@',2),-1)))
from customer

--=============ОСНОВЫ SQL==============

--======== ОСНОВНАЯ ЧАСТЬ ==============
--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес, город и страну проживания.

select concat (c. first_name, ' ' , c. last_name) as "Customer name", a.address, c2.city ,c3.country 
from customer c 
	join address a on a.address_id = c.address_id 
	join city c2 on c2.city_id = a.city_id 
	join country c3 on c3.country_id = c2.country_id 
	
-- ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select store_id as "ID магазина", count(customer_id ) as "Кол-во покупателей"
from customer
	group by store_id

--Доработайте запрос и выведите только те магазины, у которых количество покупателей больше 300.

select c.store_id as "ID магазина", count(c.customer_id ) as "Кол-во покупателей"
from customer c
	group by c.store_id 
	having count(c.customer_id ) >300
	
--Доработайте запрос, добавив в него информацию о городе магазина, фамилии и имени продавца, который работает в нём.	
	
select c.store_id as "ID магазина", count(c.customer_id ) as "Кол-во покупателей",c2.city as "Город",
concat (s2.first_name,' ',s2.last_name) as "Имя сотрудника"
from customer c
	join store s on s.store_id = c.store_id 
	join staff s2 on s2.staff_id  =s.manager_staff_id 
	join address a on a.address_id = s.address_id
	join city c2 on c2.city_id = a.city_id 
		group by c.store_id,c2.city, s2.first_name, s2.last_name 
		having count(c.customer_id ) >300
		
--ЗАДАНИЕ №3
--Выведите топ-5 покупателей, которые взяли в аренду за всё время наибольшее количество фильмов.

select concat (c.first_name,' ',c.last_name) as "Покупатель", count (i.film_id ) as "Кол-во фильмов"
from customer c 
 	join rental r on r.customer_id = c.customer_id 
 	join inventory i on i.inventory_id = r.inventory_id 
 	group by concat (c.first_name,' ',c.last_name)
 	order by 2 desc
 	limit 5
 	
 --ЗАДАНИЕ №4
 --Посчитайте для каждого покупателя 4 аналитических показателя:
	--	*количество взятых в аренду фильмов;
	--	*общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа);
	--	*минимальное значение платежа за аренду фильма;
	--	*максимальное значение платежа за аренду фильма.

select concat (c.first_name,' ',c.last_name) as "Покупатель", 
count (i.film_id ) as "Кол-во фильмов", 
round(sum (p.amount)) as "Общая ст-ть платежей", min(p.amount) as "Миним.ст-ть платежа", 
max(p.amount) as "Максим. ст-ть платежа"  
from customer c 
 	left join rental r on r.customer_id = c.customer_id 
 	left join inventory i on i.inventory_id = r.inventory_id
 	left join payment p on p.rental_id  = r.rental_id
 	group by concat (c.first_name,' ',c.last_name)

 --ЗАДАНИЕ №5 
 --Используя данные из таблицы городов, составьте одним запросом всевозможные пары городов так, 
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
 
 select c.city as "city 1", c2.city as "city 2" 
 from city c 
 	cross join city c2
 	where c.city  != c2.city  
 	
 --ЗАДАНИЕ №6
 --Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и дате возврата (поле return_date), 
 --вычислите для каждого покупателя среднее количество дней, за которые он возвращает фильмы.
 
 select customer_id ,round(avg (return_date::date-rental_date::date),2)
 from rental
 group by customer_id 
 order by 1
 
 --========ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ==========

--ЗАДАНИЕ №1 
--Посчитайте для каждого фильма, 
--сколько раз его брали в аренду, а также общую стоимость аренды фильма за всё время.
 
select f.title as "Название фильма", count (i.film_id) as "Колличество аренд",
sum (p.amount) as "Стоимость аренды"
from film f
	join inventory i using (film_id )
	join rental r using (inventory_id)
	join payment p on p.rental_id = r.rental_id 
	group by f.title 
	order by 1
	
--ЗАДАНИЕ №2 
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, 
--которые ни разу не брали в аренду.

select f.title as "Название фильма", count (i.film_id) as "Колличество аренд",
sum (p.amount) as "Стоимость аренды"
from film f
	left join inventory i using (film_id )
	left join rental r using (inventory_id)
	left join payment p on p.rental_id = r.rental_id 
	where i.inventory_id  is null 
	group by f.title 
	
--ЗАДАНИЕ №3 
--Посчитайте количество продаж, выполненных каждым продавцом. 
--Добавьте вычисляемую колонку «Премия». Если количество продаж превышает 7 300, 
--то значение в колонке будет «Да», иначе должно быть значение «Нет».

select p.staff_id, count (payment_id), 
	(case 
		when count (payment_id) > 7300 then 'ДА'
		else 'НЕТ'
	end) as "Премия"
from payment p
group by staff_id


--==========УГЛУБЛЕНИЕ В SQL=============

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--База данных: если подключение к облачной базе, то создаёте новую схему с префиксом в виде фамилии, 
--название должно быть на латинице в нижнем регистре и таблицы создаете в этой новой схеме, если подключение к локальному серверу, 
--то создаёте новую схему и в ней создаёте таблицы.

--Спроектируйте базу данных, содержащую три справочника:
--· язык (английский, французский и т. п.);
--· народность (славяне, англосаксы и т. п.);
--· страны (Россия, Германия и т. п.).
--Две таблицы со связями: язык-народность и народность-страна, отношения многие ко многим. Пример таблицы со связями — film_actor.
--Требования к таблицам-справочникам:
--· наличие ограничений первичных ключей.
--· идентификатору сущности должен присваиваться автоинкрементом;
--· наименования сущностей не должны содержать null-значения, не должны допускаться --дубликаты в названиях сущностей.
--Требования к таблицам со связями:
--· наличие ограничений первичных и внешних ключей.

--В качестве ответа на задание пришлите запросы создания таблиц и запросы по --добавлению в каждую таблицу по 5 строк с данными.
 
create schema DZ4

--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ

select * from "language"

create table language 
	( language_id serial primary key,
	language_name varchar(50) not null unique)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ

insert into language (language_name)
values ('Английский'), ('Французский'), ('Японский'), ('Русский'), ('Немецкий')

--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ

select * from "nationality"

create table "nationality"
	(nationality_id serial primary key,
 	nationality varchar (50) not null unique)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ

insert into nationality(nationality)
values ('Англосаксы'),('Кельты'),('Монголы'),('Славяне'),('Индоевропейцы')

--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ

create table "country"
	(country_id serial primary key,
	counTry varchar (50) not null unique)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ
	
insert into "country" (country)
values('Англия'),('Франция'),('Япония'),('Россия'),('Германия')

select * from country

--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table "connection_1" (
	language_id int references language (language_id),
	nationality_id int references nationality (nationality_id),
	primary key (language_id, nationality_id)
)

select * from connection_1

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into connection_1 (language_id, nationality_id)
values(1,1),(2,2),(3,3),(4,4),(5,5)


--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table connection_2 (
	country_id int references country (country_id),
	nationality_id int references nationality (nationality_id),
	primary key (country_id, nationality_id))

select * from connection_2

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into connection_2 (country_id, nationality_id)
values(1,1),(2,2),(3,3),(4,4),(5,5)


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============
--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, 
что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.

create table film_new(
	film_name varchar(255) not null,
	film_year integer not null check (film_year > 0),
	film_rental_rate numeric(4,2),
	film_duration integer not null check (film_duration> 0))
	

--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
values ('The Shawshank Redemption', 1994, 2.99, 142),('The Green Mile', 1999, 0.99, 189),
('Back to the Future', 1985, 1.99, 116),('Forrest Gump', 1994, 2.99, 142), ('Schindlers List', 1993, 3.99, 195)

--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41

update film_new 
set film_rental_rate = (film_rental_rate + 1.41)

--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new

delete from film_new
where film_name = 'Back to the Future'

--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме

insert into film_new(film_name, film_year, film_rental_rate, film_duration)
values ('Jumanji blade', 2006, 4.4, 121)

--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых

select film_name, film_year, film_rental_rate, film_duration, round( film_duration / 60, 2) film_duration_h
from film_new

--ЗАДАНИЕ №7 
--Удалите таблицу film_new

drop table film_new




