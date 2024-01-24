# Dark Nebula

Dark Nebula is a project centered around using k3s and Argo Workflow to create and manage a multitude of containers, each equipped with various penetration testing tools. This setup facilitates the development of diverse penetration testing scenarios, allowing seamless integration with various types of containers to form a comprehensive attack chain.

## Overview

The Dark Nebula project aims to streamline the process of setting up penetration testing environments by leveraging the power of Kubernetes with k3s and orchestrating workflows with Argo. This combination allows for the dynamic creation of attack scenarios and testing environments, providing an efficient way to simulate real-world attack vectors and test system resilience against penetration attempts.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- A machine with Linux OS
- Docker installed
- Kubernetes knowledge (basic)

### Installation

The `makefile` in the project root provides a set of commands to set up the environment:

- To install k3s and Argo Workflow:

  ```sh
  make install
  ```

- To install Docker registry:

  ```sh
  make docker-registry-install
  ```

### Usage

- To run the Argo workflow and forward the port for local access:

  ```sh
  make run
  ```

- To build and push Docker images to your local registry:

  ```sh
  make build-container
  ```

- To apply Argo workflows:

  ```sh
  make apply-workflow
  ```

- To delete Argo workflows:

  ```sh
  make delete-workflow
  ```

- To restart the k3s service:

  ```sh
  make restart-k3s
  ```

### Uninstallation

To remove the installed components:

```sh
make uninstall
```
