# Gatekeeper Monitoring

<!-- <SD-DOCS> -->

## Overview

This package provides the monitoring integration for Gatekeeper. It includes:

- a Prometheus `ServiceMonitor` definition to instruct the SD Monitoring Module to gather Gatekeeper metrics;
- a custom set of Prometheus rules to alert when Gatekeeper's webhooks are misbehaving;
- a custom Grafana dashboard that visualizes those metrics.

It requires the SD Monitoring Module to be installed.

## Deployment

This package is deployed as part of **Policy Module** when you create a cluster with `furyctl` and `spec.distribution.modules.policy.type` is set to `gatekeeper`. See the [module documentation](../../../README.md) to learn how the Policy Module is installed and configured.

<!-- </SD-DOCS> -->

## License

For license details please see [LICENSE](../../../LICENSE)
