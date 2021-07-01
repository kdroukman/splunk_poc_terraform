# Splunk POC Detectors with Terraform
**Requires Terraform (minimum) v0.14**

## Clone this repository:

`git clone https://github.com/kdroukman/splunk_poc_terraform.git`

## Initialise Terraform

```
$ terraform init --upgrade
```

## Create a workspace (Optional)

```
$ terraform workspace new my_workspace
```
Where `my_workspace` is the name of your workspace

## Review the execution plan

```
$ terraform plan -var="access_token=abc123" -var="realm=us1"
```

Where `access_token` is the Splunk Access Token and `realm` is either `eu0`, `us0`, `us1` or `us2`

## Apply the changes

```
$ terraform apply -var="access_token=abc123" -var="realm=us1"
```

## Destroy everything (if you must)

If you created a workspace you will first need to ensure you are in the correct workspace e.g.

```
$ terraform workspace select my_workspace
```
Where `my_workspace` is the name of your workspace

```
$ terraform destroy -var="access_token=abc123" -var="realm=us1"
```

# Programmatically changing detector settings

This script contains a number of different detectors. 
You can programmatically modify variables specific to each detector, or even change the filter to set up detectors for specific services and operations.
For example

```
terraform apply -var="access_token=abc123" -var="realm=us1" -target=signalfx_detector.error_sudden_change -var="current_window='1m'" -var="historic_window='3h'" -var="fire_growth_percent=0.25" -var="min_requests=15"
```

The above will modify the sudden change alert for error rate growth to the respective settings.
See [`variables.tf`](https://github.com/kdroukman/splunk_poc_terraform/blob/main/variables.tf) for default values and variables that can be set, and [`main.tf`](https://github.com/kdroukman/splunk_poc_terraform/blob/main/main.tf) to understand how these are used within the Detectors. You can set those inline, or create a [`.tfvars`](https://www.terraform.io/docs/language/values/variables.html#variable-definitions-tfvars-files) file to manage your configuration. 

You may also wish to create different Workspaces and different alerting conditions for different services. 
This example script provides you with the `name_prefix` variable which you can use to prefix your detector with respective service, platform or team name. 

## How to use filters

[filter() Documentation](https://dev.splunk.com/observability/docs/signalflow/functions/filter_function/)

Notice that detectors use a filter() to select what to alert on. In these scripts the default filter is a *catch-all* one.
Bellow are some examples of how you can modify it:

Filter on a specific environment and service
```-var="filter=filter('sf_environment', 'my_environment') and filter('sf_service', 'my_demo_service') and filter('sf_operation','*')"```

Filter on a specific environment and service, but exclude some endpoints
```-var="filter=filter('sf_environment', 'my_environment') and filter('sf_service', 'my_demo_service') and not filter('sf_operation','*/healthz')"```

The above examples use *dimensions* related to APM metrics such as `spans.count` and `spans.duration`. The are dimensionilized by 
* sf_environment
* sf_service
* sf_operation
* sf_kind 
* sf_error
* sf_httpMethod

And addtional dimensions on request.

Other metrics are dimensionalized differently - for exmaple JVM metrics use:
* service
* process_pid
* host.name
* deployment_environment
* etc

You can use the metrics finder to explore properties and dimensions associated with specific metrics. 

Read more about Splunk Observability data model [here](https://dev.splunk.com/observability/docs/datamodel/metrics_metadata)


## Reference

You can read more about Splunk Observability Terraform Provider here:

Main page: 
[Splunk Terraform Provider](https://registry.terraform.io/providers/splunk-terraform/signalfx/latest/docs)

Detectors: 
[Splunk Terraform Provider Detector resource](https://registry.terraform.io/providers/splunk-terraform/signalfx/latest/docs/resources/detector),
[Splunk Detector Documentation](https://docs.signalfx.com/en/latest/detect-alert/alert-condition-reference/index.html)

_Note that the provider still references signalfx as this capability from acquired from SignalFx by Splunk_
