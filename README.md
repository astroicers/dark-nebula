# Dev

## Install

```
k3s-install.sh && argo-install.sh && docker-registry-install.sh
```

## Run

```
argo-run.sh
```

## Show pods

```
kubectl -n argo get pods
```

## Local build container to self-managed registry 

```
sudo docker build -t whois-local -f dockerfiles/whois.Dockerfile .
sudo docker tag whois-local localhost:5000/whois-local
sudo docker push localhost:5000/whois-local
```

## Apply / Delete workflow

```
kubectl -n argo apply -f workflows/templates/*.yaml
kubectl -n argo apply -f workflows/main-workflow.yaml

kubectl -n argo delete -f workflows/templates/*.yaml
kubectl -n argo delete -f workflows/main-workflow.yaml
```
