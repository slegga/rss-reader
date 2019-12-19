-- 1 up
create table episodes (id text,feed text, title text, published_epoch integer, is_downloaded integer, is_rejected integer, PRIMARY KEY(id ASC) );
-- 1 down
drop table episodes;