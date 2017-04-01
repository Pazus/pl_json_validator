whenever sqlerror exit failure rollback
whenever oserror exit failure rollback
set echo off
set feedback off
set heading off
set verify off

define ut3_user       = &1
define ut3_password   = &2
define ut3_tablespace = &3

@@../source/create_pljs_owner.sql &&ut3_user &&ut3_password &&ut3_tablespace

exit success
