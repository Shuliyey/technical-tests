#!/usr/bin/env bash

dir_name=$(cd `dirname $0` && pwd)
work_dir=/app

docker run -it --rm -v ${dir_name}:${work_dir} -w "${work_dir}" golang:${GO_VERSION:-1.13}-alpine sh