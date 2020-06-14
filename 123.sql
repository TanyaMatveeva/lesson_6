select case when female > male then female else male end as genderlikes from
(select count(case when gend = 'f' then 1 end) as female, count(case when gend = 'm' then 1 end) as male
from
(select l.media_id, l.user_id, (select gender from vk.profiles as p where p.user_id = l.user_id) as gend
from vk.likes as l
where l.user_id in (select user_id from vk.profiles)) as gendf) as gendmf