#lang north

-- @revision: 34e268880473bec8b84739f367252c19
-- @parent: 9698fdd4476cf3261516d66c2d3e3cac
-- @description: Creates the article_tags table.
-- @up {
create table article_tags (
    id varchar(36) primary key,
    article_id varchar(36),
    tag_id varchar(36),
    set_by text,
    created_at timestamp without time zone
);
-- }

-- @down {
drop table article_tags;
-- }
