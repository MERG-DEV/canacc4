#!/bin/bash
cd `dirname $0`
mkdir -p logs
rm -f ./logs/*_test.log
echo "`ls *_test.mdb|wc -w` tests to run"
time parallel --progress --eta "mdb {} > ./logs/{.}.log 2>&1" ::: $(grep -E 'wait[ ]+for[ ]+[0-9]+[ ]+ms;' scl/*_test.scl|sort -n -r -k4|cut -d'/' -f2|cut -d':' -f1|sed s/scl/mdb/|awk '!seen[$0]++')
echo
grep -h -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' ./logs/*_test.log|sort -k2,2 -k1,1
echo -e \\n`grep -h '_test: PASS' ./logs/*_test.log|wc -l` of `ls ./logs/*_test.log|wc -l` passed
cd - > /dev/null
