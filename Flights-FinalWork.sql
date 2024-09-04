
1.В каких городах больше одного аэропорта?

select city "Город" -- выберем все города из таблички аэропорты
	from airports
group by city -- сгруппируем по названиям городов
having count(*) > 1 -- выведем только те города, названия которых встречается больше 1 раза

2.В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

select distinct a2.airport_name "Название аэропорта", a2.airport_code "Код аэропорта", t.range "Расстоние,км"
from (select a.aircraft_code,model, max(a."range") as "range" -- выбираем код самолета, модель и максимальную длину полета
	from aircrafts a 
	group by a.aircraft_code --группируем по первичному ключу
	order by 3 desc -- сортируем по убыванию все значения и выбираем одно наибольшее
	limit 1) t -- задаем алиас и выбираем из подзапроса  расстояние
join flights f on f.aircraft_code = t.aircraft_code -- присоединяем таблицу и выбираем аэропорты откуда улетают самолеты
join airports a2 on a2.airport_code = f.arrival_airport -- присоединяем таблицу, чтобы выбрать названия аэропортов


3.Вывести 10 рейсов с максимальным временем задержки вылета

select flight_no as "Номер рейса" ,(actual_departure - scheduled_departure) as "Время задержки"--выводим номер рейса и время задержки(из фактического времени вылета вычитаем время вылета по расписанию)
from flights
where (actual_departure - scheduled_departure) is not null --выводим только те значения, где время задержки не нулевое
order by 2 desc --сортируем по убыванию
limit 10 --выводим только 10 значений


4.Были ли брони, по которым не были получены посадочные талоны?

select t.book_ref, boarding_no --выводим номер бронирования и номер посадочного талона
from tickets t -- присоединяем к таблице билетов
left join boarding_passes bp on bp.ticket_no = t.ticket_no -- используем левое присоединение, чтобы нам попали все значения из таблицы регистрации
where boarding_no is null -- выбираем только те бронирования, по которым не прошла регистрация

5.Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест 
в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров 
из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - 
сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.

	
select f.flight_no , count(*) all_seats, t.busy_seats, (count(*) - t.busy_seats) free_seats, --выводим № рейса,кол-во всех мест,кол-во занятых и свободных мест (используя данные из подзапроса)
 	((count(*) -busy_seats)*100/count(*)) as "%",f.departure_airport,f.actual_departure::date, --считаем % к общ.кол-ву мест
 	sum (t.busy_seats) over  (partition by f.departure_airport, date_trunc('day', f.actual_departure) order by f.actual_departure)--считаем накопительную сумму по аэропорту и каждому дню с сортировкой по дате
 	from seats s--из таблицы мест
 	join flights f on f.aircraft_code = s.aircraft_code-- присоединяем табл полеты, чтобы получить номер рейса, аэропорт вылета, дату вылета
 	join (
 		select bp.flight_id, count (*) as busy_seats--используем подзапрос, чтобы получить кол-во занятых мест
 		from boarding_passes bp 
 		group by bp.flight_id ) t on t.flight_id = f.flight_id --присоединяем подзапрос к основной таблице для дальнейших расчетов
 	group by f.flight_no, t.busy_seats,f.departure_airport,f.actual_departure


6.Найдите процентное соотношение перелетов по типам самолетов от общего количества.

select t.aircraft_code, t.model, t.flight, 
	(round (t.flight/(sum (t.flight) over ()),2)*100) "%"-- выводим тип самолета,модель, кол-во перелетов и считаем % отношение 
	from(select a.aircraft_code, a.model,count(f.flight_id) as flight--используем подзапрос для получения кода самолета,модели самолета,кол-во полетов
		from flights f
		join aircrafts a on f.aircraft_code = a.aircraft_code 
		group by a.model,a.aircraft_code) t
	group by t.model, t. flight,t.aircraft_code


7.Были ли города, в которые можно  добраться бизнес - классом дешевле, 
чем эконом-классом в рамках перелета?

with cte as (--создаем cte
select f.flight_id ,a.city, tf.fare_conditions as Business , tf.amount as bisuness_amount,
t.Econom, t.econom_amount --выводим номер рейса,город прибытия, класс обслуживания, цена за билет (разделяем эконом и бизнес)
 from flights f --к таблице перелетов присоединяем таблицу билетов, аэропортоа
 join ticket_flights tf on tf.flight_id = f.flight_id--присоединяем к таблице полетов таблицу с билетами
 join airports a on a.airport_code = f.arrival_airport--присоединяем к таблице полетов таблицу с аэропортами
 join (select tf.flight_id, tf.fare_conditions as Econom , tf.amount as econom_amount --выводим номер рейса, билеты эконом классаи цену за билет эконом-класса 
 	from ticket_flights tf
	 where tf.fare_conditions = 'Economy') t on t.flight_id = f.flight_id --отделяем билеты категории Эконом и стоимость билетов эконом-класса
 where tf.fare_conditions = 'Business' )--отделяем билеты категории Бизнес
 select distinct cte.city--выводим из cte название города
from cte
where cte.bisuness_amount < cte.econom_amount--условие, если цена за билет бизнес-класса меньше цены за билет эконом-класса
 
 
8.Между какими городами нет прямых рейсов?

create view flights_c as--создаем представление
	select a.city city_1, a2.city city_2 --выводим 2 столбца со всеми возможными сочитаниями городов
	from airports a, airports a2--находим все возмжные сочитания
	where a.city != a2.city --убираем пары городов, где город 1 и город 2 имеют одинаковые назания
	except--удаляем повторяющиеся строки
	select a.city arrival_city, a2.city departure_city--находим город вылета и города прилета
	from flights f--из таблицы перелетов
	join airports a on a.airport_code = f.arrival_airport--присоединяем таблицы, чтобы найти названия городов
	join airports a2 on a2.airport_code = f.departure_airport
	
select *
from flights_c--запускаем предсталение

9.Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы *

with cte as (--создадим CTE
select t.aircraft_code, a3."range", acos (sind(t.B)*sind(t.B2) + cosd(t.B)*cosd(t.B2)*cosd(t.A - t.A2))*6371 as distance--считаем расстояние м/у аэропортами по формуле, выводим согласно коду самолета, max дистанцию
from (select distinct f.departure_airport,a.longitude A ,a.latitude B ,f.arrival_airport,a2.longitude A2 ,a2.latitude B2, f.aircraft_code  
	from flights f--из таблицы перелетов выводим аэпорт вылета, широта, долгота, аэропорт прилета, широта, долгота, код самолета
	join airports a on a.airport_code = f.departure_airport --присоединяем таблицу аэропорты, чтобы узнать код аэрпорта вылета
	join airports a2 on a2.airport_code = f.arrival_airport ) t--присоединяем таблицу аэропорты, чтобы узнать код аэрпорта прилета
join aircrafts a3 on a3.aircraft_code = t.aircraft_code)
select *,--выводим все значения ихз CTE
	case  --прописываем условия, если расстояние м/у аэропортами меньше или равно max дистанции, то полет допустимый
		when cte.distance <= cte."range" then 'Допутимый перелет'
		else 'Недопустимый перелет'--иначе недопустимый
	end
from cte