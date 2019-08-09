#!/bin/bash
cd `dirname $0`
mkdir -p logs
rm -f ./logs/*_test.log
for TEST_FILE in *_test.mdb; do
  TEST_NAME=`basename --suffix=.mdb ${TEST_FILE}`
  echo "Launching ${TEST_NAME}"
  mdb ./${TEST_NAME}.mdb > ./logs/${TEST_NAME}.log 2>&1 &
done
wait
grep -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' ./logs/*_test.log
cd - > /dev/null
