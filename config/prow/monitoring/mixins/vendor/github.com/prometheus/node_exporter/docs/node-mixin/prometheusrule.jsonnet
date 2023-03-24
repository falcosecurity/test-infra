local rules = (import 'mixin.libsonnet').prometheusRules;

{
  apiVersion: 'monitoring.coreos.com/v1',
  kind: 'PrometheusRule',
  metadata: {
    labels: {
      prometheus: 'prow',
      role: 'node-rules',
    },
    name: 'prometheus-nodes-rules',
    namespace: 'prow-monitoring',
  },
  spec: rules,
}
