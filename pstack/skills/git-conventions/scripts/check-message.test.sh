#!/usr/bin/env bash
# Tests for check-message.sh. Run: bash check-message.test.sh
set -u

here="$(cd "$(dirname "$0")" && pwd)"
check="$here/check-message.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# Run outside any repository, so a caller's pstack.allowTerm config cannot leak in.
cd "$tmp" || exit 1
failures=0
n=0

# expect <pass|fail> <name> <mode> <text> [extra args...]
expect() {
	local want="$1" name="$2" mode="$3" text="$4"
	shift 4
	n=$((n + 1))
	local out code
	if [ "$mode" = title ]; then
		out="$(bash "$check" title "$text" "$@" 2>&1)"
		code=$?
	else
		printf '%s\n' "$text" > "$tmp/msg"
		out="$(bash "$check" "$mode" "$tmp/msg" "$@" 2>&1)"
		code=$?
	fi
	if { [ "$want" = pass ] && [ "$code" -ne 0 ]; } || { [ "$want" = fail ] && [ "$code" -ne 1 ]; }; then
		failures=$((failures + 1))
		printf 'FAIL %s: wanted %s, exit %s\n%s\n' "$name" "$want" "$code" "$out"
	fi
}

# expect_output <name> <mode> <text> <substring>
expect_output() {
	local name="$1" mode="$2" text="$3" needle="$4"
	n=$((n + 1))
	printf '%s\n' "$text" > "$tmp/msg"
	local out
	out="$(bash "$check" "$mode" "$tmp/msg" 2>&1)"
	case "$out" in
	*"$needle"*) ;;
	*) failures=$((failures + 1)); printf 'FAIL %s: output lacks "%s"\n%s\n' "$name" "$needle" "$out" ;;
	esac
}

expect pass "plain header" commit "fix(group): refresh group windows when a selected target takes damage"
expect pass "header without scope" commit "docs: describe the deploy steps"
expect pass "breaking change marker" commit "feat(api)!: drop the v1 endpoints"
expect pass "header with body and footer" commit "perf(group): skip non-player targeters before group lookup

Group lookups ran for every targeter, including NPCs that can never be in a group.

Refs #711"
expect pass "human co-author" commit "fix(ui): align the toolbar

Co-authored-by: Jane Doe <jane@example.com>"
expect pass "git comments and scissors are ignored" commit "fix(rewards): log every Kronos reward
# Please enter the commit message for your changes.
# ------------------------ >8 ------------------------
diff --git a/x b/x"
expect pass "fixup commit" commit "fixup! fix(rewards): log every Kronos reward"
expect pass "merge commit" commit "Merge branch 'main' into fix/kronos"
expect pass "git revert" commit 'Revert "fix(rewards): log every Kronos reward"'

expect fail "missing type" commit "refresh group windows"
expect fail "unknown type" commit "update(group): refresh group windows"
expect fail "capitalized type" commit "Fix(group): refresh group windows"
expect fail "capitalized subject" commit "fix(group): Refresh group windows"
expect fail "trailing period" commit "fix(group): refresh group windows."
expect fail "empty subject" commit "fix(group): "
expect fail "header over 100 characters" commit "fix(group): refresh the group windows of every player on the map that targets the entity that took damage now"
expect fail "body without blank line" commit "fix(group): refresh group windows
The windows were stale."
expect fail "claude co-author trailer" commit "fix(group): refresh group windows

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
expect fail "cursor co-author trailer" commit "fix(group): refresh group windows

Co-authored-by: Cursor Agent <cursoragent@cursor.com>"
expect fail "generated-with footer" commit "fix(group): refresh group windows

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
expect fail "model named in body" commit "fix(group): refresh group windows

Grok traced the stale state to the damage system."
expect pass "allowed domain term" commit "fix(llm): retry the Claude API on overload" --allow-term claude

expect pass "title" title "fix(galaxy-gates): stop shield healing on gate bosses and fix Kronos completion"
expect fail "title fixup" title "fixup! fix(group): refresh group windows"
expect fail "title merge" title "Merge branch 'main' into fix/kronos"
expect fail "title names a model" title "feat(group): add targeter refresh (by grok)"
expect fail "title with newline" title "fix(group): refresh
windows"

body_739='## Why

Fixes #731 and #732.

- The Zeta Devourer and Delta shielded bosses reset to full HP and shield every 3 s while their insta-shield was up. The shield now only blocks damage, and its refresh animation reaches every nearby pilot.
- Kronos completion granted every reward but only logged crafting materials, so pilots saw just the Schism Crystals. Every reward is now logged.
- The Kronos clone was sent with the player'"'"'s design id as an NPC type the client has no sprite for, so only its name showed. It now carries the player'"'"'s ship pattern.

Paired client PR draws the clone'"'"'s lasers and engines from the player design. Screenshots: [before](https://play.averin.space/showcase/kronos-clone-before.png), [after](https://play.averin.space/showcase/kronos-clone-after.png).'

body_736='## Why

Part of #711. Group updates only fired when a member dealt or took damage, so a member'"'"'s selected target showed stale HP and shield when someone else hit it. Damage now also refreshes the groups of players on the map targeting the entity, through the existing once-per-second group cadence.

Paired client fix makes the target bar tooltips reachable.'

body_full='## Why

Fixes #740. Discount codes were checked in the client only, so any code worked against the API. The server now validates codes and caps the discount.

## Testing

- [ ] Apply `SAVE10` to a 50 EUR cart. The total shows 45 EUR.
- [ ] Apply an expired code. The cart shows "Code expired" and the total does not change.

## Deployment

- [ ] Before deploy, create the codes table:
  ```sql
  CREATE TABLE IF NOT EXISTS discount_codes (code VARCHAR(32) PRIMARY KEY, percent INT NOT NULL);
  # a shell-style comment line inside a fence is not a heading
  ```
- [ ] After deploy, add `DISCOUNT_MAX_CENTS=2000` to the API environment and restart the service.'

expect pass "reference body 739" body "$body_739"
expect pass "reference body 736" body "$body_736"
expect pass "body with testing and deployment" body "$body_full"

expect fail "body without why" body "Fixes #12. The total is now right."
expect fail "body with an unknown section" body "## Why

Fixes #12.

## What changed

- \`Cart.total\` rounds once."
expect fail "testing item without checkbox" body "## Why

Fixes #12.

## Testing

- Open the cart and check the total."
expect fail "empty section" body "## Why

Fixes #12.

## Testing
"
expect fail "sections out of order" body "## Testing

- [ ] Open the cart.

## Why

Fixes #12."
expect fail "generated-with footer in body" body "## Why

Fixes #12.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
expect fail "assistant self-mention in body" body "## Why

I am Claude, and I changed the cart total to round once."
expect fail "co-author in body" body "## Why

Fixes #12.

Co-Authored-By: Grok <noreply@x.ai>"

long_body="## Why
"
for i in $(seq 1 45); do long_body="$long_body
- Line $i of a description that is far too long."; done
expect fail "body over 40 lines" body "$long_body"

expect pass "human co-author on an ai subdomain" commit "fix(ui): align the toolbar

Co-authored-by: Jane Doe <jane@ai.example.com>"
expect pass "human co-author whose name contains agent" commit "fix(ui): align the toolbar

Co-authored-by: Kai Agent-Smith <kai@example.com>"
expect fail "bot co-author" commit "fix(ui): align the toolbar

Co-authored-by: review bot <bot@example.com>"
expect pass "body with CRLF line endings" body "$(printf '## Why\r\n\r\nFixes #12. The total rounds once.\r\n')"

template_body='## Summary

Adds discount codes.

## Checklist

- [x] Tests added'
expect pass "attribution mode accepts a repository template" attribution "$template_body"
expect fail "attribution mode rejects a co-author" attribution "$template_body

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"

git init -q "$tmp/repo"
git -C "$tmp/repo" config --add pstack.allowTerm claude
n=$((n + 1))
printf 'fix(llm): retry the Claude API on overload\n' > "$tmp/repo/msg"
if ! (cd "$tmp/repo" && bash "$check" commit msg >/dev/null 2>&1); then
	failures=$((failures + 1))
	echo "FAIL git config pstack.allowTerm is honored"
fi

expect_output "explains the attribution rule" commit "fix(group): refresh group windows

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" "attribution"

if [ "$failures" -eq 0 ]; then
	printf 'ok %s tests\n' "$n"
else
	printf '%s of %s tests failed\n' "$failures" "$n"
	exit 1
fi
