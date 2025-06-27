# DevOps Workflow Example

[![CI Status](https://github.com/justrunme/devops-workflow/actions/workflows/test-pipeline.yaml/badge.svg)](https://github.com/justrunme/devops-workflow/actions/workflows/test-pipeline.yaml)

This repository demonstrates a basic DevOps workflow for a microservices application, including local development with Docker Compose, deployment to a local Kubernetes cluster using Kind and Terraform, and a CI/CD pipeline with GitHub Actions.

## Project Overview

The application consists of three main components:

-   **Frontend API (`frontend-api`):** A Node.js (Express) application that exposes an API endpoint (`/convert`) to accept Markdown content, processes it (currently a simple conversion), and returns HTML. It interacts with Redis.
-   **Backend Worker (`backend-worker`): A Python application that would typically process tasks from Redis. (Note: In the current setup, the frontend directly processes the markdown for simplicity, but the backend worker is included for architectural completeness and demonstrates a worker pattern.)
-   **Redis (`redis`):** A Redis instance used as a data store for tasks and communication between the frontend and backend.

## Architecture

The application follows a microservices architecture:

```
+-----------------+     +-----------------+     +-----------------+
|                 |     |                 |     |                 |
|  Frontend API   |<--->|      Redis      |<--->|  Backend Worker |
|  (Node.js)      |     |                 |     |  (Python)       |
|                 |     |                 |     |                 |
+-----------------+     +-----------------+     +-----------------+
```

-   The Frontend API exposes a RESTful interface.
-   Redis acts as a message broker/data store.
-   The Backend Worker is designed to consume tasks from Redis.

## Local Development

You can run the entire application locally using Docker Compose.

### Prerequisites

-   Docker Desktop (or Docker Engine and Docker Compose)

### Steps

1.  **Build and Run:**
    ```bash
    docker-compose up --build
    ```
2.  **Access Frontend API:**
    The Frontend API will be available at `http://localhost:3000`.

3.  **Test the API:**
    You can send a POST request to the `/convert` endpoint:
    ```bash
    curl -X POST -H "Content-Type: application/json" \
         -d '{"markdown": "# Hello from Local!\n\nThis is a **test**."}' \
         http://localhost:3000/convert
    ```
    Expected output:
    ```json
    {"id":"test-id","html":"<h1>Hello from Local!</h1>\n\nThis is a <strong>test</strong>.","status":"completed"}
    ```

## Deployment to Kubernetes (Kind & Terraform)

This project uses Kind (Kubernetes in Docker) for local Kubernetes cluster creation and Terraform for deploying the application components.

### Prerequisites

-   [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
-   [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
-   [Terraform](https://developer.hashicorp.com/terraform/downloads)

### Steps

1.  **Create Kind Cluster:**
    ```bash
    kind create cluster --name devops-workflow-kind-cluster
    ```

2.  **Load Docker Images into Kind:**
    Build your Docker images and load them into the Kind cluster. Replace `your-docker-username` with your Docker Hub or GitHub Container Registry username.
    ```bash
    # Build images (example for frontend-api)
    docker build -t your-docker-username/devops-workflow-frontend-api:latest ./frontend-api
    docker build -t your-docker-username/devops-workflow-backend-worker:latest ./backend-worker

    # Load images into Kind
    kind load docker-image your-docker-username/devops-workflow-frontend-api:latest --name devops-workflow-kind-cluster
    kind load docker-image your-docker-username/devops-workflow-backend-worker:latest --name devops-workflow-kind-cluster
    ```

3.  **Initialize Terraform:**
    Navigate to the Terraform directory and initialize it.
    ```bash
    cd infra/terraform
    terraform init
    ```

4.  **Apply Terraform Configuration:**
    Deploy the Kubernetes resources using Terraform. Replace `your-docker-username` and `your-image-tag` with your actual values.
    ```bash
    terraform apply -auto-approve \
      -var="docker_username=your-docker-username" \
      -var="image_tag=your-image-tag" \
      -var="kubeconfig_path=$HOME/.kube/config"
    ```
    This will deploy Redis, Frontend API, and Backend Worker deployments and services to your Kind cluster.

5.  **Verify Deployment:**
    Check the status of your pods and services:
    ```bash
    kubectl get pods
    kubectl get services
    ```

6.  **Access Frontend API (via NodePort):**
    Get the NodePort for the `frontend-api` service:
    ```bash
    NODE_PORT=$(kubectl get service frontend-api -o jsonpath='{.spec.ports[0].nodePort}')
    echo "Frontend API NodePort: $NODE_PORT"
    ```
    You can then access the API via `http://localhost:$NODE_PORT`.

7.  **Cleanup Kind Cluster:**
    ```bash
    kind delete cluster --name devops-workflow-kind-cluster
    ```

### Kubernetes and Terraform Configuration

-   **`infra/k8s/`**: Contains raw Kubernetes YAML manifests for Redis, Frontend API, and Backend Worker. These are used as a reference for the Terraform configurations.
-   **`infra/terraform/main.tf`**: Defines the Kubernetes provider and the deployments/services for Redis, Frontend API, and Backend Worker using Terraform's Kubernetes provider.
    -   The `kubernetes` provider is explicitly configured with `config_path = var.kubeconfig_path` to ensure it connects to the correct Kind cluster.
-   **`infra/terraform/variables.tf`**: Defines input variables for Terraform, including `docker_username`, `image_tag`, and `kubeconfig_path`.

## CI/CD Pipeline (GitHub Actions)

The `.github/workflows/test-pipeline.yaml` defines the CI/CD pipeline for this project. It automates building, testing, and deploying the application to a Kind cluster.

### Workflow Steps

1.  **Checkout repository:** Clones the repository.
2.  **Set up Docker Buildx:** Configures Docker Buildx for multi-platform builds.
3.  **Log in to GitHub Container Registry:** Authenticates with GitHub Container Registry to push and pull Docker images.
4.  **Build and push Docker images:** Builds `frontend-api` and `backend-worker` Docker images and pushes them to GitHub Container Registry. Images are also loaded into the local Docker daemon for Kind.
5.  **Install Kind:** Downloads and installs the Kind CLI.
6.  **Create Kind cluster:** Creates a new Kind cluster.
7.  **Set KUBECONFIG for Terraform:** Exports the `KUBECONFIG` environment variable to point to the Kind cluster's kubeconfig file, ensuring Terraform can connect.
8.  **Check Kind cluster:** Verifies Kubernetes cluster connectivity by listing nodes (`kubectl get nodes`).
9.  **Load Docker images into Kind cluster:** Loads the built Docker images from the local Docker daemon into the Kind cluster.
10. **Debug KUBECONFIG path & Check Kubernetes access:** Additional debugging steps to confirm `KUBECONFIG` is set and `kubectl get pods -A` works.
11. **Set up Terraform:** Installs a specific version of Terraform.
12. **Terraform Init:** Initializes the Terraform working directory.
13. **Terraform Apply:** Applies the Terraform configuration to deploy the application to the Kind cluster. It passes `docker_username`, `image_tag`, and `kubeconfig_path` as variables.
14. **Wait for deployments to be ready:** Waits for Redis, Frontend API, and Backend Worker deployments to become available.
15. **Get Frontend API NodePort:** Retrieves the NodePort for the Frontend API service.
16. **Describe frontend pod & Logs of frontend-api:** Debugging steps to inspect the frontend-api pod's status and logs.
17. **Test Frontend API:** This is the core testing step.
    -   It initiates a `kubectl port-forward` from the `frontend-api` service to `localhost:8080`.
    -   It includes a robust wait loop using `nc -z localhost 8080` to ensure the port-forward is ready before proceeding.
    -   It sends a `POST` request with Markdown content to `http://localhost:8080/convert`.
    -   It parses the JSON response using `jq`, extracting `id`, `status`, and `html`.
    -   It validates the parsed `TASK_ID` and checks the `HTML` content for expected `<h1>` and `<strong>` tags using `grep -q`.
    -   Includes comprehensive logging for debugging.
18. **Cleanup Kind cluster:** Deletes the Kind cluster, ensuring a clean environment for subsequent runs. This step runs even if previous steps fail (`if: always()`).

## Testing

The CI pipeline includes a comprehensive test for the Frontend API.

### Test Details

The `Test Frontend API` step performs the following actions:

1.  **Port Forwarding:** Establishes a port-forward from the `frontend-api` service (port 80) to `localhost:8080` on the GitHub Actions runner.
2.  **Port Readiness Check:** Uses a `for` loop with `nc -z localhost 8080` to wait until `localhost:8080` is actively listening, ensuring the port-forward is fully established before sending requests.
3.  **API Request:** Sends a `POST` request to `http://localhost:8080/convert` with a JSON payload containing Markdown content.
    ```json
    {"markdown": "# Hello from Kind!\n\nThis is a **test**."}
    ```
4.  **Response Parsing and Validation:**
    -   The raw API response is logged for debugging.
    -   The response is validated as a valid JSON using `jq -e .`.
    -   `TASK_ID`, `STATUS`, and `HTML` are extracted from the JSON response using `jq -r`.
    -   The `TASK_ID` is checked to ensure it's not empty or "null".
5.  **HTML Content Verification:**
    -   The extracted `HTML` content is checked using `grep -q` to ensure it contains the expected `<h1>Hello from Kind!</h1>` and `<strong>test</strong>` tags, confirming the Markdown conversion was successful.
6.  **Cleanup:** The `kubectl port-forward` process is terminated.

This robust testing approach ensures that the Frontend API is deployed correctly, is accessible, and functions as expected within the Kubernetes environment.

