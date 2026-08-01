groups:
  - name: ecs-common-alerts
    rules:

      - alert: ECSTargetDown
        expr: up{job="ecs"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "ECS service {{ $labels.service }} unreachable"
          description: |
          Target {{ $labels.instance }} (service {{ $labels.service }})
          in cluster {{ $labels.cluster }} has been unreachable for more than 1 min.
          Environment: {{ $labels.environment }}

      - alert: ECSServiceUnhealthy
        expr: probe_success{job="blackbox"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "HTTP check for service {{ $labels.instance }} failed"
          description: |
            Blackbox Exporter was unable to receive a successful response from {{ $labels.instance }}.
            The service has likely crashed or is not ready to accept traffic.

      - alert: HighErrorRate
        expr: |
          (
            sum by (service) (rate(http_server_requests_seconds_count{status=~"5..", job="ecs"}[5m]))
            /
            sum by (service) (rate(http_server_requests_seconds_count{job="ecs"}[5m]))
          ) > 0.05
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High 5xx error rate on service {{ $labels.service }}"
          description: |
            More than 5% of requests to service {{ $labels.service }}
            have returned 5xx responses over the last 2 min.
            Check the service logs and health checks.