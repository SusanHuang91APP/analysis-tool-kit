---
description: Initialize analysis environment with branch and directory structure
scripts:
  sh: .analysis-tool-kit/scripts/analysis-init.sh --json "{ARGS}"
  ps: .analysis-tool-kit/scripts/analysis-init.ps1 -Json "{ARGS}"
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

The text the user typed after `/analysis-init` in the triggering message **is** the analysis name. Assume you always have it available in this conversation even if `{ARGS}` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that analysis name, do this:

1. Run the script `{SCRIPT}` from repo root and parse its JSON output for BRANCH_NAME and ANALYSIS_DIR. All file paths must be absolute.
   **IMPORTANT** You must only ever run this script once. The JSON is provided in the terminal as output - always refer to it to get the actual content you're looking for.
2. Report completion with branch name, analysis directory path, and readiness for the next phase.

Note: This script creates and checks out the new analysis branch and initializes the basic directory structure with README.md before proceeding.

## AI Prompt Instructions:

You are responsible for initializing a new analysis environment. Your task is to:

1. Execute the analysis-init.sh script with the provided analysis name
2. Parse the JSON output to extract branch and directory information  
3. Confirm the successful creation of the analysis environment
4. Guide the user to the next step: using `/analysis-create-template` with View files

The initialization process creates:
- A new git branch: `analysis/###-analysis-name`
- A new analysis directory: `analysis/###-analysis-name/`
- A basic README.md file for tracking progress

Next step instructions:
After successful initialization, inform the user that they should run:
`/analysis-create <files...>` to analyze source files and create the architecture analysis (supports multiple tech stacks).
