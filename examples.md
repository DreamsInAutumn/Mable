# Script Examples

This repository contains a collection of advanced Windows Batch scripts utilizing a custom macro assembly library (`assembly.library.cmd`) to achieve modular, structured, and state-driven logic.

### Included Utilities

| Script Name | Description |
| :--- | :--- |
| **`gemapi.cmd`** | A secure loader for a Gemini CLI application. It performs pre-launch health checks, gracefully handles missing configuration files, and securely loads API keys into memory before executing the main application. |
| **`pinglog.cmd`** | A TUI (Text User Interface) network health monitor. It continuously pings a rotating list of public DNS hosts (Google, Cloudflare, etc.), calculates failure percentages, logs outages with timestamps, and features an interactive menu to toggle alert beeps or skip hosts. |
| **`shasum.cmd`** | A quick command-line utility to generate file checksums. It acts as a wrapper for the native Windows `certutil` tool, cleanly validating user input to output either SHA-256 or SHA-512 hashes. |
| **`sshc.cmd`** | A visual SSH connection manager. It reads a list of saved SSH profiles from a `.conf` file, provides a selection menu, and uses `gum` to display a visual spinner while polling the remote server until it comes online to establish a connection. |

---
**Note:** All scripts require the `assembly.library.cmd` file to be present in the environment or working directory to function properly. 
