#lang north

-- @revision: 9a26dc3bc69e61594655ad4e90fd6252
-- @parent: 4cad8da904a1f8c42598e00e7f2cf256
-- @description: Creates the registration_invitations table.
-- @up {
create table registration_invitations (
    id bigserial primary key,
    code text,
    available boolean,
    user_id integer,
    user_registered_at timestamp without time zone,
    created_at timestamp without time zone
);
-- }

-- @down {
drop table registration_invitations;
-- }
