Step 7 — Write a proper README
bashcat > README.md << 'EOF'
# DevOps Toolkit

![ShellCheck](https://github.com/sakethreddy-24/devops-toolkit/actions/workflows/shellcheck.yml/badge.svg)

A production-grade CLI toolkit for Linux server automation and DevOps workflows.

## Tools included

| Tool | Description |
|------|-------------|
| `system-health` | CPU, memory, disk, process monitoring with configurable thresholds |
| `backup` | Compressed backups with automatic retention policy |

## Quick start

```bash
git clone https://github.com/YOURUSERNAME/devops-toolkit.git
cd devops-toolkit
chmod +x devops-toolkit
./devops-toolkit
```

## Usage

```bash
# Interactive menu
./devops-toolkit

# Direct tool access
./devops-toolkit system-health
./devops-toolkit backup /path/to/directory
```

## Architecture
