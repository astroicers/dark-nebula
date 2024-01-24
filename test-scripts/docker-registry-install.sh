sudo docker run -d -p 5000:5000 --name registry registry:2
echo 'mirrors:' | sudo tee -a /etc/rancher/k3s/k3s.yaml
echo '  "localhost:5000":' | sudo tee -a /etc/rancher/k3s/k3s.yaml
echo '    endpoint:' | sudo tee -a /etc/rancher/k3s/k3s.yaml
echo '    - "http://localhost:5000"' | sudo tee -a /etc/rancher/k3s/k3s.yaml
sudo systemctl restart k3s