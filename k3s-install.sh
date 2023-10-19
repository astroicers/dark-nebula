curl -sfL https://get.k3s.io | sh - 
# Check for Ready node, takes ~30 seconds 
sudo k3s kubectl get node 

sudo groupadd k3s
sudo usermod -aG k3s `whoami`
sudo chown `whoami`:k3s /etc/rancher/k3s/k3s.yaml
kubectl get pods
