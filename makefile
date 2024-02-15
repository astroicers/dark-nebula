.PHONY: help install uninstall k3s-install argo-workflow-install docker-registry-install run-argo-workflow show-pods build-container apply-workflow delete-workflow restart-k3s redis-install redisinsight-install minio-install apply-share-volume delete-share-volume website-backend-install website-backend-build website-frontend-install apply-subdomain-enumeration delete-subdomain-enumeration apply-subdomain-ping-check delete-subdomain-ping-check apply-network-scanning delete-network-scanning apply-web-fingerprint-scanning delete-web-fingerprint-scanning apply-web-vuln-scanning delete-web-vuln-scanning apply-web-subdirectory-enumeration delete-web-subdirectory-enumeration

help:
	@echo "Available commands:"
	@echo "  make install               - Installs k3s, Argo, Docker registry, Redis, RedisInsight, and Minio"
	@echo "  make uninstall             - Uninstalls k3s and Argo Workflow"
	@echo "  make docker-registry-install - Installs Docker registry"
	@echo "  make run-argo-workflow     - Runs Argo workflow"
	@echo "  make show-pods             - Displays pods in the Argo namespace"
	@echo "  make build-container       - Builds and pushes Docker images"
	@echo "  make restart-k3s           - Restarts k3s service"
	@echo "  make redis-install         - Installs Redis"
	@echo "  make redisinsight-install  - Installs RedisInsight"
	@echo "  make minio-install         - Installs Minio"
	@echo "  make website-backend-install - Installs website backend"
	@echo "  make website-backend-build - Builds website backend"
	@echo "  make website-frontend-install - Installs website frontend"
	@echo "  make apply-share-volume    - Applies shared volume configuration"
	@echo "  make delete-share-volume   - Deletes shared volume configuration"
	@echo "  make apply-subdomain-enumeration - Applies subdomain enumeration workflow"
	@echo "  make delete-subdomain-enumeration - Deletes subdomain enumeration workflow"
	@echo "  make apply-subdomain-ping-check - Applies subdomain ping check workflow"
	@echo "  make delete-subdomain-ping-check - Deletes subdomain ping check workflow"
	@echo "  make apply-network-scanning - Applies network scanning workflow"
	@echo "  make delete-network-scanning - Deletes network scanning workflow"
	@echo "  make apply-web-fingerprint-scanning - Applies web fingerprint scanning workflow"
	@echo "  make delete-web-fingerprint-scanning - Deletes web fingerprint scanning workflow"
	@echo "  make apply-web-vuln-scanning - Applies web vulnerability scanning workflow"
	@echo "  make delete-web-vuln-scanning - Deletes web vulnerability scanning workflow"
	@echo "  make apply-web-subdirectory-enumeration - Applies web subdirectory enumeration workflow"
	@echo "  make delete-web-subdirectory-enumeration - Deletes web subdirectory enumeration workflow"

.DEFAULT_GOAL := help

install: k3s-install argo-workflow-install docker-registry-install redis-install redisinsight-install minio-install website-install apply-share-volume

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

k3s-install:
	# Install k3s
	curl -sfL https://get.k3s.io | sh -
	sudo k3s kubectl get node 
	sudo groupadd k3s
	sudo usermod -aG k3s `whoami`
	sudo chown `whoami`:k3s /etc/rancher/k3s/k3s.yaml
	kubectl get pods

argo-workflow-install:
	# Install Argo Workflow
	kubectl create namespace argo
	kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.4/install.yaml
	kubectl patch deployment argo-server --namespace argo --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["server", "--auth-mode=server","--access-control-allow-origin=*"]}]'

docker-registry-install:
	kubectl apply -f workflows/docker-registry/argo-role.yaml                
	kubectl apply -f workflows/docker-registry/argo-rolebinding.yaml
	kubectl create -f workflows/docker-registry/docker-registry.yaml

run-argo-workflow:
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

restart-k3s:
	sudo systemctl restart k3s

redis-install:
	kubectl apply -f workflows/redis/redis-deployment.yaml
	kubectl apply -f workflows/redis/redis-service.yaml

redisinsight-install:
	kubectl apply -f workflows/redisinsight/redisinsight-deployment.yaml
	kubectl apply -f workflows/redisinsight/redisinsight-service.yaml

minio-install:
	@export MINIO_ACCESS_KEY=$$(openssl rand -base64 12); \
	export MINIO_SECRET_KEY=$$(openssl rand -base64 24); \
	kubectl create secret generic minio-secret \
		--from-literal=accesskey=$$MINIO_ACCESS_KEY \
		--from-literal=secretkey=$$MINIO_SECRET_KEY; \
	kubectl apply -f workflows/minio/minio-deployment.yaml; \
	kubectl apply -f workflows/minio/minio-service.yaml

website-backend-install:
	kubectl apply -f workflows/website-backend/backend-deployment.yaml
	kubectl apply -f workflows/website-backend/backend-service.yaml

website-backend-build:
	git clone https://github.com/astroicers/dark-nebula-backend.git dark-nebula-backend; \
	sudo docker build -t dark-nebula-backend -f dark-nebula-backend/Dockerfile ./dark-nebula-backend; \
	sudo docker tag dark-nebula-backend localhost:30000/dark-nebula-backend; \
	sudo docker push localhost:30000/dark-nebula-backend; \

website-frontend-install:	
	kubectl apply -f workflows/website-frontend/frontend-deployment.yaml
	kubectl apply -f workflows/website-frontend/frontend-service.yaml

apply-share-volume:
	kubectl apply -f workflows/share-volume/share-pv.yaml
	kubectl apply -f workflows/share-volume/share-pvc.yaml

delete-share-volume:
	kubectl delete pvc shared-pvc
	kubectl delete pv shared-pv

# Workflows

apply-subdomain-enumeration:
	for file in workflows/subdomain-enumeration/*.yaml; do \
		if [ "$$file" != "workflows/subdomain-enumeration/subdomain-enumeration.yaml" ]; then \
		kubectl apply -f "$$file"; \
		fi; \
		done
	kubectl create -f workflows/subdomain-enumeration/subdomain-enumeration.yaml

delete-subdomain-enumeration:
	for file in workflows/subdomain-enumeration/*.yaml; do \
		if [ "$$file" != "workflows/subdomain-enumeration/subdomain-enumeration.yaml" ]; then \
		kubectl delete -f "$$file"; \
		fi; \
		done
	kubectl delete -f workflows/subdomain-enumeration/subdomain-enumeration.yaml

apply-subdomain-ping-check:
	for file in workflows/subdomain-ping-check/*.yaml; do \
		if [ "$$file" != "workflows/subdomain-ping-check/subdomain-ping-check.yaml" ]; then \
		kubectl apply -f "$$file"; \
		fi; \
		done
	kubectl create -f workflows/subdomain-ping-check/subdomain-ping-check.yaml

delete-subdomain-ping-check:
	for file in workflows/subdomain-ping-check/*.yaml; do \
		if [ "$$file" != "workflows/subdomain-ping-check/subdomain-ping-check.yaml" ]; then \
		kubectl delete -f "$$file"; \
		fi; \
		done
	kubectl delete -f workflows/subdomain-ping-check/subdomain-ping-check.yaml

apply-network-scanning:
	for file in workflows/network-scanning/*.yaml; do \
		if [ "$$file" != "workflows/network-scanning/network-scanning.yaml" ]; then \
		kubectl apply -f "$$file"; \
		fi; \
		done
	kubectl create -f workflows/network-scanning/network-scanning.yaml

delete-network-scanning:
	for file in workflows/network-scanning/*.yaml; do \
		if [ "$$file" != "workflows/network-scanning/network-scanning.yaml" ]; then \
		kubectl delete -f "$$file"; \
		fi; \
		done
	kubectl delete -f workflows/network-scanning/network-scanning.yaml

apply-web-fingerprint-scanning:
	for file in workflows/web-fingerprint-scanning/*.yaml; do \
		if [ "$$file" != "workflows/web-fingerprint-scanning/web-fingerprint-scanning.yaml" ]; then \
		kubectl apply -f "$$file"; \
		fi; \
		done
	kubectl create -f workflows/web-fingerprint-scanning/web-fingerprint-scanning.yaml

delete-web-fingerprint-scanning:
	for file in workflows/web-fingerprint-scanning/*.yaml; do \
		if [ "$$file" != "workflows/web-fingerprint-scanning/web-fingerprint-scanning.yaml" ]; then \
		kubectl delete -f "$$file"; \
		fi; \
		done
	kubectl delete -f workflows/web-fingerprint-scanning/web-fingerprint-scanning.yaml

apply-web-vuln-scanning:
	for file in workflows/web-vuln-scanning/*.yaml; do \
		if [ "$$file" != "workflows/web-vuln-scanning/web-vuln-scanning.yaml" ]; then \
		kubectl apply -f "$$file"; \
		fi; \
		done
	kubectl create -f workflows/web-vuln-scanning/web-vuln-scanning.yaml

delete-web-vuln-scanning:
	for file in workflows/web-vuln-scanning/*.yaml; do \
		if [ "$$file" != "workflows/web-vuln-scanning/web-vuln-scanning.yaml" ]; then \
		kubectl delete -f "$$file"; \
		fi; \
		done
	kubectl delete -f workflows/web-vuln-scanning/web-vuln-scanning.yaml

apply-web-subdirectory-enumeration:
	for file in workflows/web-subdirectory-enumeration/*.yaml; do \
		if [ "$$file" != "workflows/web-subdirectory-enumeration/web-subdirectory-enumeration.yaml" ]; then \
		kubectl apply -f "$$file"; \
		fi; \
		done
	@if kubectl get configmap gobuster-wordlist > /dev/null 2>&1; then \
		echo "ConfigMap 'gobuster-wordlist' already exists."; \
	else \
		echo "Creating ConfigMap 'gobuster-wordlist'..."; \
		kubectl create configmap gobuster-wordlist --from-file=wordlists/wordlists; \
	fi
	kubectl create -f workflows/web-subdirectory-enumeration/web-subdirectory-enumeration.yaml

delete-web-subdirectory-enumeration:
	for file in workflows/web-subdirectory-enumeration/*.yaml; do \
		if [ "$$file" != "workflows/web-subdirectory-enumeration/web-subdirectory-enumeration.yaml" ]; then \
		kubectl delete -f "$$file"; \
		fi; \
		done
	kubectl delete -f workflows/web-subdirectory-enumeration/web-subdirectory-enumeration.yaml
	kubectl delete configmap gobuster-wordlist