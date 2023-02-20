local util = import 'config_util.libsonnet';

//
// Edit configuration in this object.
//
local config = {
  local comps = util.consts.components,

  // Instance specifics
  instance: {
    name: "K8s Prow",
    botName: "k8s-ci-robot",
    url: "https://prow.falco.org",
    monitoringURL: "https://monitoring.prow.falco.org",
  },

  // SLO compliance tracking config
  slo: {
    components: [
      comps.deck,
      comps.hook,
      comps.prowControllerManager,
      comps.sinker,
      comps.tide,
      comps.monitoring,
    ],
  },

  ciAbsents: {
    components: [
      comps.crier,
      comps.deck,
      comps.ghproxy,
      comps.hook,
      comps.horologium,
      comps.prowControllerManager,
      comps.sinker,
      comps.tide,
    ],
  },

  // Heartbeat jobs
  heartbeatJobs: [
    {name: 'ci-test-infra-prow-checkconfig', interval: '5m', alertInterval: '20m'},
  ],

  // Tide pools that are important enough to have their own graphs on the dashboard.
  tideDashboardExplicitPools: [
    {org: 'kubernetes', repo: 'kubernetes', branch: 'master'},
  ],

  // Additional scraping endpoints
  probeTargets: [
  # ATTENTION: Keep this in sync with the list in ../../additional-scrape-configs_secret.yaml
    {url: 'https://prow.falco.org', labels: {slo: comps.deck}},
    {url: 'https://monitoring.prow.falco.org', labels: {slo: comps.monitoring}},
  ],

  // How long we go during work hours without seeing a webhook before alerting.
  webhookMissingAlertInterval: '10m',

  // How many work days prow hasn't been bumped, the alert rule using this value
  // understands to adjust based on day of week so weekends are considered.
  prowImageStaleByDays: {daysStale: 7, eventDuration: '24h'},

  kubernetesExternalSecretServiceAccount: "kubernetes-external-secrets-sa@k8s-prow.iam.gserviceaccount.com",
};

// Generate the real config by adding in constant fields and defaulting where needed.
{
  _config+:: util.defaultConfig(config),
  _util+:: util,
}
