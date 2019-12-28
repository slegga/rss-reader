-- 1 up
create table episode (feed varchar(64), title varchar(128), published, is_downloded, num_rejected int);

CREATE UNIQUE INDEX headers ON episode(feed, title);
CREATE UNIQUE INDEX published ON episode(published);

-- 1 down
drop table episode;
