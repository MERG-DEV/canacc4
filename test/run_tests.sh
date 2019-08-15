#!/bin/bash
cd `dirname $0`
mkdir -p logs
rm -f ./logs/*_test.log
parallel "echo \"Launching {.}\";mdb {} > ./logs/{.}.log 2>&1" ::: *_test.mdb
grep -h -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' ./logs/*_test.log
cd - > /dev/null
