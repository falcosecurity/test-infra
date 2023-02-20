# Monitoring

This folder contains the manifest files for monitoring prow resources.

## Quickstart 

```shell
make apply
```

## Deploy

The deployment has been integrated into our CI system except `secret` objects.
Cluster admins need to create `secret`s  manually.

```
### replace the sensitive inforamtion in the files before executing:
$ kubectl create -f grafana_secret.yaml
$ kubectl create -f alertmanager-prow_secret.yaml

```

A successful deploy will spawn a stack of monitoring for prow in namespace `prow-monitoring`: _prometheus_, _alertmanager_, and _grafana_.

_Add more dashboards_:

Suppose that there is an App running as a pod that exposes Prometheus metrics on port `n` and we want to include it into our prow-monitoring stack.
First step is to create a k8s-service to proxy port `n` if you have not done it yet.

### Add the service as target in Prometheus

Add a new `servicemonitors.monitoring.coreos.com` which proxies the targeting service into [prow_servicemonitors.yaml](./prow_servicemonitors.yaml), eg,
`servicemonitor` for `ghproxy`,

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: ghproxy
  name: ghproxy
  namespace: prow-monitoring
spec:
  endpoints:
    - interval: 30s
      port: metrics
      scheme: http
  namespaceSelector:
    matchNames:
      - default
  selector:
    matchLabels:
      app: ghproxy

```

The `svc` should be available on prometheus web UI: `Status` &rarr; `Targets`.

_Note_ that the `servicemonitor` has to have label `app` as key (value could be an arbitrary string).

### Add a new grafana dashboard

We use [jsonnet](https://jsonnet.org) to generate the json files for grafana dashboards and [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler) to manage the jsonnet libs.
Developing a new dashboard can be achieved by

* Create a new file `<dashhoard_name>.jsonnet` in folder [grafana_dashboards](grafana_dashboards).

* Use the configMap above in [grafana_deployment.yaml](grafana_deployment.yaml).

## Access components' Web page

* For `grafana`, visit [monitoring.prow.falco.org](https://monitoring.prow.falco.org). Anonymous users are with read-only mode.
Use `adm` and [password](https://github.com/kubernetes/test-infra/blob/master/config/prow/cluster/monitoring/grafana_deployment.yaml#L39-L45) to become admin.

If the Prow instance does not publicly expose `grafana` it can still be accessed by cluster admins via [port-forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/). Run

```
kubectl -n prow-monitoring port-forward service/grafana 8080:80
```
then visit [localhost:8080](http://127.0.0.1:8080).

* For `prometheus` and `alertmanager`, there is no public domain configured based on the security
concerns (no authorization out of the box).
Cluster admins can use [k8s port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) to
access the web.

    ```
    $ kubectl -n prow-monitoring port-forward $( kubectl -n prow-monitoring get pods --selector app=prometheus -o jsonpath={.items[0].metadata.name} ) 9090
    $ kubectl -n prow-monitoring port-forward $( kubectl -n prow-monitoring get pods --selector app=alertmanager -o jsonpath={.items[0].metadata.name} ) 9093
    ```

    Then, visit [127.0.0.1:9090](http://127.0.0.1:9090) for the `prometheus` pod and [127.0.0.1:9093](http://127.0.0.1:9093) for the `alertmanager` pod.

    As a result of no public domain for those two components, some of the links on the UI do not work, eg, the links on the slack alerts.
