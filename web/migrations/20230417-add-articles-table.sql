#lang north

-- @revision: d01285fcd20cb1920e603539eae873ee
-- @parent: 3a24d1d98d651b46221cc677ced4e7ef
-- @description: Creates the articles table.
-- @up {
create table articles (
    id varchar(36) primary key,
    user_id varchar(36),
    feed_id varchar(36),
    link text,
    title text,
    description text,
    type text,
    date timestamp without time zone,
    extracted_content_html text,
    extracted_content_text text,
    generated_summary_html text,
    generated_summary_text text,
    archived boolean,
    created_at timestamp without time zone
);
-- }

-- @down {
drop table articles;
-- }
