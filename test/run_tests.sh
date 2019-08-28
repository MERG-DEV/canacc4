#!/bin/bash
cd `dirname $0`
mkdir -p logs
rm -f ./logs/*_test.log
echo "`ls *_test.mdb|wc -w` tests to run"
parallel --bar "mdb {} > ./logs/{.}.log 2>&1" ::: *_test.mdb
echo
grep -h -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' ./logs/*_test.log
echo -e \\n`grep -h '_test: PASS' ./logs/*_test.log|wc -l` of `ls ./logs/*_test.log|wc -l` passed
cd - > /dev/null
