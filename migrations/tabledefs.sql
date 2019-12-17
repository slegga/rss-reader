-- 1 up
create table episodes (feed text, title text, published_epoch integer, is_downloaded boolean, is_rejected boolean );
-- 1 down
drop table episodes;