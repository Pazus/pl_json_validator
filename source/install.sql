prompt Installing PL-JSON-Schema

set serveroutput on size unlimited
set timing off
set verify off
set define &

spool install.log

alter session set plsql_warnings = 'ENABLE:ALL', 'DISABLE:(6000,6001,6003,6010, 7206)';
set define off

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

@@json_validator.pck

spool off

exit success