# Q2 - Kubernetes

## 1. summary

`kubectl` is used to deploy application manifests to kubernetes cluster

## 2. local build environment requirements

* inherit local build environment requirements defined in [main](../README.md#12-local-build-environment-requirements)
* [kubectl](https://github.com/kubernetes/kubernetes/tree/master/pkg/kubectl)
* [jq](https://github.com/stedolan/jq)

## 3. make tasks

#### 3.1 up

deploy application manifests to kubernetes cluster

```bash
make up
```

#### 3.2 down

delete application manifests from kubernetes cluster

```bash
make down
```

### 4. kubectl - kubernetes

instructions to deploy/tear down applications to kubernetes cluster through plain `kubectl`

assuming your local `kubectl` is already pointing to the desired kubernetes context (this can be verified through `kubectl config current-context`)

#### 4.1 deploy

deploy application manifests to kubernetes cluster

```bash
cd ci/k8s
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f hpa.yaml
kubectl apply -f service.yaml
# list of node ips can be obtained
kubectl get nodes --namespace technical-test -o jsonpath="{.items[0].status.addresses[0].address}"
# node port can be obtained
kubectl get service/technical-tests -o jsonpath="{.spec.ports[0].nodePort}" -n technical-test
# pick one of the node ips and visit endpoint <node_ip>:<node_port>/version
```

#### 4.2 tear down

delete application manifests from kubernetes cluster

```bash
cd ci/k8s
kubectl delete -f service.yaml
kubectl delete -f hpa.yaml
kubectl delete -f deployment.yaml
```

## 4. notes

horizontal pod autoscaler is defined to autoscale the kubernetes deployment manifests with `minReplicas: 3`, `maxReplicas: 10` when `targetCPUUtilizationPercentage` exceed `50`%. Happy `k8s`
