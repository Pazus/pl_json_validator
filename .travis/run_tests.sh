#!/bin/bash
set -ev

cd $(dirname "$(readlink -f "$0")")


sqlplus /nolog  @utPLSQL/client_source/sqlplus/ut_run.sql $PLJS_OWNER/$PLJS_OWNER_PASSWORD@//$CONNECTION_STR -f=ut_documentation_reporter -s
