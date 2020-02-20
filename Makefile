info.generate:
	./action.sh --action=info.generate

go.test:
	./action.sh --action=go.test

go.build:
	./action.sh --action=go.build

go.run:
	./action.sh --action=go.run

docker.info:
	./action.sh --action=docker.info

docker.build:
	./action.sh --action=docker.build

docker.run:
	./action.sh --action=docker.run

k8s.apply:
	./action.sh --action=k8s.apply

k8s.delete:
	./action.sh --action=k8s.delete

up:
	make k8s.apply

down:
	make k8s.delete

ci.up:
	./action.sh --action=ci.up

ci.down:
	./action.sh --action=ci.down