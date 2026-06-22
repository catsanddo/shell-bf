#!/bin/sh

# How to use:
# Place your tests in the USERS_TESTS block marked by the BEGIN_USER_TESTS and
# END_USER_TESTS comments.
# To test a command, use the syntax:
#     test 'shell_command' 'expected_output'
# The command you enter will be passed directly to eval inside a subshell. It's
# standard output will be compared to expected_output. A match means the test
# passes. If there is a mismatch, the actual and expected outputs will be
# printed, and the test will be marked as failed.
# If all tests pass, the shell exits with status code 0. Otherwise it exits with
# a non-zero status code.

# NOTE: due to the way shell variables are processed, trailing newlines will be
#       stripped off of both the command's output and the expected_output
#       argument. As far as I know, there is no way to avoid this.

passed_tests=0
total_tests=0

TEST_RED="$(printf '\033[31m')"
TEST_GREEN="$(printf '\033[32m')"
TEST_YELLOW="$(printf '\033[33m')"
TEST_RESET="$(printf '\033[0m')"

# Param: command expected_output [exit_code]
test () {
    local actual_output
    printf '%s' "Testing '${TEST_YELLOW}$1${TEST_RESET}'... "
    actual_output="$(eval $1)"
    if [ "$2" = "$actual_output" -a '(' -z "$3" -o "$3" = "$?" ')' ]; then
        passed_tests=$((passed_tests + 1))
        echo "${TEST_GREEN}pass${TEST_RESET}"
        total_tests=$((total_tests + 1))
    else
        echo "${TEST_RED}fail${TEST_RESET}"
        printf '\t%s\n' "Expected '$2' got '$actual_output' instead."
        total_tests=$((total_tests + 1))
        return 1
    fi
}

printf '%s' 'Sanity checks...'
test_sanity_check=barfos
test '' '' >/dev/null
test 'echo Hello World' 'Hello World' >/dev/null
test 'echo $test_sanity_check' 'barfos' >/dev/null
test 'echo Hello World' '' >/dev/null || passed_tests=$((passed_tests + 1))
unset sanity_check

if [ "$passed_tests" -ne "$total_tests" ]; then
    echo "${TEST_RED}fail${TEST_RESET}"
    echo 'There is an error in the testing script'
    exit 1
fi
echo "${TEST_GREEN}pass${TEST_RESET}"

passed_tests=0
total_tests=0

# BEGIN_USERS_TESTS
. src/map.sh
map_set test_map foo bar
test 'map_get test_map foo' 'bar'
map_set test_map fooz 'bar baz'
test 'map_get test_map fooz' 'bar baz'
test 'echo $test_map' 'foo fooz'
map_delete test_map
test 'echo $test_map__foo' ''
test 'echo $test_map__fooz' ''
test 'echo $test_map' ''

. src/list.sh
list='1 2 3 4 5 6 7 8'
test 'list_get 0 $list' '1'
test 'list_get 4 $list' '5'
test 'list_get 7 $list' '8'
test 'list_get -1 $list' '' '1'
test 'list_get 8 $list' '' '1'
test 'list_set -1 0 $list' '1 2 3 4 5 6 7 8' '1'
test 'list_set 8 0 $list' '1 2 3 4 5 6 7 8' '1'
test 'list_set 1 23 $list' '1 23 3 4 5 6 7 8'
test 'list_set 7 23 $list' '1 2 3 4 5 6 7 23'
list="a 'b c' d"
test 'eval list-get 1 $list' 'b c'
unset list

. src/list-lite.sh
list='1 2 3 4 5 6 7 8'
test 'list_get 0 $list' '1'
test 'list_get 4 $list' '5'
test 'list_get 7 $list' '8'
test 'list_get -1 $list' '' '1'
test 'list_get 8 $list' '' '1'
test 'list_set -1 0 $list' '1 2 3 4 5 6 7 8' '1'
test 'list_set 8 0 $list' '1 2 3 4 5 6 7 8' '1'
test 'list_set 1 23 $list' '1 23 3 4 5 6 7 8'
test 'list_set 7 23 $list' '1 2 3 4 5 6 7 23'
unset list

. src/string.sh
string="`printf '\n foo bar '`"
test 'substr 0 1 "$string"' "`printf '\n'`"
test 'substr 1 1 "$string"' ' '
test 'substr 4 3 "$string"' 'o b'
test 'substr 9 1 "$string"' ' '
string='    '
test 'substr 1 2 "$string"' '  '
unset string

# END_USER_TESTS

echo "$passed_tests tests out of $total_tests passed."
[ "$passed_tests" -ne "$total_tests" ] && exit 1
echo "${TEST_GREEN}All tests passed.${TEST_RESET}"
