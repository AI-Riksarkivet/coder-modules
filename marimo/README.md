---
display_name: Marimo 
description: A module that adds Marimo in your Coder template.
icon: ../../../../.icons/python.svg
verified: true
tags: [marimo, ide, web]
---

# Marimo 

A module that adds Marimo in your Coder template.

```tf
module "marimo" {
  count     = data.coder_workspace.me.start_count
  source    = "git::https://github.com/AI-Riksarkivet/coder-modules.git//marimo?ref=main"
  agent_id  = coder_agent.main.id
  port      = 8080
  subdomain = false
}
```
