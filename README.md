# Dev

## Show pods

```
kubectl -n argo get pods
```

## Apply / Delete workflow

```
kubectl -n argo apply -f workflows/whois-recon-pocket.yaml
kubectl -n argo delete -f workflows/whois-recon-pocket.yaml
```

## Local Container build

```
sudo docker build -t dark-nebula-whois -f local_containers/whois.Dockerfile .
docker save -o dark-nebula-whois.tar dark-nebula-whois
```


