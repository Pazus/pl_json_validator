#!/bin/bash

cd "$(dirname "$(readlink -f "$0")")"
cd ..
cd source
set -ev
#install core of utplsql
"$SQLCLI" $PLJS_OWNER/$PLJS_OWNER_PASSWORD@//$CONNECTION_STR <<SQL
@install.sql

exit
SQL
