global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  receiver: 'sns'

receivers:
  - name: 'aws-sns-receiver'
    sns_configs:
      - topic_arn: "arn:aws:sns:REGION:ACCOUNT:your-alert-topic"
        region: ${var.aws_region}      
        subject: "Alert in Retail store: {{ .GroupLabels.alertname }} - {{ .Status }}"
        message: |
          {{ range .Alerts }}
            Status: {{ .Status }}
            Summary: {{ .Annotations.summary }}
            Description: {{ .Annotations.description }}
            Instance: {{ .Labels.instance }}
          {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

