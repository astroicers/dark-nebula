.PHONY: install uninstall docker-registry-install run show-pods build-container apply-workflow delete-workflow restart-k3s

help:
	@echo "Available commands:"
	@echo "  make install               - Install k3s and Argo"
	@echo "  make uninstall             - Uninstall k3s and Argo Workflow"
	@echo "  make docker-registry-install - Install Docker registry"
	@echo "  make run                   - Run Argo workflow"
	@echo "  make show-pods             - Show pods in the Argo namespace"
	@echo "  make build-container       - Build and push Docker images"
	@echo "  make apply-workflow        - Apply Argo workflows"
	@echo "  make delete-workflow       - Delete Argo workflows"
	@echo "  make restart-k3s           - Restart k3s service"
	@echo "  make minio-install         - Install Minio"

.DEFAULT_GOAL := help

install:
	# Install k3s
	curl -sfL https://get.k3s.io | sh -
	sudo k3s kubectl get node 
	sudo groupadd k3s
	sudo usermod -aG k3s `whoami`
	sudo chown `whoami`:k3s /etc/rancher/k3s/k3s.yaml
	kubectl get pods

	# Install Argo Workflow
	kubectl create namespace argo
	kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.4/install.yaml
	kubectl patch deployment argo-server --namespace argo --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["server", "--auth-mode=server","--access-control-allow-origin=*"]}]'

uninstall:
	# Uninstall Argo Workflow
	echo "Uninstalling Argo Workflow..."
	kubectl delete namespace argo

	# Uninstall k3s
	echo "Uninstalling k3s..."
	sudo /usr/local/bin/k3s-killall.sh
	sudo /usr/local/bin/k3s-uninstall.sh

	# Remove user and group
	echo "Removing user and group..."
	sudo gpasswd -d `whoami` k3s
	sudo groupdel k3s

	# Remove k3s related files
	echo "Cleaning up k3s related files..."
	sudo rm -rf /etc/rancher/k3s

	echo "Uninstallation completed."

docker-registry-install:
	kubectl apply -f workflows/docker-registry/argo-role.yaml                
	kubectl apply -f workflows/docker-registry/argo-rolebinding.yaml
	kubectl create -f workflows/docker-registry/docker-registry.yaml

run:
	# Run Argo Workflow
	kubectl -n argo port-forward deployment/argo-server 2746:2746

show-pods:
	kubectl -n argo get pods

build-container:
	for file in dockerfiles/*.Dockerfile; do \
		base_name=$$(basename $$file .Dockerfile); \
		image_name="$$base_name-local"; \
		sudo docker build -t $$image_name -f $$file .; \
		sudo docker tag $$image_name localhost:30000/$$image_name; \
		sudo docker push localhost:30000/$$image_name; \
		done

apply-workflow:
	for file in workflows/subdomain-enumeration/*.yaml; do \
		if [ "$$file" != "workflows/subdomain-enumeration/subdomain-enumeration.yaml" ]; then \
		kubectl apply -f "$$file"; \
		fi; \
		done
	kubectl apply -f workflows/subdomain-enumeration/subdomain-enumeration.yaml

delete-workflow:
	for file in workflows/subdomain-enumeration/*.yaml; do \
		if [ "$$file" != "workflows/subdomain-enumeration/subdomain-enumeration.yaml" ]; then \
		kubectl delete -f "$$file"; \
		fi; \
		done
	kubectl delete -f workflows/subdomain-enumeration/subdomain-enumeration.yaml

restart-k3s:
	sudo systemctl restart k3s

redis-install:
	kubectl apply -f workflows/redis/redis-deployment.yaml
	kubectl apply -f workflows/redis/redis-service.yaml

minio-install:
	@export MINIO_ACCESS_KEY=$$(openssl rand -base64 12); \
	export MINIO_SECRET_KEY=$$(openssl rand -base64 24); \
	kubectl create secret generic minio-secret \
		--from-literal=accesskey=$$MINIO_ACCESS_KEY \
		--from-literal=secretkey=$$MINIO_SECRET_KEY; \
	kubectl apply -f workflows/minio/minio-deployment.yaml; \
	kubectl apply -f workflows/minio/minio-service.yaml
