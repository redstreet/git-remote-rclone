#!/usr/bin/env bash

readonly base="$(cd "$(dirname "${0}")" && pwd)"

readonly TEST_DIR="${base}/test"
readonly FIRST_REPO="${TEST_DIR}/LOCAL1"
readonly REMOTE_REPO="${TEST_DIR}/REMOTE"
readonly SECOND_REPO="${TEST_DIR}/LOCAL2"
readonly RCLONE_REMOTE_PLAIN="test-remote-plain"
readonly RCLONE_REMOTE_CRYPT="test-remote-crypt"
readonly GIT_PLAIN_REMOTE_URL="rclone://${RCLONE_REMOTE_PLAIN}/${REMOTE_REPO}"
readonly GIT_CRYPT_REMOTE_URL="rclone://${RCLONE_REMOTE_CRYPT}"
readonly TEST_FILE1="testfile1"
readonly TEST_FILE2="testfile2"

cleanup()
{
	if [ -d "${TEST_DIR}" ]; then
		rm -rf "${TEST_DIR}"
	fi
}

setup_rclone_config()
{
	export RCLONE_CONFIG="${TEST_DIR}/rclone.conf"
	rclone config create "${RCLONE_REMOTE_PLAIN}" local
	rclone config create "${RCLONE_REMOTE_CRYPT}" crypt "password=$(rclone obscure git-remote-rclone)" "remote=${REMOTE_REPO}"
}

setup_test_dir()
{
	mkdir -p "${TEST_DIR}"
}

setup_remote_repo()
{
	if [ -d "${REMOTE_REPO}" ]; then
		rm -rvf "${REMOTE_REPO}"
	fi
	mkdir -p "${REMOTE_REPO}"
}

setup_repo()
{
	local remote_url="${1?missing remote_url}"
	rm -rvf "${FIRST_REPO}" "${SECOND_REPO}"
	mkdir -p "${FIRST_REPO}"
	git -C "${FIRST_REPO}" init --initial-branch master
	git -C "${FIRST_REPO}" remote add origin "${remote_url}"
}

prepend_data()
{
	local repo="${1?missing repo}"
	local file="${2-${TEST_FILE1}}"
	local data="${3-$(date -Ins)}"
	local new_data="$(echo "${data}"; cat "${repo}/${file}")"
	echo "${new_data}" > "${repo}/${file}"
}

append_data()
{
	local repo="${1?missing repo}"
	local file="${2-${TEST_FILE1}}"
	local data="${3-$(date -Ins)}"
	echo "${data}" >> "${repo}/${file}"
}

replace_data()
{
	local repo="${1?missing repo}"
	local file="${2-${TEST_FILE1}}"
	local data="${3-$(date -Ins)}"
	echo "${data}" > "${repo}/${file}"
}

create_commit()
{
	local repo="${1?missing repo}"
	git -C "${repo}" add "${repo}"
	git -C "${repo}" commit -m "$(date -Ins)"
	return "${?}"
}

push_repo()
{
	local repo="${1?missing repo}"
	git -C "${repo}" push -u origin master
	return "${?}"
}

pull_repo()
{
	local repo="${1?missing repo}"
	git -C "${repo}" pull origin master
	return "${?}"
}

fetch_repo()
{
	local repo="${1?missing repo}"
	git -C "${repo}" fetch
	return "${?}"
}

merge_repo()
{
	local repo="${1?missing repo}"
	git -C "${repo}" merge origin/master
	return "${?}"
}

reset_repo()
{
	local repo="${1?missing repo}"
	git -C "${repo}" reset --hard origin/master
	return "${?}"
}

test_push_new_repo()
{
	set -xe
	local remote_url="${1?missing remote_url}"
	setup_repo "${remote_url}"
	append_data "${FIRST_REPO}"
	create_commit "${FIRST_REPO}"
	push_repo "${FIRST_REPO}"
}

test_clone_repo()
{
	set -xe
	local remote_url="${1?missing remote_url}"
	git -C "${TEST_DIR}" clone -b master "${remote_url}" "${SECOND_REPO}"
}

test_pull_repo()
{
	set -xe
	append_data "${FIRST_REPO}"
	create_commit "${FIRST_REPO}"
	push_repo "${FIRST_REPO}"
	pull_repo "${SECOND_REPO}"
}

test_3way_merge()
{
	set -xe
	append_data "${FIRST_REPO}"
	create_commit "${FIRST_REPO}"
	push_repo "${FIRST_REPO}"
	append_data "${SECOND_REPO}" "${TEST_FILE2}"
	create_commit "${SECOND_REPO}"
	fetch_repo "${SECOND_REPO}"
	merge_repo "${SECOND_REPO}"
	push_repo "${SECOND_REPO}"
	pull_repo "${FIRST_REPO}"
}

test_conflict()
{
	set -xe
	replace_data "${FIRST_REPO}"
	create_commit "${FIRST_REPO}"
	push_repo "${FIRST_REPO}"
	append_data "${SECOND_REPO}"
	create_commit "${SECOND_REPO}"
	push_repo "${SECOND_REPO}" && false || true
	fetch_repo "${SECOND_REPO}"
	reset_repo "${SECOND_REPO}"
}

print_test_started()
{
	local test="${1?missing test}"
	local type="${2?missing type}"
	printf "TEST ${test} (${type}): "
}

print_test_passed()
{
	echo "PASSED"
}

print_test_failed()
{
	echo "FAILED"
}

run_test()
{
	local test="${1?missing test}"
	local type="${2?missing type}"
	shift 2
	print_test_started "${test}" "${type}"
	output=$(eval "${test}" "${@}" 2>&1)
	if [ "${?}" -ne 0 ]; then
		print_test_failed "${test}" "${type}"
		echo "Test logs:"
		echo "${output}" 1>&2
		print_test_started "${test}" "${type}"
		print_test_failed "${test}" "${type}"
		exit 1
	fi
	print_test_passed "${test}" "${type}"
}

tests()
{
	local remote_url="${1?missing remote_url}"
	local remote_type="${2?missing remote_type}"
	run_test test_push_new_repo "${remote_type}" "${remote_url}"
	run_test test_clone_repo "${remote_type}" "${remote_url}"
	run_test test_pull_repo "${remote_type}"
	run_test test_3way_merge "${remote_type}"
	run_test test_conflict "${remote_type}"
	run_test test_pull_repo "${remote_type}"
}

main()
{
	cleanup
	setup_test_dir
	setup_rclone_config
	setup_remote_repo
	tests "${GIT_PLAIN_REMOTE_URL}" "plain"
	tests "${GIT_CRYPT_REMOTE_URL}" "crypt"
	echo "PASSED ALL TESTS SUCCESSFULLY"
}

main
