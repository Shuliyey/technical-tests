#!/usr/bin/env bash

################### constants ###################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

DRED='\033[1;31m'
DGREEN='\033[1;32m'
DYELLOW='\033[1;33m'
DBLUE='\033[1;34m'
DPURPLE='\033[1;35m'
DCYAN='\033[1;36m'

NC='\033[0m'

################### funcs/vars ###################

infoMsg() {
  echo -e "$1"
}

doneMsg() {
  echo -e "$1 ${GREEN}done${NC}"
}

warnMsg() {
  echo -e "$1 ${YELLOW}warn${NC}"
}

failMsg() {
  echo -e "$1 ${RED}fail${NC}"
}

wait_for_endpoint() {
  local endpoint=""
  local status_regex="^200$"
  local interval=10
  local limits=30
  local kv=""

  for kv in "$@"; do
    case "${kv}" in
      --endpoint=*)
        endpoint="${kv#*=}"
        ;;
      --status_regex=*)
        status_regex="${kv#*=}"
        ;;
      --interval=*)
        interval="${kv#*=}"
        ;;
      --insecure)
        if [ "$(echo ${extra_opt} | grep -E -- "--insecure|-k")" == "" ]; then
          extra_opt="${extra_opt} -k"
        fi
        ;;
      --limits=*)
        limits="${kv#*=}"
        ;;
      *)
        infoMsg "unknown param: ${YELLOW}${kv}${NC}, skipping"
        ;;
    esac
  done

  local msg="waiting for http status of ${CYAN}${endpoint}${NC} to match regex ${CYAN}${status_regex}${NC} ..."
  local status="000"

  infoMsg "${msg}"

  while true; do
    if [ "${limits}" -le "0" ]; then
      failMsg "${msg}"
      return
    fi

    status="$(curl -s ${extra_opt} --connect-timeout 15 --max-time 30 "${endpoint}" -w %{http_code} -o /dev/null || true)"

    if echo "${status}" | grep -q -E "${status_regex}" ; then
      break
    fi

    (( limits-- )) || true

    infoMsg "http status of ${CYAN}${endpoint}${NC} is ${RED}${status}${NC} (trying again in ${CYAN}${interval}${NC} seconds, ${DPURPLE}${limits}${NC} tries remaining, ${RED}doesn't${NC} match regex ${CYAN}${status_regex}${NC})"
    sleep ${interval}
  done

  infoMsg "http status of ${CYAN}${endpoint}${NC} is ${GREEN}${status}${NC} (${GREEN}matches${NC} regex ${CYAN}${status_regex}${NC})"
  doneMsg "${msg}"
}

generate_git_info() {
  local dir_name=$(cd $(dirname $0) && pwd)
  local src_info="${dir_name}/info"
  local dest_info="${dir_name}/info.txt"

  git fetch --tags > /dev/null || true
  local git_sha=$(git rev-parse HEAD)
  local tag=$(git tag --points-at ${git_sha})
  if [ ! "$(echo ${tag})" ]; then
    local release=$(git tag --list | sort -V -r | head -n 1)
    local release=${release#*v}
    local release=(${release//./ })
    local tag=v${release[0]:-0}.$((release[1] + 1)).0-pre
  fi

  cat << EOF > ${dest_info}
${tag}
${git_sha}
$(cat ${src_info})
EOF
}

import_aws_profile() {
  for kv in "$@"; do
    case "${kv}" in
      --access-key=*)
        local access_key="${kv#*=}"
        ;;
      --secret-key=*)
        local secret_key="${kv#*=}"
        ;;
      --region=*)
        local region="${kv#*=}"
        ;;
      --format=*)
        local format="${kv#*=}"
        ;;
      *)
        echo -e "unkown param: ${YELLOW}${kv}${NC}, skipping"
        ;;
    esac
  done
  expect << EOF
spawn aws configure
expect -re "^AWS Access Key ID \\\\\[.+\\\\\] *: *$"
send "${access_key//$/\\$}\n"
expect -re "AWS Secret Access Key \\\\\[.+\\\\\] *: *$"
send "${secret_key//$/\\$}\n"
expect -re "Default region name \\\\\[.+\\\\\] *: *$"
send "${region//$/\\$}\n"
expect -re "Default output format \\\\\[.+\\\\\] *: *$"
send "${format//$/\\$}\n"
expect eof
EOF
}