select sum(countmedia) from
(select count(media_id) as countmedia, user_id, birthday
from
(SELECT l.user_id, l.media_id, (SELECT birthday FROM vk.profiles AS p where p.user_id = l.user_id) AS birthday
FROM vk.likes AS l
where l.user_id IN (SELECT user_id FROM vk.profiles)
order by birthday) as userid
group by user_id
limit 10) as mediacount