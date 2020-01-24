#!/usr/bin/env bash

if [ "$1" == "--help" ]; then
  echo "$(basename "$0") <optional list of tests in form file:func>"
  echo "e.g.: "
  echo " - run all tests: $0"
  echo " - run specific tests script: $0 signature_help.test.vim"
  echo " - run specific tests fun: $0 signature_help.test.vim:Test_signatures_TopLine\\(\\)"
  exit 0
fi

RUN_VIM="vim --clean --not-a-term"
RUN_TEST="${RUN_VIM} -S lib/test.vim"

pushd $(dirname "$0") > /dev/null

echo "Running vista.vim Vim tests"

RESULT=0

TESTS="$@"

AVOID_E325='au SwapExists * let v:swapchoice = "e"' 

if [ -z "$TESTS" ]; then
  TESTS="*_test.vim"
fi

for t in ${TESTS}; do
  echo ""
  echo "%RUN: $t"

  # split on : into fileName and testName
  IFS=: read -s t T <<< "$t"

  TESTLOGDIR=$(pwd)/logs/$t

  if ${RUN_TEST} --cmd "$AVOID_E325" "$t" "$T" && [ -f "$t.res" ]; then
    echo "%PASS: $t PASSED"
  else
    echo "%FAIL: $t FAILED - see $TESTLOGDIR"
    RESULT=1
  fi

  rm -rf "$TESTLOGDIR"
  mkdir -p "$TESTLOGDIR"
  ${RUN_VIM} --version > "${TESTLOGDIR}/vimversion"
  for l in messages debuglog test.log *.testlog; do
    # In CI we can't view the output files, so we just have to cat them
    if [ -f "$l" ]; then
      if [ "$YCM_TEST_STDOUT" ]; then
        echo ""
        echo ""
        echo "*** START: $l ***"
        cat "$l"
        echo "*** END: $l ***"
      fi
      mv "$l" "$TESTLOGDIR"
    fi
  done

  rm -f "$t".res
done

echo "Done running tests"

popd > /dev/null

echo ""
echo "All done."

echo "exit_code: $RESULT"

exit $RESULT
