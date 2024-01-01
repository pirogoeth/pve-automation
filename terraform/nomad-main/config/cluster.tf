resource "nomad_scheduler_config" "default" {
  scheduler_algorithm             = "spread"
  memory_oversubscription_enabled = true
  preemption_config = {
    batch_scheduler_enabled    = true
    service_scheduler_enabled  = false
    sysbatch_scheduler_enabled = false
    system_scheduler_enabled   = true
  }
}

resource "nomad_node_pool" "gpu" {
  name        = "gpu"
  description = "GPU worker nodes"
}
