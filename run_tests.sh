#!/usr/bin/env bash

set -e

case "${1:-all}" in
  cube)
    swipl -g 'set_test_options([format(log)]),run_tests' -t halt tests/test_cube.pl
    ;;
  moves)
    swipl -g 'set_test_options([format(log)]),run_tests' -t halt tests/test_moves.pl
    ;;
  validation)
    swipl -g 'set_test_options([format(log)]),run_tests' -t halt tests/test_validation.pl
    ;;
  facelets)
    swipl -g 'set_test_options([format(log)]),run_tests' -t halt tests/test_facelets.pl
    ;;
  search)
    swipl -g 'set_test_options([format(log)]),run_tests' -t halt tests/test_search.pl
    ;;
  tables)
    swipl -g 'set_test_options([format(log)]),run_tests' -t halt tests/test_tables.pl
    ;;
  thistle)
    swipl -g 'set_test_options([format(log)]),run_tests' -t halt tests/test_thistle.pl
    ;;
  all)
    swipl -g 'set_test_options([format(log)]),run_tests' -t halt \
      tests/test_cube.pl tests/test_moves.pl tests/test_validation.pl tests/test_facelets.pl tests/test_search.pl tests/test_tables.pl tests/test_thistle.pl
    ;;
  *)
    echo "Uso: $0 [all|cube|moves|validation|facelets|search|tables|thistle]" >&2
    exit 1
    ;;
esac
