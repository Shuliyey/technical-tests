#!/bin/bash
set -e

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

################### parse parameters ###################

set_default=false
log_level=info

for kv in "$@"; do
  case "${kv}" in
    --set_default)
      set_default=true
      ;;
    --log_level=*)
      log_level="${kv#*=}"
      ;;
    --action=*)
      action="${kv#*=}"
      ;;
    *)
      echo -e "unkown param: ${YELLOW}${kv[@]}${NC}, skipping"
      ;;
  esac
done

################### funcs/vars ###################

infoMsg() {
  if [ "$(echo ${log_level} | tr A-Z a-z)" == "info" ] && [ "$(echo ${set_default} | tr A-Z a-z)" != "true" ]; then
    echo -e "$1"
  fi
}

errorMsg() {
  if [ "$(echo ${log_level} | tr A-Z a-z)" != "none" ]; then
    echo -e "$1"
  fi
}

get_default() {
  local val=$(eval "echo \$DEFAULT_$(echo "${1}" | tr a-z A-Z)")
  echo $val
}

check_dep() {
  local dir_name=$(cd `dirname $0` && pwd)
  case ${action} in
    docker.info)
      local DEFAULT_GITCLOUD_PROVIDER=github

      local ENVS=()
      local OPTIONAL_ENV=("GITCLOUD_PROVIDER")
      local missing=()
      local found=()
      local optional=()
      ;;
    go.build)
      local DEFAULT_GENERATE_INFO="true"

      local ENVS=()
      local OPTIONAL_ENV=("GENERATE_INFO")
      local missing=()
      local found=()
      local optional=()
      ;;
    go.run)
      local DEFAULT_PORT="8000"
      local DEFAULT_BIND_HOST="0.0.0.0"
      local DEFAULT_GENERATE_INFO="true"

      local ENVS=()
      local OPTIONAL_ENV=("PORT" "BIND_HOST" "GENERATE_INFO")
      local missing=()
      local found=()
      local optional=()
      ;;
    docker.build)
      local DEFAULT_GO_VERSION=$(curl -s "https://golang.org/VERSION?m=text" | sed -E "s/^go//g")
      local DEFAULT_ALPINE_VERSION=$(curl -s http://dl-cdn.alpinelinux.org/alpine/ | grep -E '^<a href="v\d' | awk '{print $2}' | sed -E 's/(^href="v.+\/">v|\/<\/a>$)//g' | sort -V -r | head -n 1)
      local DEFAULT_IMAGE_NAME="shuliyey/technical-tests"
      local DEFAULT_IMAGE_TAG="latest"
      local DEFAULT_GENERATE_INFO="true"

      local ENVS=()
      local OPTIONAL_ENV=("GO_VERSION" "ALPINE_VERSION" "IMAGE_NAME" "IMAGE_TAG" "GENERATE_INFO")
      local missing=()
      local found=()
      local optional=()
      ;;
    docker.run)
      local DEFAULT_CONTAINER_PORT=8000
      local DEFAULT_HOST_PORT=${DEFAULT_CONTAINER_PORT}
      local DEFAULT_RUNTIME_USER=""
      local DEFAULT_IMAGE_NAME="shuliyey/technical-tests"
      local DEFAULT_IMAGE_TAG="latest"

      local ENVS=()
      local OPTIONAL_ENV=("CONTAINER_PORT" "HOST_PORT" "RUNTIME_USER" "IMAGE_NAME" "IMAGE_TAG")
      local missing=()
      local found=()
      local optional=()
      ;;
    k8s)
      local OPTIONAL_ENV=()
      local missing=()
      local found=()
      local optional=()
      ;;
    ci)
      local OPTIONAL_ENV=()
      local missing=()
      local found=()
      local optional=()
      ;;
    *)
      ;;
  esac

  for g in "${ENVS[@]}"; do
    g=($g)
    local found_g=()
    for e in ${g[@]}; do
      if [ ! "$(echo ${!e})" ]; then
        continue
      fi
      found_g+=($e)
    done
    if [ ${#found_g[@]} == 0 ]; then
      g=${g[@]}
      missing+=("${g// /|}")
      continue
    fi
    found_g=${found_g[@]}
    found+=("${found_g// /|}")
  done

  for g in "${OPTIONAL_ENV[@]}"; do
    g=($g)
    local found_g=()
    for e in ${g[@]}; do
      if [ ! "$(echo ${!e})" ]; then
        continue
      fi
      found_g+=($e)
    done
    if [ ${#found_g[@]} == 0 ]; then
      g=${g[@]}
      optional+=("${g// /|}")
      continue
    fi
    found_g=${found_g[@]}
    found+=("${found_g// /|}")
  done

  if [ ${#found[@]} -gt 0 ]; then
    infoMsg "${DGREEN}found${NC}:"
    for g in "${found[@]}"; do
      local g=(${g//|/ })
      if [ ${#g[@]} -gt 1 ]; then
        local d=${g[@]}
        infoMsg "  ${DCYAN}* ${d// /|}${NC}:"
        for e in ${g[@]}; do
          infoMsg "    ${CYAN}- ${e}=${!e}${NC}"
        done
        continue
      fi
      for e in ${g[@]}; do
        infoMsg "  ${CYAN}* ${e}=${!e}${NC}"
      done
    done
  fi

  if [ ${#optional[@]} -gt 0 ]; then
    infoMsg "${DYELLOW}optional${NC}:"
    for g in "${optional[@]}"; do
      local g=(${g//|/ })
      if [ ${#g[@]} -gt 1 ]; then
        local d=${g[@]}
        infoMsg "  ${DPURPLE}* ${d// /|}${NC}:"
        local kv=""
        for e in ${g[@]}; do
          kv="${kv}
${e} $(get_default ${e})"
        done
        kv=$(echo "${kv}" | sed '/^\s*$/d' | sort -k2 -k1)
        local v_uniq=$(echo "${kv}" | awk '{print $2}' | uniq -c | awk '{print  $1 " " $2}')
        local k=($(echo "${kv}" | awk '{print $1}'))
        local count=0
        for c in $(echo "${v_uniq[@]}" | awk '{print $1}'); do
          local a=${k[@]:$count:$c}
          a=${a// /,}
          infoMsg "    ${PURPLE}- ${a} (default: $(get_default ${k[$count]}))${NC}"
          for _a in ${a//,/ }; do
            if [ "$(echo ${set_default} | tr A-Z a-z)" == "true" ]; then
              echo "export ${_a}=\"$(get_default ${_a})\""
            fi
          done
          count=$((count + c))
        done
        continue
      fi
      for e in ${g[@]}; do
        infoMsg "  ${PURPLE}* ${e} (default: $(get_default ${e}))${NC}"
        if [ "$(echo ${set_default} | tr A-Z a-z)" == "true" ]; then
          echo "export ${e}=\"$(get_default ${e})\""
        fi
      done
    done
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    errorMsg "${DRED}missing${NC}:"
    for e in ${missing[@]}; do
      errorMsg "  ${YELLOW}* ${e}${NC}"
    done
    exit 1
  fi
}

################### core ###################

check_dep