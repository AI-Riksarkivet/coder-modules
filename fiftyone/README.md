---
display_name: FiftyOne
description: Visualize, explore, and curate computer vision datasets.
icon: ../.icons/fiftyone.svg # You'll need to add a fiftyone.svg icon here or adjust path
maintainer_github: coder # Or your GitHub handle
verified: false # Set to true once tested and stable
tags: [helper, data-science, computer-vision, python]
---

# FiftyOne

Automatically install [FiftyOne](https://voxel51.com/fiftyone/) in a workspace using pip, and create an app to access the FiftyOne App via the dashboard.

```tf
module "fiftyone" {
  source   = "[registry.coder.com/modules/fiftyone/coder](https://registry.coder.com/modules/fiftyone/coder)" # Adjust if using a local path or different registry
  version  = "1.0.0" # Start with an initial version
  agent_id = coder_agent.example.id
  # port     = 5151 # Optional: Defaults to 5151
}