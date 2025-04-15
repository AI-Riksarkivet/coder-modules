
```terraform
terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 0.12"
    }
  }
}

variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
}

variable "port" {
  type        = number
  description = "The port to run the FiftyOne App on."
  default     = 5151 # Default FiftyOne port
}

# Optional: Add a variable for FiftyOne version if needed
# variable "fiftyone_version" {
#   type        = string
#   description = "Version of FiftyOne to install (e.g., '0.23.7'). Leave empty for latest."
#   default     = ""
# }

resource "coder_script" "fiftyone_setup" {
  agent_id     = var.agent_id
  display_name = "FiftyOne Setup & Launch"
  icon         = "/icon/fiftyone.svg" # Assumes icon is placed in the Coder deployment's icon dir
  script       = templatefile("${path.module}/run.sh", {
    PORT = var.port
    # FIFTYONE_VERSION = var.fiftyone_version # Uncomment if using the version variable
  })
  run_on_start = true
  # Optional: Set run_on_stop to terminate the fiftyone process gracefully if needed
  # run_on_stop = "pkill -f 'fiftyone app launch'"
}

resource "coder_app" "fiftyone" {
  agent_id     = var.agent_id
  slug         = "fiftyone"
  display_name = "FiftyOne App"
  url          = "http://localhost:${var.port}"
  icon         = "/icon/fiftyone.svg" # Assumes icon is placed in the Coder deployment's icon dir
  subdomain    = true
  share        = "owner"

  healthcheck {
    url       = "http://localhost:${var.port}/" # FiftyOne app root should respond
    interval  = 10 # Increase interval slightly as startup might take time
    threshold = 6  # Increase threshold slightly
  }

  # Depend on the script finishing its initial run
  depends_on = [coder_script.fiftyone_setup]
}
