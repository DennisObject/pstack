#!/usr/bin/env bash
# Check a commit message, a PR title, or a PR body against the git-conventions
# skill: a Conventional Commits header, the Why / Testing / Deployment PR body,
# and no AI attribution anywhere.
#
# Usage: check-message.sh commit <file> [--allow-term <word>]...
#        check-message.sh title <text> [--allow-term <word>]...
#        check-message.sh body <file> [--allow-term <word>]...
#        check-message.sh attribution <file> [--allow-term <word>]...
#   <file> can be - for stdin. Exit 0 when clean, 1 on a violation, 2 on misuse.
#   attribution checks only for AI attribution. Use it for a PR body that
#   follows a repository template instead of Why, Testing, and Deployment.
#   --allow-term lets one AI product name through when it is part of the
#   project's own domain, such as a client for that product's API. So does
#   `git config --add pstack.allowTerm <word>` in that repository, which also
#   reaches the commit-msg hook. Attribution lines are never allowed.
#   Symlinked as .git/hooks/commit-msg, it checks every commit message.
set -u

[ "$(basename "$0")" = commit-msg ] && set -- commit "$@"

usage() { sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 2; }

[ $# -ge 2 ] || usage
mode="$1"
input="$2"
shift 2
allowed="$(git config --get-all pstack.allowTerm 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr '\n' ' ')"
while [ $# -gt 0 ]; do
	case "$1" in
	--allow-term) [ $# -ge 2 ] || usage; allowed="$allowed $(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"; shift 2 ;;
	*) usage ;;
	esac
done

errors=0
error() { printf 'error: %s\n' "$1" >&2; errors=$((errors + 1)); }
warn() { printf 'warning: %s\n' "$1" >&2; }

case "$mode" in
title) text="$input" ;;
commit | body | attribution)
	if [ "$input" = - ]; then text="$(cat)"; else
		[ -f "$input" ] || { printf 'error: no such file: %s\n' "$input" >&2; exit 2; }
		text="$(cat "$input")"
	fi
	;;
*) usage ;;
esac
text="$(printf '%s' "$text" | tr -d '\r')"

# Git drops these before it stores a commit message, so they are not the message.
if [ "$mode" = commit ]; then
	text="$(printf '%s\n' "$text" | sed '/^# -\{2,\} >8 -\{2,\}$/,$d' | grep -v '^#')"
fi

types='feat|fix|perf|refactor|test|docs|build|ci|chore|style|revert'

check_header() {
	local header="$1"
	if ! printf '%s' "$header" | grep -Eq "^($types)(\([a-z0-9][a-z0-9._/-]*\))?!?: "; then
		error "header must be 'type(scope): subject' with a type from: ${types//|/, }. Got: $header"
		return
	fi
	local subject="${header#*: }"
	subject="${subject#"${subject%%[! ]*}"}"
	if [ -z "$subject" ]; then
		error "the subject after 'type(scope): ' is empty"
		return
	fi
	case "$subject" in
	[A-Z]*) error "start the subject with a lowercase imperative verb: $subject" ;;
	esac
	case "$subject" in
	*.) error "drop the trailing period from the subject" ;;
	esac
	local length=${#header}
	if [ "$length" -gt 100 ]; then
		error "header is $length characters. Keep it under 72, never over 100"
	elif [ "$length" -gt 72 ]; then
		warn "header is $length characters. Aim for 72 or fewer"
	fi
}

check_attribution() {
	local all="$1" line
	local trailer='claude|anthropic|grok|x\.ai|openai|chatgpt|gpt|copilot|cursor|codex|gemini|devin|aider|(:|[[:space:]])(ai|bot|llm|agent)([[:space:]]|<|$)'
	local tool='claude|anthropic|grok|openai|chatgpt|gpt-?[0-9]|copilot|codex|gemini|llm|an ai([^a-z]|$)|ai (assistant|model|agent|tool)'
	while IFS= read -r line; do
		if printf '%s' "$line" | grep -Eiq "^[[:space:]]*(co-authored-by|signed-off-by|assisted-by|generated-by|made-with|reviewed-by|helped-by)[[:space:]]*:.*($trailer)"; then
			error "AI attribution is not allowed (git-conventions). Remove: $line"
		elif printf '%s' "$line" | grep -Eiq "(generated|written|authored)[[:space:]]+(with|by|using)[^.]{0,60}($tool)"; then
			error "AI attribution is not allowed (git-conventions). Remove: $line"
		elif printf '%s' "$line" | grep -Fq '🤖' || printf '%s' "$line" | grep -Eiq 'claude\.com/claude-code|claude\.ai/code'; then
			error "AI attribution is not allowed (git-conventions). Remove: $line"
		elif printf '%s' "$line" | grep -Eiq "(^|[^a-z])(as an ai|i am an ai|i'm an ai|ai-generated|ai generated|llm-generated)([^a-z]|$)"; then
			error "do not mention that an AI wrote this: $line"
		fi
	done <<EOF
$all
EOF
	local names='claude|anthropic|grok|chatgpt|openai|copilot|gemini|codex' term
	for term in $allowed; do
		names="$(printf '%s' "$names" | tr '|' '\n' | grep -vx "$term" | paste -sd '|' -)"
	done
	[ -n "$names" ] || return
	local hit
	hit="$(printf '%s\n' "$all" | grep -Eio "(^|[^a-z0-9])($names)([^a-z0-9]|$)" | head -1 | tr -cd '[:alnum:]')"
	if [ -n "$hit" ] && [ "$errors" -eq 0 ]; then
		error "names an AI model or tool ('$hit'). Describe the change, not who wrote it. Pass --allow-term $hit only when it is project vocabulary"
	fi
}

check_commit() {
	local header
	header="$(printf '%s\n' "$text" | sed -n '1p')"
	case "$header" in
	'fixup! '* | 'squash! '* | 'amend! '* | 'Merge '* | 'Revert "'*) ;;
	*) check_header "$header" ;;
	esac
	local second
	second="$(printf '%s\n' "$text" | sed -n '2p')"
	if [ -n "$second" ]; then
		error "leave a blank line between the header and the body"
	fi
}

check_title() {
	case "$text" in
	*$'\n'*) error "a PR title is one line"; return ;;
	esac
	check_header "$text"
}

check_body() {
	local line fence=0 section="" order="" count=0 last=0 first=""
	local -A lines checkboxes
	while IFS= read -r line; do
		count=$((count + 1))
		[ -n "${line//[[:space:]]/}" ] && last=$count
		[ -z "$first" ] && [ -n "${line//[[:space:]]/}" ] && first="$line"
		case "$line" in
		*'```'*)
			fence=$((1 - fence))
			[ -n "$section" ] && lines[$section]=$((${lines[$section]:-0} + 1))
			continue
			;;
		esac
		if [ "$fence" -eq 0 ] && printf '%s' "$line" | grep -Eq '^#{1,6}[[:space:]]'; then
			local heading="${line%"${line##*[! ]}"}"
			case "$heading" in
			'## Why' | '## Testing' | '## Deployment')
				section="${heading#'## '}"
				order="$order $section"
				lines[$section]=0
				checkboxes[$section]=0
				;;
			*) error "unknown section '$heading'. A PR body has only ## Why, ## Testing, and ## Deployment" ;;
			esac
			continue
		fi
		[ -n "$section" ] || continue
		[ -n "${line//[[:space:]]/}" ] && lines[$section]=$((${lines[$section]} + 1))
		if [ "$fence" -eq 0 ] && [ "$section" != Why ]; then
			case "$line" in
			'- [ ] '* | '- [x] '*) checkboxes[$section]=$((${checkboxes[$section]} + 1)) ;;
			'- '* | '* '* | '+ '*) error "every top-level item under ## $section is a checkbox ('- [ ] ...'): $line" ;;
			esac
		fi
	done <<EOF
$text
EOF
	if [ "$first" != '## Why' ]; then
		error "start the body with '## Why'"
	fi
	case "$order" in
	' Why' | ' Why Testing' | ' Why Deployment' | ' Why Testing Deployment' | '') ;;
	*) error "sections must appear once, in this order: Why, Testing, Deployment. Got:$order" ;;
	esac
	local s
	for s in $order; do
		[ "${lines[$s]:-0}" -gt 0 ] || error "## $s is empty. Drop the section instead"
		if [ "$s" != Why ] && [ "${lines[$s]:-0}" -gt 0 ] && [ "${checkboxes[$s]:-0}" -eq 0 ]; then
			error "## $s needs at least one checkbox item ('- [ ] ...')"
		fi
	done
	if [ "$last" -gt 40 ]; then
		error "body is $last lines. Keep it a one-minute read, never over 40 lines"
	elif [ "$last" -gt 20 ]; then
		warn "body is $last lines. Most bodies fit in 15"
	fi
}

case "$mode" in
attribution) ;;
commit) check_commit ;;
title) check_title ;;
body) check_body ;;
esac
check_attribution "$text"

[ "$errors" -eq 0 ] || exit 1
exit 0
