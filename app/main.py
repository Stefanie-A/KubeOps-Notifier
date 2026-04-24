"""
KubeOps Notifier - Reactive Kubernetes event watcher and notifier.
Watches cluster events and dispatches alerts to configured channels (Slack, etc.)
"""

import os
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from threading import Thread

from kubernetes import client, config, watch
import requests
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from aiops.agent import analyze_incident, IncidentContext

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO").upper())
log = logging.getLogger("kubeops-notifier")

SLACK_WEBHOOK_URL = os.environ["SLACK_WEBHOOK_URL"]
WATCH_NAMESPACES  = os.getenv("WATCH_NAMESPACES", "default").split(",")
AIOPS_ENABLED     = os.getenv("AIOPS_ENABLED", "true").lower() == "true"

ALERT_REASONS = {"BackOff", "OOMKilling", "Failed", "Evicted", "NodeNotReady"}

# Prometheus metrics
EVENTS_TOTAL = Counter(
    "kubeops_events_total",
    "Total Kubernetes events processed",
    ["namespace", "reason"]
)
NOTIFICATION_ERRORS = Counter(
    "kubeops_notification_errors_total",
    "Total failed notification deliveries"
)


def send_slack(message: str):
    try:
        requests.post(SLACK_WEBHOOK_URL, json={"text": message}, timeout=5)
    except Exception as e:
        log.error("Failed to send Slack notification: %s", e)
        NOTIFICATION_ERRORS.inc()


def watch_events(namespace: str):
    v1 = client.CoreV1Api()
    w = watch.Watch()
    log.info("Watching events in namespace: %s", namespace)
    for event in w.stream(v1.list_namespaced_event, namespace=namespace):
        obj = event["object"]
        reason = obj.reason or ""
        if reason in ALERT_REASONS:
            EVENTS_TOTAL.labels(namespace=namespace, reason=reason).inc()

            # Base alert
            msg = (
                f":warning: *KubeOps Alert* | `{namespace}`\n"
                f"*Reason:* {reason}\n"
                f"*Object:* {obj.involved_object.kind}/{obj.involved_object.name}\n"
                f"*Message:* {obj.message}"
            )

            # AIOps enrichment — run agent and append RCA
            if AIOPS_ENABLED:
                log.info("Running AIOps analysis for %s/%s", namespace, reason)
                ctx = IncidentContext(
                    namespace=namespace,
                    reason=reason,
                    kind=obj.involved_object.kind,
                    name=obj.involved_object.name,
                    message=obj.message or "",
                )
                rca = analyze_incident(ctx)
                msg += f"\n\n:robot_face: *AIOps Analysis*\n{rca}"

            log.warning(msg)
            send_slack(msg)


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/healthz", "/readyz"):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        elif self.path == "/metrics":
            self.send_response(200)
            self.send_header("Content-Type", CONTENT_TYPE_LATEST)
            self.end_headers()
            self.wfile.write(generate_latest())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, *args):
        pass  # suppress access logs


def start_health_server():
    server = HTTPServer(("0.0.0.0", 8080), HealthHandler)
    log.info("Health server listening on :8080")
    server.serve_forever()


if __name__ == "__main__":
    try:
        config.load_incluster_config()
    except config.ConfigException:
        config.load_kube_config()

    Thread(target=start_health_server, daemon=True).start()

    threads = [Thread(target=watch_events, args=(ns.strip(),), daemon=True)
               for ns in WATCH_NAMESPACES]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
