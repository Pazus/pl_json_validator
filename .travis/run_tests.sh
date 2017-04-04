#!/bin/bash
set -ev

#cd $(dirname "$(readlink -f "$0")")


#sqlplus /nolog  @utPLSQL/client_source/sqlplus/ut_run.sql $PLJS_OWNER/$PLJS_OWNER_PASSWORD@//$CONNECTION_STR -f=ut_documentation_reporter -s
"$SQLCLI" -L $PLJS_OWNER/$PLJS_OWNER_PASSWORD@//$CONNECTION_STR <<SQL
@tests/test_json_validator.pck
set trimspool on
set echo off
set feedback off
set verify off
Clear Screen
set linesize 32767
set pagesize 0
set long 200000000
set longchunksize 1000000
set serveroutput on size unlimited format truncated
exec ut.run();
SQL
