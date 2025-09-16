---
display_name: Langflow
description: A module that adds Langflow (LLM app builder) to your Coder template.
icon: ../../../../.icons/python.svg
verified: true
tags: [langflow, llm, ai, web]
---

# Langflow

A module that adds Langflow to your Coder template for building LLM applications.
```tf
module "langflow" {
  count     = data.coder_workspace.me.start_count
  source    = "git::https://github.com/AI-Riksarkivet/coder-modules.git//langflow?ref=main"
  agent_id  = coder_agent.main.id
  port      = 7860
  subdomain = false
}
