#lang north

-- @revision: 7ef0ac3fec298599b137e90f909a0363
-- @parent: 9a26dc3bc69e61594655ad4e90fd6252
-- @description: Creates the feedback table.
-- @up {
create table feedback (
    id varchar(36) primary key,
    user_id varchar(36),
    location_url text,
    content text,
    created_at timestamp without time zone
);
-- }

-- @down {
drop table feedback;
-- }
