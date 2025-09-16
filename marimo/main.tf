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

variable "slug" {
  type        = string
  description = "The slug of the coder_app resource."
  default     = "marimo"
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

resource "coder_script" "marimo" {
  agent_id     = var.agent_id
  display_name = "Marimo Notebook"
  icon         = "/icon/jupyter.svg"
  run_on_start = true
  script       = templatefile("${path.module}/run.sh", {
    PORT = var.port
  })
}

resource "coder_app" "marimo" {
  agent_id     = var.agent_id
  slug         = var.slug
  display_name = "Marimo"
  url          = "http://localhost:${var.port}"
  icon         = "/icon/jupyter.svg"
  subdomain    = var.subdomain
  share        = var.share
  order        = var.order
  group        = var.group
  
  healthcheck {
    url       = "http://localhost:${var.port}/health"
    interval  = 3
    threshold = 10
  }
}
