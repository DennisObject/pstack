#!/usr/bin/env bash
# Tests for red-green.sh. Each case builds a throwaway repo whose test command
# runs every tests/*_test.sh file. Run: bash red-green.test.sh
set -u

here="$(cd "$(dirname "$0")" && pwd)"
script="$here/red-green.sh"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
failures=0
n=0

repo() {
	local dir="$root/$1"
	mkdir -p "$dir/src" "$dir/tests"
	cd "$dir" || exit 1
	git init -q -b main
	git config user.email t@example.com
	git config user.name t
	git config commit.gpgsign false
	printf 'add() { echo $(($1 + $2)); }\n' > src/math.sh
	printf 'for t in tests/*_test.sh; do bash "$t" || exit 1; done\n' > run-tests.sh
	printf '. src/math.sh; [ "$(add 2 3)" = 5 ]\n' > tests/add_test.sh
	git add . && git commit -qm "feat(math): add numbers"
}

commit() {
	git add -A && git commit -qm "$1"
}

add_failing_test() {
	printf '. src/math.sh; [ "$(mul 2 3)" = 6 ]\n' > tests/mul_test.sh
	commit "test(math): cover multiplication"
}

implement() {
	printf 'mul() { echo $(($1 * $2)); }\n' >> src/math.sh
	commit "feat(math): multiply numbers"
}

# check <name> <want-exit> <needle> <args...>
check() {
	local name="$1" want="$2" needle="$3"
	shift 3
	n=$((n + 1))
	local out code
	out="$(bash "$script" "$@" 2>&1)"
	code=$?
	if [ "$code" -ne "$want" ]; then
		failures=$((failures + 1))
		printf 'FAIL %s: wanted exit %s, got %s\n%s\n' "$name" "$want" "$code" "$out"
		return
	fi
	case "$out" in
	*"$needle"*) ;;
	*) failures=$((failures + 1)); printf 'FAIL %s: output lacks "%s"\n%s\n' "$name" "$needle" "$out" ;;
	esac
}

repo happy
add_failing_test
red="$(git rev-parse HEAD)"
implement
check "red then green passes" 0 "GREEN" --red "$red" -- bash run-tests.sh
check "summary names the red run" 0 "RED" --red "$red" -- bash run-tests.sh
[ "$(git branch --show-current)" = main ] || { failures=$((failures + 1)); echo "FAIL restores the branch"; }
n=$((n + 1))

repo red-only
add_failing_test
check "red commit at HEAD confirms red" 0 "implement" --red HEAD -- bash run-tests.sh

repo passes-early
printf '. src/math.sh; [ "$(add 1 1)" = 2 ]\n' > tests/more_add_test.sh
commit "test(math): cover more addition"
red="$(git rev-parse HEAD)"
printf '# no-op\n' >> src/math.sh
commit "refactor(math): touch the source"
check "tests that pass before the change fail the check" 1 "pass before" --red "$red" -- bash run-tests.sh

repo edited-after-red
add_failing_test
red="$(git rev-parse HEAD)"
printf 'mul() { echo 0; }\n' >> src/math.sh
printf '. src/math.sh; [ "$(mul 2 3)" = 0 ]\n' > tests/mul_test.sh
commit "feat(math): multiply numbers"
check "tests edited after the red commit fail the check" 1 "changed after the red commit" --red "$red" -- bash run-tests.sh

repo mode-only
add_failing_test
red="$(git rev-parse HEAD)"
chmod +x tests/mul_test.sh
implement
check "a mode-only change to a test is not an edit" 0 "GREEN" --red "$red" -- bash run-tests.sh

repo still-red
add_failing_test
red="$(git rev-parse HEAD)"
printf 'mul() { echo 0; }\n' >> src/math.sh
commit "feat(math): multiply numbers"
check "tests still failing at HEAD fail the check" 1 "fail at HEAD" --red "$red" -- bash run-tests.sh

repo dirty
add_failing_test
red="$(git rev-parse HEAD)"
implement
printf '# uncommitted\n' >> src/math.sh
check "a dirty tree is refused" 1 "commit or stash" --red "$red" -- bash run-tests.sh

repo explicit-tests
mkdir -p checks
printf '. src/math.sh; [ "$(mul 2 3)" = 6 ]\n' > checks/mul.sh
printf 'for t in tests/*_test.sh checks/*.sh; do [ -f "$t" ] && { bash "$t" || exit 1; }; done; true\n' > runner.sh
commit "test(math): cover multiplication"
red="$(git rev-parse HEAD)"
implement
check "a red commit without test-named files is still frozen and proven" 0 "GREEN" --red "$red" -- bash runner.sh
check "explicit --tests works" 0 "GREEN" --red "$red" --tests checks/mul.sh -- bash runner.sh

repo modified-existing
printf '. src/math.sh; [ "$(add 2 3)" = 5 ] && [ "$(mul 2 3)" = 6 ]\n' > tests/add_test.sh
commit "test(math): cover multiplication next to addition"
red="$(git rev-parse HEAD)"
implement
check "editing an existing test in the red commit is flagged" 0 "existing test" --red "$red" -- bash run-tests.sh

repo not-ancestor
add_failing_test
red="$(git rev-parse HEAD)"
git switch -q -c other HEAD~1
implement
check "a red commit outside HEAD's history is refused" 1 "ancestor" --red "$red" -- bash run-tests.sh

repo missing-tests-path
add_failing_test
red="$(git rev-parse HEAD)"
implement
check "a --tests path missing from the red commit is refused" 1 "not in the red commit" --red "$red" --tests test/mul_test.sh -- bash run-tests.sh

repo helper-edited
mkdir -p App.Tests/Builders
printf 'expected=6\n' > App.Tests/Builders/MulBuilder.cs
printf '. App.Tests/Builders/MulBuilder.cs; . src/math.sh; [ "$(mul 2 3)" = "$expected" ]\n' > tests/mul_test.sh
commit "test(math): cover multiplication with a builder"
red="$(git rev-parse HEAD)"
printf 'mul() { echo 0; }\n' >> src/math.sh
printf 'expected=0\n' > App.Tests/Builders/MulBuilder.cs
commit "feat(math): multiply numbers"
check "a test helper in a .Tests project edited after red fails the check" 1 "changed after the red commit" --red "$red" -- bash run-tests.sh

repo config-edited
printf '<phpunit/>\n' > phpunit.xml
commit "build: add phpunit config"
add_failing_test
red="$(git rev-parse HEAD)"
implement
printf '<phpunit stopOnFailure="false"/>\n' > phpunit.xml
commit "build: relax phpunit config"
check "a test config edited after red fails the check" 1 "phpunit.xml" --red "$red" -- bash run-tests.sh

repo other-test-edited
add_failing_test
red="$(git rev-parse HEAD)"
implement
printf '. src/math.sh; true\n' > tests/add_test.sh
commit "test(math): loosen addition"
check "an existing test edited after red fails the check" 1 "tests/add_test.sh" --red "$red" -- bash run-tests.sh

repo subdirectory
mkdir -p backend
git mv src tests run-tests.sh backend/
commit "refactor: move the backend into backend/"
cd backend
add_failing_test
red="$(git rev-parse HEAD)"
implement
check "the command runs from the directory the script was called in" 0 "GREEN" --red "$red" -- bash run-tests.sh
cd ..

repo expect
printf 'for t in tests/*_test.sh; do echo "running $t"; bash "$t" || { echo "FAILED $t"; exit 1; }; done\n' > run-tests.sh
commit "build: name each test as it runs"
add_failing_test
red="$(git rev-parse HEAD)"
implement
check "--expect passes when the red log names the failure" 0 "GREEN" --red "$red" --expect "FAILED tests/mul_test.sh" -- bash run-tests.sh
check "--expect fails when red failed for another reason" 1 "expected" --red "$red" --expect "FAILED tests/div_test.sh" -- bash run-tests.sh

repo untracked
add_failing_test
red="$(git rev-parse HEAD)"
implement
printf 'div() { :; }\n' > src/div.sh
check "an untracked file is refused" 1 "commit or stash" --red "$red" -- bash run-tests.sh

repo rewrites-tracked
printf 'v1\n' > snapshot.txt
commit "test: add a snapshot"
add_failing_test
red="$(git rev-parse HEAD)"
implement
check "a command that rewrites tracked files fails the check" 1 "changed tracked files" --red "$red" -- bash -c 'echo v2 > snapshot.txt; bash run-tests.sh'
n=$((n + 1))
if [ "$(git branch --show-current)" != main ] || [ -n "$(git status --porcelain)" ]; then
	failures=$((failures + 1))
	echo "FAIL returns to the branch with a clean tree after a rewrite"
fi

repo fixture-edited
printf 'expected=6\n' > src/expected.env
printf '. src/expected.env; . src/math.sh; [ "$(mul 2 3)" = "$expected" ]\n' > tests/mul_test.sh
commit "test(math): cover multiplication against a fixture"
red="$(git rev-parse HEAD)"
printf 'mul() { echo 0; }\n' >> src/math.sh
printf 'expected=0\n' > src/expected.env
commit "feat(math): multiply numbers"
check "a fixture from the red commit edited later fails the check" 1 "src/expected.env" --red "$red" -- bash run-tests.sh

repo stub-in-red
printf 'mul() { return 1; }\n' >> src/math.sh
printf '. src/math.sh; [ "$(mul 2 3)" = 6 ]\n' > tests/mul_test.sh
commit "test(math): cover multiplication"
red="$(git rev-parse HEAD)"
printf 'mul() { echo $(($1 * $2)); }\n' >> src/math.sh
commit "feat(math): multiply numbers"
check "a stub inside the red commit points to its own earlier commit" 1 "earlier commit" --red "$red" -- bash run-tests.sh

if [ "$failures" -eq 0 ]; then
	printf 'ok %s tests\n' "$n"
else
	printf '%s of %s tests failed\n' "$failures" "$n"
	exit 1
fi
