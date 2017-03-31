#!/bin/bash
set -ev

cd $(dirname "$(readlink -f "$0")")
#create user
"$SQLCLI" -L -S sys/$ORACLE_PWD@//$CONNECTION_STR AS SYSDBA <<SQL
set echo off
@@create_pljs_owner.sql $PLJS_USER $PLJS_OWNER_PASSWORD $PLJS_OWNER_TABLESPACE
SQL
