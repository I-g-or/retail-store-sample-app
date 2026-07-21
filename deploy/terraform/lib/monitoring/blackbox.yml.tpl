modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_response_codes: [200, 301, 302]
      method: GET
      preferred_ip_protocol: "ip4"