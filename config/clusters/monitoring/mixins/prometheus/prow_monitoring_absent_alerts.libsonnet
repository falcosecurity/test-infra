{
  prometheusAlerts+:: {
    local componentName = $._config.components.monitoring,
    groups+: [
      {
        name: 'prow-monitoring-absent',
        rules: [{
          alert: 'ServiceLost',
          expr: |||
            sum(up{job=~"prometheus|alertmanager"}) by (job) <= 0
          |||,
          'for': '5m',
          labels: { 
            severity: 'critical',
            slo: componentName,
          },
          annotations: {
            message: 'The service {{ $labels.job }} has at most 0 instance for 5 minutes.',
          },
        }] + [
          {
            alert: '%sDown' % name,
            expr: |||
              absent(up{job="%s"} == 1)
            ||| % name,
            'for': '5m',
            labels: {
              severity: 'critical',
              slo: componentName,
            },
            annotations: {
              message: 'The service %s has been down for 5 minutes.' % name,
            },
          }
          for name in ['alertmanager', 'prometheus', 'grafana']
        ],
      },
    ],
  },
}
