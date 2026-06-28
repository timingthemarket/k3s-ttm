# k3s-ttm

Kubernetes manifests for the k3s cluster. Each top-level `*.yaml` is a deployment
plus its associated services / routes. Secrets are managed out of band via
[secrets/manage-secret.sh](secrets/manage-secret.sh) and a per-app `.env` file.

## Layout

```
.
├── article-news-raw.yaml      # Deployment + Service + Traefik route
├── rabbitmq.yaml              # RabbitMQ with management UI
├── securities-masterdata.yaml # Deployment + Service
├── uptime-kuma.yaml           # Uptime Kuma
└── secrets/
    ├── manage-secret.sh       # Helper for applying secrets from .env files
    ├── article-news-raw/.env  # Not committed
    └── rabbitmq/.env          # Not committed
```

## Deploy a secret

Secrets are sourced from a `.env` file inside `secrets/<app-name>/`. The folder
name becomes the secret name (and must match the `secretRef.name` used in the
deployment).

```sh
# Create / update a secret from secrets/<app-name>/.env
./secrets/manage-secret.sh <app-name>

# Examples
./secrets/manage-secret.sh article-news-raw
./secrets/manage-secret.sh rabbitmq
```

The script runs `kubectl create secret generic ... --dry-run=client -o yaml |
kubectl apply -f -`, so it is safe to re-run to update an existing secret.

After updating a secret, restart the deployment so pods pick up the new values
(see below).

## Deploy / apply a manifest

```sh
kubectl apply -f <file>.yaml

# Examples
kubectl apply -f securities-masterdata.yaml
kubectl apply -f rabbitmq.yaml
```

## Restart a deployment

Triggers a rolling restart without changing the manifest. Useful after updating
a secret or pushing a new image to the same tag (e.g. `:latest`).

```sh
kubectl rollout restart deployment/<name>

# Examples
kubectl rollout restart deployment/securities-masterdata
kubectl rollout restart deployment/article-news-raw

# Watch the rollout
kubectl rollout status deployment/<name>
```

## Deploy a new container image

The in-cluster registry lives at `192.168.68.63:5000`. Typical flow:

```sh
# 1. Build and push the image
docker build -t 192.168.68.63:5000/<image>:<tag> .
docker push 192.168.68.63:5000/<image>:<tag>
```

Then either:

**A. Same tag (e.g. `:latest`)** — manifest unchanged, just restart:

```sh
kubectl rollout restart deployment/<name>
```

**B. New tag** — update the `image:` field in the manifest and re-apply:

```sh
kubectl apply -f <file>.yaml
```

Or set the image directly without editing the file:

```sh
kubectl set image deployment/<name> <container>=192.168.68.63:5000/<image>:<tag>

# Example
kubectl set image deployment/securities-masterdata \
  securities-masterdata=192.168.68.63:5000/securities_masterdata:v1.2.3
```

## Useful inspection commands

```sh
kubectl get deploy,svc,pod
kubectl describe deployment/<name>
kubectl logs deployment/<name> -f
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>          # roll back to previous revision
```
