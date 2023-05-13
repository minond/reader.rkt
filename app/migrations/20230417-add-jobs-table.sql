#lang north

-- @revision: 4cad8da904a1f8c42598e00e7f2cf256
-- @parent: d01285fcd20cb1920e603539eae873ee
-- @description: Creates the jobs table.
-- @up {
create table jobs (
    id varchar(36) primary key,
    status text,
    name text,
    data bytea,
    logs text,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone
);
-- }

-- @down {
drop table jobs;
-- }
