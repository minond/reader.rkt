#lang north

-- @revision: 9698fdd4476cf3261516d66c2d3e3cac
-- @parent: 7ef0ac3fec298599b137e90f909a0363
-- @description: Creates the tags table.
-- @up {
create table tags (
    id varchar(36) primary key,
    label text,
    color text,
    approved boolean,
    created_at timestamp without time zone
);
-- }

-- @down {
drop table tags;
-- }
