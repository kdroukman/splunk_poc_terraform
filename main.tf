provider "signalfx" {
  auth_token = var.access_token
  api_url    = "https://api.${var.realm}.signalfx.com"
}


/*resource "signalfx_detector" "z_test_detector" {
  name         = "zTest Detector"
  description  = "Alerts when the p90 latency in the last 5 minutes is higher than normal"
  program_text = <<-EOF
    from signalfx.detectors.apm.latency.historical_anomaly_v2 import historical_anomaly
    I = data('spans.duration.ns.p99', filter=filter('sf_kind', 'SERVER', 'CONSUMER') and filter('sf_service', '*') and filter('sf_operation', '*') and filter('sf_environment', '*') and (not filter('sf_dimensionalized', '*'))).promote('team').max(by=['sf_service', 'sf_operation']).publish(label='I')
    J = data('spans.duration.ns.p90', filter=filter('sf_kind', 'SERVER', 'CONSUMER') and filter('sf_service', '*') and filter('sf_operation', '*') and filter('sf_environment', '*') and (not filter('sf_dimensionalized', '*'))).promote('team').max(by=['sf_service', 'sf_operation']).publish(label='J')
    K = data('spans.duration.ns.median', filter=filter('sf_kind', 'SERVER', 'CONSUMER') and filter('sf_service', '*') and filter('sf_operation', '*') and filter('sf_environment', '*') and (not filter('sf_dimensionalized', '*'))).promote('team').max(by=['sf_service', 'sf_operation']).publish(label='K')
    historical_anomaly.deviations_from_norm(filter_=((filter('sf_service', '*') and filter('sf_operation', '*'))) and (filter('sf_kind', 'SERVER','CONSUMER')) and (filter('sf_environment', '*')), custom_filter=None, current_window='5m', historical_window='1h', cycle_length='1w', num_cycles=4, fire_num_dev_threshold=5, clear_num_dev_threshold=4, exclude_errors=True, volume_static_threshold=10, volume_relative_threshold=0.2, auto_resolve_after='30m').publish('zTest Detector')
  EOF
  rule {
    detect_label       = "zTest Detector"
    severity           = "Critical"
  }
}*/

resource "signalfx_detector" "error_sudden_change" {
  name         = "${var.name_prefix} service error rate % greater than historical norm"
  description  = "Alerts when error rate for a service is significantly higher than normal, as compared to the historic window"
  program_text = <<-EOF
    f = ${var.filter}
    cw=${var.current_window}
    hw=${var.historic_window}
    fgt=${var.fire_growth_percent}
    cgt=${var.clear_growth_percent}
    num_v=${var.min_requests}

    A = data('spans.count', filter=f and filter('sf_error', 'true'), rollup='delta').sum(by=['sf_environment','sf_service','sf_operation']).publish(label='A', enable=False)
    B = data('spans.count', filter=f, rollup='delta').sum(by=['sf_environment','sf_service','sf_operation']).publish(label='B', enable=False)
    C = combine(100*((A if A is not None else 0) / B)).publish(label='C')

    from signalfx.detectors.apm.errors.sudden_change_v2 import sudden_change as errors_sudden_change_v2
    errors_sudden_change_v2.detector(filter_=f, current_window=cw, preceding_window=hw, fire_growth_threshold=fgt, clear_growth_threshold=cgt, attempt_threshold=num_v, auto_resolve_after='30m').publish('service error rate % greater than historical norm')
  EOF
  rule {
    detect_label       = "service error rate % greater than historical norm"
    severity           = "Critical"
    parameterized_body = var.message_body
  }
}

resource "signalfx_detector" "latency_deviation" {
  name         = "${var.name_prefix} service latency is greater than historical norm"
  description  = "Alerts when latency for a service is significantly higher than normal, as compared to the historic window"
  program_text = <<-EOF

    f = ${var.filter}
    cw=${var.current_window}
    hw=${var.historic_window}
    fgt=${var.fire_growth_percent}
    cgt=${var.clear_growth_percent}
    num_v=${var.min_requests}
    num_c=${var.num_cycles}
    pct=${var.latency_percentile}

    A = data('spans.duration.ns.p99', filter=f).max(by=['sf_service', 'sf_operation']).publish(label='p99')
    B = data('spans.duration.ns.p90', filter=f).max(by=['sf_service', 'sf_operation']).publish(label='p90')
    C = data('spans.duration.ns.median', filter=f).max(by=['sf_service', 'sf_operation']).publish(label='p50')

    from signalfx.detectors.apm.latency.sudden_change_v2 import sudden_change as latency_sudden_change_v2
    latency_sudden_change_v2.growth_rate(filter_=f, pctile=pct, current_window=cw, historical_window=hw, fire_growth_rate_threshold=fgt, clear_growth_rate_threshold=cgt, exclude_errors=True, volume_static_threshold=num_v, volume_relative_threshold=0).publish('service latency is greater than historical norm')
  EOF
  rule {
    detect_label       = "service latency is greater than historical norm"
    severity           = "Critical"
    parameterized_body = var.message_body
  }
}



resource "signalfx_detector" "jvm_heap_threshold" {
  name         = "${var.name_prefix} JVM heap memory usage is high"
  description  = "Alerts when JVM heap usage is above the specified thresholds over the past minute"
  program_text = <<-EOF
    B = data('runtime.jvm.memory.used', filter=filter('service', '*') and filter('area', 'heap'), rollup="average").publish(label='B', enable=False)
    C = data('runtime.jvm.memory.max', filter=filter('service', '*') and filter('area', 'heap'), rollup="average").above(-1).publish(label='C', enable=False)
    D = (B/C*100).publish(label='D')
    detect(when(D>${var.critical_threshold},'1m'),off=when(D<${var.critical_threshold},'1m')).publish("JVM heap usage is above ${var.critical_threshold}%")
    detect(when(D>${var.warning_threshold},'1m'),off=when(D<${var.warning_threshold},'1m')).publish("JVM heap usage is above ${var.warning_threshold}%")
  EOF
  rule {
    detect_label       = "JVM heap usage is above ${var.critical_threshold}%"
    severity           = "Critical"
  }
  rule {
    detect_label       = "JVM heap usage is above ${var.warning_threshold}%"
    severity           = "Warning"
  }
}

resource "signalfx_detector" "jvm_heap_forecast" {
  name         = "${var.name_prefix} JVM heap memory is forecast to reach 100% in the next hour"
  description  = "Alerts when JVM heap usage is above the specified thresholds over the past minute"
  program_text = <<-EOF
    B = data('runtime.jvm.memory.used', filter=filter('service', '*') and filter('area', 'heap'), rollup="average").publish(label='B', enable=False)
    C = data('runtime.jvm.memory.max', filter=filter('service', '*') and filter('area', 'heap'), rollup="average").above(-1).publish(label='C', enable=False)
    D = (B/C*100).publish(label='D')
    forecast = D.mean(over='30m').double_ewma(over='5m', forecast='1h').publish(label='Forecast')
    detect(when(forecast > 100 )).publish("JVM heap memory is forecast to reach 100% in the next hour")
  EOF
  rule {
    detect_label       = "JVM heap memory is forecast to reach 100% in the next hour"
    severity           = "Critical"
  }
}

resource "signalfx_detector" "jvm_gc_max_pause" {
  name         = "${var.name_prefix} JVM GC max pause time is high"
  description  = "Alerts when JVM heap usage is above the specified thresholds over the past minute"
  program_text = <<-EOF
    A = data('runtime.jvm.gc.pause.max', filter=filter('service', '*')).publish(label='A')
    detect(when(A > threshold(${var.gc_pause_threshold}))).publish('JVM GC max pause time above the threshold of ${var.gc_pause_threshold}s')
  EOF
  rule {
    detect_label       = "JVM GC max pause time above the threshold of ${var.gc_pause_threshold}s"
    severity           = "Warning"
  }
}