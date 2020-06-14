use vk;

-- Операторы, фильтрация, сортировка и ограничение
-- Агрегация данных
-- ------------------------------------------ пользователи
-- Находим пользователя
SELECT * FROM users LIMIT 1;
SELECT * FROM users WHERE id = 1; 
SELECT firstname, lastname FROM users WHERE id = 1;

use vk;
SELECT id, count(*),
	from_user_id, 
    to_user_id
  FROM vk.messages
where from_user_id IN (SELECT id
		-- firstname, 
		-- lastname
		from vk.users 
		WHERE id IN (
			SELECT initiator_user_id FROM friend_requests WHERE (target_user_id = 1) AND status='approved' -- ИД друзей, заявку которых я подтвердил
			union
			SELECT target_user_id FROM friend_requests WHERE (initiator_user_id = 1) AND status='approved' -- ИД друзей, подрвердивших мою заявку
		))  
        or 
        to_user_id IN (SELECT id
		-- firstname, 
		-- lastname
		from users 
		WHERE id IN (
			SELECT initiator_user_id FROM friend_requests WHERE (target_user_id = 1) AND status='approved' -- ИД друзей, заявку которых я подтвердил
			union
			SELECT target_user_id FROM friend_requests WHERE (initiator_user_id = 1) AND status='approved' -- ИД друзей, подрвердивших мою заявку
		))  
GROUP BY id;




-- Данные пользователя с заглушками
SELECT 
	firstname
	, lastname
	, 'city' 
	, 'main_photo'
FROM users 
WHERE id = 1;

-- Расписываем заглушки
SELECT 
	firstname, 
	lastname, 
	(SELECT hometown FROM profiles WHERE user_id = 1) AS city,
	(SELECT filename FROM media WHERE id = 
	    (SELECT photo_id FROM profiles WHERE user_id = 1)
	) AS main_photo
FROM users 
WHERE id = 1;

-- Начинаем работать с фотографиями
-- в типах медиа данных есть фото:
-- % - заменяет любое количество любых символов
-- _ - заменяет 1 любой символ
SELECT * FROM media_types WHERE name LIKE 'phoTo'; -- LIKE не чувствителен к регистру!
SELECT * FROM media_types WHERE name LIKE 'p%';
SELECT * FROM media_types WHERE name LIKE '_____'; -- названия из 5 символов

-- Выбираем фотографии пользователя
SELECT filename FROM media 
  WHERE user_id = 1
    AND media_type_id = (
      SELECT id FROM media_types WHERE name LIKE 'photo' -- в реальной жизни указали бы id = 1
    ); 
    
-- Фото другого пользователя (подменить user_id = 5)
SELECT filename FROM media 
  WHERE user_id = 5
    AND media_type_id = (
      SELECT id FROM media_types WHERE name LIKE 'photo'
    ); 
   
-- Фото другого пользователя (если знаем только email пользователя)
SELECT filename FROM media 
WHERE user_id = (select id from users where email = 'arlo50@example.org')
    AND media_type_id = (
      SELECT id FROM media_types WHERE name LIKE 'photo' -- если не знаем id
    ); 
   
-- ------------------------------------------ новости
-- Смотрим типы объектов для которых возможны новости  
SELECT * FROM media_types;

-- Выбираем новости пользователя
select *
  FROM media 
  WHERE user_id = 1;
  
-- Выбираем путь к видео файлам, которые есть в новостях
SELECT filename FROM media 
	WHERE user_id = 1
  AND media_type_id = (
    SELECT id FROM media_types WHERE name LIKE 'video' limit 1
);

-- Аггрегирующие функции (avg, max, min, count) 
-- Подсчитываем количество таких файлов
SELECT COUNT(*) FROM media 
	WHERE user_id = 1
  AND media_type_id = (
    SELECT id FROM media_types WHERE name LIKE 'photo'
);

-- Начинаем создавать архив новостей по месяцам
-- (сколько новостей в каждом месяце было создано)
SELECT 
	COUNT(id) AS media -- группируем по id и считаем сумму таких записей
	, MONTHNAME(created_at) AS month_name
	-- , MONTH(created_at) AS month_num -- если заходим вывести номер месяца (вспомогательно) 
FROM media
GROUP BY month_name
-- order by month(created_at) -- упорядочим по месяцам
order by media desc -- узнаем самые активные месяцы
; 

-- сколько новостей у каждого пользователя?  
SELECT COUNT(id) AS news_count, user_id
  FROM media
  GROUP BY user_id;
 
 -- режимы MySQL
 select @@sql_mode;
 
-- ------------------------------------------ друзья
-- Смотрим структуру таблицы дружбы (для любителей работать в консоли)
describe friend_requests; -- фишка MySQL, в MS SQL Server такой команды нет
DESC     friend_requests; -- то же самое

-- Выбираем друзей пользователя (сначала все заявки)
SELECT * FROM friend_requests 
WHERE 
	initiator_user_id = 1 -- мои заявки
	or target_user_id = 1 -- заявки ко мне
;

-- Выбираем только друзей с подтверждённым статусом
SELECT * FROM friend_requests 
WHERE (initiator_user_id = 1 or target_user_id = 1)
	and status = 'approved' -- только подтвержденные друзья
;

-- Выбираем новости друзей (общий вид запроса, с заглушками)
SELECT * FROM media WHERE user_id IN (1,2,3 union 4,5,6); -- нерабочий запрос, только шаблон

-- Выбираем новости друзей (реальный запрос)
SELECT * FROM media WHERE user_id IN (
  SELECT initiator_user_id FROM friend_requests WHERE (target_user_id = 1) AND status='approved' -- ИД друзей, заявку которых я подтвердил
  union
  SELECT target_user_id FROM friend_requests WHERE (initiator_user_id = 1) AND status='approved' -- ИД друзей, подрвердивших мою заявку
);

-- Объединяем новости пользователя и его друзей (добавим к пред. запросу 1 строку в начале (мои новости) и 2 строки в конце (order by + limit))
SELECT * FROM media WHERE user_id = 1 -- мои новости
UNION
SELECT * FROM media WHERE user_id IN (  -- новости друзей
  SELECT initiator_user_id FROM friend_requests WHERE (target_user_id = 1) AND status='approved' -- ИД друзей, заявку которых я подтвердил
  union
  SELECT target_user_id FROM friend_requests WHERE (initiator_user_id = 1) AND status='approved' -- ИД друзей, подрвердивших мою заявку
)
ORDER BY created_at desc -- упорядочиваем список
LIMIT 10; -- просто чтобы потренироваться

-----------------------------------------------------------
------------------------- перерыв -------------------------
-----------------------------------------------------------

/*
-- Находим имена (пути) медиафайлов, на которые ссылаются новости
SELECT media_type_id FROM media WHERE user_id = 1
UNION
SELECT media_type_id FROM media WHERE user_id IN (
  SELECT user_id FROM friend_requests WHERE user_id = 1 AND status
);
*/

-- ------------------------------------------ лайки
-- Смотрим структуру лайков
DESC likes;

-- Подсчитываем лайки для моих новостей (моих медиа)
SELECT 
	media_id
	, COUNT(*) -- применим агрегирующую функцию count 
FROM likes 
WHERE media_id IN ( -- 1,2,3,4,5
  SELECT id FROM media WHERE user_id = 1 -- мои медиа
)
GROUP BY media_id; -- схлапываем все записи с каждым media_id в 1 запись и подсчитываем их количество

/*
-- то же с JOIN
SELECT media_id, COUNT(*) 
FROM likes l
JOIN media m on l.media_id = m.id
WHERE m.user_id = 1 -- мои медиа
GROUP BY media_id;
*/

-- ------------------------------------------ сообщения  
-- Выбираем сообщения от пользователя и к пользователю (мои и ко мне)
SELECT * FROM messages
  WHERE from_user_id = 1 -- от меня (я отправитель)
    OR to_user_id = 1 -- ко мне (я получатель)
  ORDER BY created_at DESC; -- упорядочим по дате
  
-- Непрочитанные сообщения
-- добавим колонку is_read DEFAULT FALSE
ALTER TABLE messages
ADD COLUMN is_read BOOL default false;

-- получим непрочитанные (будут все) 
SELECT * FROM messages
  WHERE to_user_id = 1
    AND is_read = 0
  ORDER BY created_at DESC;

 -- отметим прочитанными некоторые (старше какой-то даты)
 -- эмулируем ситуацию, что пользователь заходил в сеть 100 дней назад
 update messages
 set is_read = 1
 where created_at < DATE_SUB(NOW(), INTERVAL 100 DAY);

 -- снова получим непрочитанные
 SELECT * FROM messages
  WHERE to_user_id = 1
    AND is_read = 0
  ORDER BY created_at DESC;
 
-- Выводим друзей пользователя с преобразованием пола и возраста 
-- (поиграемся со встроенными функциями MYSQL)
SELECT user_id, 
	-- , gender -- сначала выведем так, потом заменим на CASE ниже 
    CASE (gender)
         WHEN 'm' THEN 'male'
         WHEN 'f' THEN 'female'
    END AS gender, 
    TIMESTAMPDIFF(YEAR, birthday, NOW()) AS age -- функция определяет разницу между датами в выбранных единицах (YEAR)
  FROM profiles
  WHERE user_id IN ( -- 1,2,3 union 4,5,6 -- это мы уже делали сегодня раньше (получали подтвержденных друзей пользователя)
	  SELECT initiator_user_id FROM friend_requests WHERE (target_user_id = 1) AND status='approved' -- ИД друзей, заявку которых я подтвердил
	  union
	  SELECT target_user_id FROM friend_requests WHERE (initiator_user_id = 1) AND status='approved' -- ИД друзей, подрвердивших мою заявку
  );

-- Является ли пользователь админом данного сообщества?
-- добавляем поле admin_user_id в таблицу communities
ALTER TABLE vk.communities ADD admin_user_id INT DEFAULT 1 NOT NULL;
-- ALTER TABLE vk.communities ADD CONSTRAINT communities_fk FOREIGN KEY (admin_user_id) REFERENCES vk.users(id);

-- установим пользователя с id = 1 в качестве админа ко всем сообществам
update communities
set admin_user_id = 1;

-- является ли пользователь админом группы?
-- user_id = 1
-- community_id = 5
select 2 = (
	select admin_user_id
	from communities
	where id = 5
	) as 'is admin';




    
-- Решение 2й задачи 6 урока - найти человека, который больше всех общался с нашим пользователем.
use vk;
SELECT id, count(*),
	from_user_id, 
    to_user_id
  FROM vk.messages
where from_user_id IN (SELECT id
		-- firstname, 
		-- lastname
		from vk.users 
		WHERE id IN (
			SELECT initiator_user_id FROM friend_requests WHERE (target_user_id = 1) AND status='approved' -- ИД друзей, заявку которых я подтвердил
			union
			SELECT target_user_id FROM friend_requests WHERE (initiator_user_id = 1) AND status='approved' -- ИД друзей, подрвердивших мою заявку
		))  
        or 
        to_user_id IN (SELECT id
		-- firstname, 
		-- lastname
		from users 
		WHERE id IN (
			SELECT initiator_user_id FROM friend_requests WHERE (target_user_id = 1) AND status='approved' -- ИД друзей, заявку которых я подтвердил
			union
			SELECT target_user_id FROM friend_requests WHERE (initiator_user_id = 1) AND status='approved' -- ИД друзей, подрвердивших мою заявку
		))  
GROUP BY id;

-- Решение 3й задачи 6 урока - Общее кол-во лайков, которые поставили 10 самых молодых пользователей

select sum(countmedia) from
(select count(media_id) as countmedia, user_id, birthday
from
(SELECT l.user_id, l.media_id, (SELECT birthday FROM vk.profiles AS p where p.user_id = l.user_id) AS birthday
FROM vk.likes AS l
where l.user_id IN (SELECT user_id FROM vk.profiles)
order by birthday) as userid
group by user_id
limit 10) as mediacount;

-- Решение 4й задачи 6 урока - Определить кто больше поставил лайков, мужчины или женщины

select case when female > male then female else male end as genderlikes from -- Не понятно как сделать чтобы выводил в названии столбца (или его значении) вместо цифры слово "мужчина" или "женщина"
(select count(case when gend = 'f' then 1 end) as female, count(case when gend = 'm' then 1 end) as male
from
(select l.media_id, l.user_id, (select gender from vk.profiles as p where p.user_id = l.user_id) as gend
from vk.likes as l
where l.user_id in (select user_id from vk.profiles)) as gendf) as gendmf;