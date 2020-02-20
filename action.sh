#!/usr/bin/env bash

set -e

dir_name=$(cd $(dirname $0) && pwd)

################### source common libs ###################

. ${dir_name}/common.sh

################### parse parameters ###################

interval=15
limits=30
node_limits=3

for kv in "$@"; do
  case "${kv}" in
    --action=*)
      action="${kv#*=}"
      ;;
    --interval=*)
      interval="${kv#*=}"
      ;;
    --limits=*)
      limits="${kv#*=}"
      ;;
    --node-limits=*)
      node_limits="${kv#*=}"
      ;;
    *)
      echo -e "unkown param: ${YELLOW}${kv[@]}${NC}, skipping"
      ;;
  esac
done

################### core ###################

case "${action}" in
  info.generate)
    ${dir_name}/dep.sh --action=${action}
    eval "$(${dir_name}/dep.sh --set_default --action=${action})"

    generate_git_info
    ;;
  docker.info)
    ${dir_name}/dep.sh --action=${action}
    eval "$(${dir_name}/dep.sh --set_default --action=${action})"

    case "${GITCLOUD_PROVIDER}" in
      github)
        tags=${GITHUB_REF##*/}
        if echo ${GITHUB_REF} | grep -q -E "^refs/heads/"; then
          tags="${tags}-${GITHUB_RUN_NUMBER},latest"
        else
          tags="${tags},stable"
        fi
        echo "##[set-output name=tag;]${tags%%,*}"
        echo "##[set-output name=tags;]${tags}"
        echo "##[set-output name=repository;]$(echo ${GITHUB_REPOSITORY} | tr '[:upper:]' '[:lower:]')"
        echo "##[set-output name=actor;]$(echo ${GITHUB_ACTOR} | tr '[:upper:]' '[:lower:]')"
        ;;
      *)
        ;;
    esac
    ;;
  go.test)
    ${dir_name}/dep.sh --action=${action}
    eval "$(${dir_name}/dep.sh --set_default --action=${action})"

    msg="running ${CYAN}golint${NC} test ..."

    infoMsg "${msg}"
    golint .
    doneMsg "${msg}"

    msg="running ${CYAN}unit${NC} test ..."

    infoMsg "${msg}"
    go test
    doneMsg "${msg}"
    ;;
  go.build)
    ${dir_name}/dep.sh --action=${action}
    eval "$(${dir_name}/dep.sh --set_default --action=${action})"

    if [ "$(echo ${GENERATE_INFO} | tr '[[:upper:]]' '[[:lower:]]')" == "true" ]; then
      generate_git_info
    fi

    go build -o app main.go
    ;;
  go.run)
    ${dir_name}/dep.sh --action=${action}
    eval "$(${dir_name}/dep.sh --set_default --action=${action})"

    if [ "$(echo ${GENERATE_INFO} | tr '[[:upper:]]' '[[:lower:]]')" == "true" ]; then
      generate_git_info
    fi

    go run main.go
    ;;
  docker.build)
    ${dir_name}/dep.sh --action=${action}
    eval "$(${dir_name}/dep.sh --set_default --action=${action})"

    if [ "$(echo ${GENERATE_INFO} | tr '[[:upper:]]' '[[:lower:]]')" == "true" ]; then
      generate_git_info
    fi

    docker build --build-arg GO_VERSION=${GO_VERSION} --build-arg ALPINE_VERSION=${ALPINE_VERSION} -t ${IMAGE_NAME}:${IMAGE_TAG} .
    ;;
  docker.run)
    ${dir_name}/dep.sh --action=${action}
    eval "$(${dir_name}/dep.sh --set_default --action=${action})"

    infoMsg "running in local mode (docker run), visit app at ${CYAN}localhost:${HOST_PORT}/version${NC}"
    echo

    user=""

    if [ "$(echo ${RUNTIME_USER})" ]; then
      user="-u ${RUNTIME_USER}"
    fi

    docker run -it --rm ${user} -e PORT=${CONTAINER_PORT} -p ${HOST_PORT}:${CONTAINER_PORT} ${IMAGE_NAME}:${IMAGE_TAG}
    ;;
  k8s.apply)
    ${dir_name}/dep.sh --action=k8s
    eval "$(${dir_name}/dep.sh --set_default --action=k8s)"

    cd ${dir_name}/ci/k8s

    kubectl apply -f namespace.yaml
    kubectl apply -f deployment.yaml
    kubectl apply -f hpa.yaml
    kubectl apply -f service.yaml

    service=$(cat service.yaml | awk 'BEGIN{found=0}/^metadata:/ {found=1; next} /^  name:/ { if (found) {print; exit}} END{}' | awk '{print $2}' | tr -d '"')
    namespace=$(cat service.yaml | awk 'BEGIN{found=0}/^metadata:/ {found=1; next} /^  namespace:/ { if (found) {print; exit}} END{}' | awk '{print $2}' | tr -d '"')

    node_port=$(kubectl get svc/${service} -o jsonpath="{.spec.ports[0].nodePort}" -n ${namespace} 2>/dev/null || true)
    node_ips=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}" -n ${namespace} 2>/dev/null || true)
    node_ips=$(echo "${node_ips}" | head -n ${node_limits})

    remains=${limits}
    while [ ! "$(echo ${node_port})" ]; do
      (( remains-- )) || true

      infoMsg "NodePort of service/${CYAN}${service}${NC} is ${YELLOW}${node_port}${NC} (trying again in ${CYAN}${interval}${NC}, ${DPURPLE}${remains}${NC} tries remaining)"

      if [ "${remains}" == "0" ]; then
        break
      fi

      sleep ${interval}

      node_port=$(kubectl get svc/${service} -o jsonpath="{.spec.ports[0].nodePort}" -n ${namespace} 2>/dev/null || true)
    done

    for node_ip in ${node_ips}; do
      wait_for_endpoint --endpoint="${node_ip}:${node_port}/version" --status_regex="^200$" --interval=${interval} --limits="${limits}"
    done

    echo
    infoMsg "${YELLOW}$(printf '#%.0s' {1..100})${NC}"
    infoMsg "service/${PURPLE}${service}${NC} is up, visit any of the below urls"
    for node_ip in ${node_ips}; do
      infoMsg "  * ${CYAN}${node_ip}:${node_port}/version${NC}"
    done
    echo
    infoMsg "to tail last ${PURPLE}1000${NC} lines of logs: ${CYAN}kubectl logs --tail=1000 -f svc/${service} -n ${namespace} ${NC}"
    infoMsg "${YELLOW}$(printf '#%.0s' {1..100})${NC}"

    cd ${dir_name}
    ;;
  k8s.delete)
    cd ${dir_name}/ci/k8s

    kubectl delete -f service.yaml
    kubectl delete -f hpa.yaml
    kubectl delete -f deployment.yaml

    cd ${dir_name}
    ;;
  ci.up)
    ${dir_name}/dep.sh --action=ci
    eval "$(${dir_name}/dep.sh --set_default --action=ci)"

    docker run -it --rm -v $HOME/.ssh:/root/.ssh -v $HOME/.kube:/root/.kube -v ${dir_name}:/root shuliyey/technical-tests:build sh -c 'make up'
    ;;
  ci.down)
    ${dir_name}/dep.sh --action=ci
    eval "$(${dir_name}/dep.sh --set_default --action=ci)"

    docker run -it --rm -v $HOME/.ssh:/root/.ssh -v $HOME/.kube:/root/.kube -v ${dir_name}:/root shuliyey/technical-tests:build sh -c 'make down'
    ;;
  *)
    echo -e "unkown action: ${YELLOW}${action}${NC}, exiting"
    ;;
esac