terraform {
  required_version = ">= 1.0"
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.5"
    }
  }
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
}

variable "agent_name" {
  type        = string
  description = "The name of the coder_agent resource. (Only required if subdomain is false and the template uses multiple agents.)"
  default     = null
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

variable "slug" {
  type        = string
  description = "The slug of the coder_app resource."
  default     = "marimo"
}

variable "log_path" {
  type        = string
  description = "The path to log marimo to."
  default     = "/tmp/marimo.log"
}

variable "share" {
  type    = string
  default = "owner"
  validation {
    condition     = var.share == "owner" || var.share == "authenticated" || var.share == "public"
    error_message = "Incorrect value. Please set either 'owner', 'authenticated', or 'public'."
  }
}

variable "order" {
  type        = number
  description = "The order determines the position of app in the UI presentation."
  default     = null
}

variable "group" {
  type        = string
  description = "The name of a group that this app belongs to."
  default     = null
}

locals {
  server_base_path = var.subdomain ? "" : format("/@%s/%s%s/apps/%s", data.coder_workspace_owner.me.name, data.coder_workspace.me.name, var.agent_name != null ? ".${var.agent_name}" : "", var.slug)
  url              = "http://localhost:${var.port}${local.server_base_path}"
  healthcheck_url  = "http://localhost:${var.port}${local.server_base_path}/health"
}

resource "coder_script" "marimo" {
  agent_id     = var.agent_id
  display_name = "Marimo Notebook"
  icon         = "/icon/jupyter.svg"
  run_on_start = true
  script       = templatefile("${path.module}/run.sh", {
    PORT             = var.port
    SERVER_BASE_PATH = local.server_base_path
    LOG_PATH         = var.log_path
  })
}

resource "coder_app" "marimo" {
  agent_id     = var.agent_id
  slug         = var.slug
  display_name = "Marimo"
  url          = local.url
  icon         = "/icon/jupyter.svg"
  subdomain    = var.subdomain
  share        = var.share
  order        = var.order
  group        = var.group
  
  healthcheck {
    url       = local.healthcheck_url
    interval  = 5
    threshold = 6
  }
}
