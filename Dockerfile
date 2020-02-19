ARG GO_VERSION=1.13
ARG ALPINE_VERSION=3.11

######################## builder ########################

FROM golang:${GO_VERSION}-alpine as builder

ENV GO111MODULE=on

WORKDIR /app

ADD ./ /app

RUN go build -o golang-test  .

######################## runtime ########################

FROM alpine:${ALPINE_VERSION}

LABEL maintainer="叶泽宇/Zeyu Ye <zeyu.ye@contino.io>"

WORKDIR /app

USER nobody

ENV PORT=8000
ENV BIND_HOST=0.0.0.0

EXPOSE ${PORT}

ENTRYPOINT ["./golang-test"]

COPY --from=builder /app/golang-test /app/golang-test
ADD ./info.txt /app/info.txt