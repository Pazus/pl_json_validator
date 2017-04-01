#!/bin/bash
set -ev

cd $(dirname "$(readlink -f "$0")")
git clone https://github.com/utPLSQL/urPLSQL.git --branch=master --depth 1 utPLSQL

#create user
"$SQLCLI" -L -S sys/$ORACLE_PWD@//$CONNECTION_STR AS SYSDBA <<SQL
set echo off
@@utPLSQL/source/install_headless.sql $UT3_USER $UT3_PASSWORD $UT3_OWNER_TABLESPACE
@@utPLSQL/source/create_synonyms_and_grants_for_public.sql $UT3_USERS
SQL
