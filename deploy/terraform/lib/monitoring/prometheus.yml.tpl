global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - "ecs-alerts.yml"

scrape_configs:
  - job_name: ecs-services

    metrics_path: /metrics

    scrape_interval: 15s

    aws_sd_configs:
      - region: ${AWS_REGION}
        role: ecs
        clusters: ["${ECS_CLUSTER_ARN}"]
        port: 8080
       

    relabel_configs:
      # Scrape only application services
      - source_labels: [__meta_ecs_service]
        regex: "(ui|orders|catalog|checkout|assets|carts)"
        action: keep

      # User labels
      - source_labels: [__meta_ecs_service]
        target_label: service
      - source_labels: [__meta_ecs_cluster]
        target_label: cluster
      - source_labels: [__meta_ecs_task_definition]
        target_label: container
      - source_labels: [__meta_ecs_launch_type]
        target_label: launch_type
      - source_labels: [__meta_ecs_availability_zone]
        target_label: availability_zone

      # Static labels
      - target_label: environment
        replacement: ${ENVIRONMENT}
      - target_label: job
        replacement: ecs

      # Cleanup internal AWS labels
      - action: labeldrop
        regex: "__meta_ecs_.*"        


  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - 'ui:8080'
          - 'catalog:8080'
          - 'cart:8080'
          - 'checkout:8080'
          - 'orders:8080'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115        