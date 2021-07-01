variable "access_token" {
  description = "Splunk Access Token"
}

variable "realm" {
  description = "Splunk Realm"
}

variable "name_prefix" {
  type        = string
  description = "Detector Prefix"
  default     = "[Splunk]"
}

variable "filter" {
  type = string
  default = "filter('sf_environment', '*') and filter('sf_service', '*') and filter('sf_operation','*')"
  description = "Which services, environments, etc to filter this service on. Allows all data by default"
}

variable "group_by" {
  type = string
  default = "['sf_environment','sf_service','sf_operation']"
  description = "How to split the metric time series being reported on"

}

variable "current_window" {
  type = string
  default="'5m'"
  description="The lookback window for this detector"

}

variable "historic_window" {
  type = string
  default="'1h'"
  description="The historic window to compare the current lookback window against"

}

variable "fire_growth_percent" {
  type = string
  default="0.5"
  description="Percentage expressed in decimal, at what error growth rate to fire the alert"
}

variable "clear_growth_percent"{
  type = string
  default="0.1"
  description="Percentage expressed in decimal, at what error growth rate to clear the alert"

}

variable "min_requests" {
  type = string
  default="10"
  description="Volume of requests required before activating the alert"

}

variable "num_cycles" {
  type = string
  default="4"
  description="Number of historic cycles to include in historic anomaly alerts"

}

variable "latency_percentile" {
  type = string
  default="90"
  description="Which percentile metric (p50,p90, or p99) to use when alertin on latency"

}

variable "critical_threshold" {
  type = string
  default="80"
  description="% threshold to fire critical alert"

}

variable "warning_threshold" {
  type = string
  default="60"
  description="% threshold to fire warning alert"

}

variable "gc_pause_threshold" {
  type = string
  default="5"
  description="Time in seconds to warn of GC Pause"

}

variable "message_body" {
  type = string

  default = <<-EOF
    {{#if anomalous}}
	    Rule "{{{ruleName}}}" in detector "{{{detectorName}}}" triggered at {{timestamp}}.
    {{else}}
	    Rule "{{{ruleName}}}" in detector "{{{detectorName}}}" cleared at {{timestamp}}.
    {{/if}}

    {{#if anomalous}}
      Triggering condition: {{{readableRule}}}
    {{/if}}

    {{#if anomalous}}
      Signal value: {{inputs.A.value}}
    {{else}}
      Current signal value: {{inputs.A.value}}
    {{/if}}

    {{#notEmpty dimensions}}
      Signal details: {{{dimensions}}}
    {{/notEmpty}}

    {{#if anomalous}}
      {{#if runbookUrl}}
        Runbook: {{{runbookUrl}}}
      {{/if}}
      {{#if tip}}
        Tip: {{{tip}}}
      {{/if}}
    {{/if}}
  EOF
}

