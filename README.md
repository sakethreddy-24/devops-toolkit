
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
devops-toolkit/
├── devops-toolkit       # master CLI entry point
├── tools/               # individual automation tools
├── lib/common.sh        # shared logging, colors, error handling
├── logs/                # auto-generated run logs
└── .github/workflows/   # CI pipeline (ShellCheck)

## Skills demonstrated
- Advanced bash scripting (error handling, logging, modularity)
- Linux system administration
- Git branching and conventional commits
- GitHub Actions CI pipeline
- Production-grade code structure
