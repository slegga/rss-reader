-- 1 up
create table episodes (id text,feed text, title text, description text, published_epoch integer, url text, is_downloaded integer, is_rejected integer, PRIMARY KEY(id ASC) );
-- 1 down
drop table episodes;