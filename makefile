.PHONY: install run show-pods build-container apply-workflow delete-workflow restart-k3s

help:
	@echo "Available commands:"
	@echo "  make install         Install k3s, Argo"
	@echo "  make docker-registry Install Docker registry"
	@echo "  make run             Run Argo workflow"
	@echo "  make show-pods       Show pods in the Argo namespace"
	@echo "  make build-container Build and push Docker images"
	@echo "  make apply-workflow  Apply Argo workflows"
	@echo "  make delete-workflow Delete Argo workflows"
	@echo "  make restart-k3s     Restart k3s service"

.DEFAULT_GOAL := help

install:
	# ./k3s-install.sh
	curl -sfL https://get.k3s.io | sh -
	sudo k3s kubectl get node 
	sudo groupadd k3s
	sudo usermod -aG k3s `whoami`
	sudo chown `whoami`:k3s /etc/rancher/k3s/k3s.yaml
	kubectl get pods

	# ./argo-install.sh
	kubectl create namespace argo
	kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.0/install.yaml
	kubectl patch deployment \
	argo-server \
	--namespace argo \
	--type='json' \
	-p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
	"server",
	"--auth-mode=server"
	]}]'

docker-registry:
	# ./docker-registry-install.sh
	sudo docker run -d -p 5000:5000 --name registry registry:2
	echo 'mirrors:' | sudo tee -a /etc/rancher/k3s/k3s.yaml
	echo '  "localhost:5000":' | sudo tee -a /etc/rancher/k3s/k3s.yaml
	echo '    endpoint:' | sudo tee -a /etc/rancher/k3s/k3s.yaml
	echo '    - "http://localhost:5000"' | sudo tee -a /etc/rancher/k3s/k3s.yaml
	sudo systemctl restart k3s

run:
	# ./argo-run.sh
	kubectl -n argo port-forward deployment/argo-server 2746:2746

show-pods:
	kubectl -n argo get pods

build-container:
	sudo docker build -t whois-local -f dockerfiles/whois.Dockerfile .
	sudo docker tag whois-local localhost:5000/whois-local
	sudo docker push localhost:5000/whois-local

apply-workflow:
	for file in workflows/templates/*.yaml; do \
		kubectl -n argo apply -f "$$file"; \
	done
	kubectl -n argo apply -f workflows/main-workflow.yaml

delete-workflow:
	for file in workflows/templates/*.yaml; do \
		kubectl -n argo delete -f "$$file"; \
	done
	kubectl -n argo delete -f workflows/main-workflow.yaml

restart-k3s:
	sudo systemctl restart k3s
