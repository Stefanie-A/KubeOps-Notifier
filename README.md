# KubeOps Notifier

Reactive Kubernetes event watcher that streams cluster events and dispatches alerts to Slack (or other channels).

## Stack

- **Infra**: Terraform (EKS + VPC + S3 remote state + DynamoDB lock)
- **App**: Python / kubernetes-client + Prometheus metrics
- **AIOps Engine**: LangChain + OpenRouter (configurable free-tier models)
- **GitOps**: ArgoCD (App-of-Apps pattern)
- **Observability**: kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
- **Logging**: Loki + Fluent Bit
- **Security**: Falco (eBPF) + Falcosidekick → Slack/Loki
- **Pipeline**: GitHub Actions DevSecOps (Gitleaks → Bandit → Checkov → Trivy → Deploy → GitOps tag update)

## AIOps Flow

```
K8s Event → kubeops-notifier
                └── ALERT_REASONS match?
                        └── LangChain Agent (OpenRouter)
                                ├── describe_pod        (k8s API)
                                ├── get_pod_logs        (k8s API)
                                ├── query_prometheus    (PromQL)
                                ├── query_loki_logs     (LogQL)
                                └── list_recent_events  (k8s API)
                                        └── RCA + Remediation → Slack
```

Set `AIOPS_ENABLED=false` in the ConfigMap to disable the agent and fall back to plain alerts.

## Required GitHub Secrets

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM key with EKS/VPC permissions |
| `AWS_SECRET_ACCESS_KEY` | IAM secret |
| `SLACK_WEBHOOK_URL` | Slack incoming webhook (stored as k8s secret) |
| `GH_PAT` | GitHub PAT with repo write access (for GitOps tag commits) |

## Bootstrap Remote State

Before first `terraform apply`, create the S3 bucket and DynamoDB table:

```bash
aws s3api create-bucket --bucket kubeops-notifier-tfstate --region us-east-1
aws dynamodb create-table \
  --table-name kubeops-notifier-tflock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## Create Cluster Secrets

```bash
kubectl create secret generic kubeops-notifier-secrets \
  --from-literal=slack-webhook-url=https://hooks.slack.com/services/... \
  --from-literal=openrouter-api-key=sk-or-... \
  -n kubeops
```

Get your OpenRouter API key at [openrouter.ai/keys](https://openrouter.ai/keys). The default model is `mistralai/mistral-7b-instruct:free` — change `OPENROUTER_MODEL` in the ConfigMap to use a different one. See available free models at [openrouter.ai/models?q=free](https://openrouter.ai/models?q=free).

## GitOps Flow

1. Push to `main` → pipeline builds + scans image → pushes to GHCR
2. Pipeline updates `k8s/deployment.yaml` with new SHA tag and commits back
3. ArgoCD detects the diff and syncs the cluster automatically

## Accessing Grafana

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
# default login: admin / <GRAFANA_ADMIN_PASSWORD secret>
```

## Accessing ArgoCD UI

```bash
kubectl port-forward svc/argocd-server 8080:80 -n argocd
# get initial admin password:
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

## Replace Placeholders

Before applying ArgoCD manifests, replace these in `k8s/argocd/`:
- `$GITHUB_ORG` / `$GITHUB_REPO` — your GitHub org and repo name
- `$GRAFANA_ADMIN_PASSWORD` — desired Grafana admin password
- `$SLACK_WEBHOOK_URL` — your Slack webhook URL
