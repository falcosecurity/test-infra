local util = import 'config_util.libsonnet';

//
// Edit configuration in this object.
//
local config = {
  local comps = util.consts.components,

  // Instance specifics
  instance: {
    name: "Poiana",
    botName: "poiana",
    url: "https://prow.falco.org",
    monitoringURL: "https://monitoring.falco.org",
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
    {name: 'ci-test-infra-prow-checkconfig', interval: '30m', alertInterval: '2h'},
  ],

  // Tide pools that are important enough to have their own graphs on the dashboard.
  tideDashboardExplicitPools: [
    {org: 'falcosecurity', repo: 'test-infra', branch: 'master'},
    {org: 'falcosecurity', repo: 'falco', branch: 'master'},
  ],

  // Additional scraping endpoints
  probeTargets: [
  # ATTENTION: Keep this in sync with the list in ../../additional-scrape-configs_secret.yaml
    {url: 'https://prow.falco.org', labels: {slo: comps.deck}},
    {url: 'https://download.falco.org', labels: {slo: comps.monitoring}},
    {url: 'https://falco.org', labels: {}},
  ],

  // How long we go during work hours without seeing a webhook before alerting.
  webhookMissingAlertInterval: '1h',

  // How many days prow hasn't been bumped.
  prowImageStaleByDays: {daysStale: 14, eventDuration: '24h'},
};

// Generate the real config by adding in constant fields and defaulting where needed.
{
  _config+:: util.defaultConfig(config),
  _util+:: util,
}
