#lang north

-- @revision: b8e64f7f9610c48ae732ae35d2dfcadf
-- @parent: 34e268880473bec8b84739f367252c19
-- @description: Alters some table.
-- @up {
alter table articles
add column original_content_html text,
add column original_content_text text;
-- }

-- @down {
alter table articles
drop column original_content_html text,
drop column original_content_text text;
-- }
