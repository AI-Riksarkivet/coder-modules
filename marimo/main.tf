terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.5"
    }
  }
}

variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
}

variable "port" {
  type        = number
  description = "The port to run marimo on."
  default     = 8080
}

variable "subdomain" {
  type        = bool
  description = "Use subdomain for the app."
  default     = false
}

resource "coder_script" "marimo" {
  agent_id     = var.agent_id
  display_name = "marimo-notebook"
  icon         = "/icon/jupyter.svg"
  run_on_start = true
  script       = templatefile("${path.module}/run.sh", {
    PORT = var.port
  })
}

resource "coder_app" "marimo" {
  agent_id     = var.agent_id
  slug         = "marimo"
  display_name = "Marimo"
  url          = "http://localhost:${var.port}"
  icon         = "/icon/python.svg"
  subdomain    = var.subdomain
  share        = "owner"
  
  healthcheck {
    url       = "http://localhost:${var.port}/health"
    interval  = 3
    threshold = 10
  }
}
