#lang north

-- @revision: ea25fbf18d4fa3ba46d438f46b490959
-- @description: Creates the users table.
-- @up {
create table users (
    id varchar(36) primary key,
    email text,
    encrypted_password bytea,
    salt bytea,
    created_at timestamp without time zone
);
-- }

-- @down {
drop table users;
-- }
