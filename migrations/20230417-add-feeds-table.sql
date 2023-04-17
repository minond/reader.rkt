#lang north

-- @revision: 3a24d1d98d651b46221cc677ced4e7ef
-- @parent: ea25fbf18d4fa3ba46d438f46b490959
-- @description: Creates the feeds table.
-- @up {
create table feeds (
    id varchar(36) primary key,
    user_id varchar(36),
    feed_url text,
    logo_url text,
    link text,
    title text,
    description text,
    subscribed boolean,
    last_sync_attempted_at timestamp without time zone,
    last_sync_completed_at timestamp without time zone,
    created_at timestamp without time zone
);
-- }

-- @down {
drop table feeds;
-- }
