<div align="center">

# 🔎 Domain OSINT Tool

**A Bash-based domain reconnaissance tool for authorized OSINT and security assessments.**

[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Kali Linux](https://img.shields.io/badge/Platform-Kali%20Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)](https://www.kali.org/)
[![DNS](https://img.shields.io/badge/Focus-DNS%20Recon-0A66C2?style=for-the-badge&logo=cloudflare&logoColor=white)](https://en.wikipedia.org/wiki/Domain_Name_System)
[![OSINT](https://img.shields.io/badge/Field-OSINT-6A5ACD?style=for-the-badge)](https://en.wikipedia.org/wiki/Open-source_intelligence)

[Features](#-features) · [Installation](#-installation) · [Usage](#-usage) · [Output](#-output-files) · [Disclaimer](#-legal-and-ethical-use)

</div>

---

## 📌 Overview

**Domain OSINT Tool** (Domain Recon) is a command-line reconnaissance utility written in Bash. It brings together commonly used DNS, network, domain-registration, web-application-firewall (WAF), and subdomain-discovery checks into one workflow.

Instead of running each utility manually, you can provide a domain and collect the available results in a timestamped folder for later review.

> **Use this tool only on domains you own or have explicit permission to assess.**

## 💡 Concept

Open-Source Intelligence (OSINT) is the process of collecting and analysing information from publicly available sources. In domain reconnaissance, this can include DNS records, registration information, discovered subdomains, network-path information, and indications of WAF protection.

This project automates several of those first-stage checks using existing command-line utilities and certificate-transparency data from [crt.sh](https://crt.sh/). It is intended as a learning and reconnaissance aid—not as a replacement for a full security audit.

## 🎯 Objectives

- Automate common domain reconnaissance tasks from one terminal command.
- Collect common DNS records such as A, AAAA, MX, NS, TXT, CNAME, SOA, and CAA.
- Discover subdomains through passive certificate-transparency data and optional wordlist-based DNS checks.
- Gather WHOIS, WAF-detection, ping, and traceroute results.
- Save results as separate text files in a timestamped directory.
- Support custom wordlists, output locations, and options to disable discovery modes.

## ✨ Features

- **DNS reconnaissance:** `host`, `nslookup`, and `dig`
- **DNS record collection:** A, AAAA, MX, NS, TXT, CNAME, SOA, and CAA
- **Passive subdomain discovery:** queries `crt.sh` certificate-transparency data
- **Wordlist-based subdomain discovery:** checks candidate names against DNS
- **WAF detection:** uses `wafw00f`
- **Domain registration lookup:** uses `whois`
- **Network checks:** `ping` and `traceroute`
- **Organised reports:** writes individual result files and a summary
- **CLI options:** custom wordlist, custom output folder, quiet mode, and discovery toggles
- **Dependency checks:** reports required commands that are missing

## 🧰 Tech Stack

<div align="left">

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Kali Linux](https://img.shields.io/badge/Kali%20Linux-557C94?style=flat-square&logo=kalilinux&logoColor=white)](https://www.kali.org/)
[![DNS](https://img.shields.io/badge/DNS-0078D4?style=flat-square&logo=cloudflare&logoColor=white)](https://en.wikipedia.org/wiki/Domain_Name_System)
[![curl](https://img.shields.io/badge/curl-073551?style=flat-square&logo=curl&logoColor=white)](https://curl.se/)
[![jq](https://img.shields.io/badge/jq-8A2BE2?style=flat-square&logo=json&logoColor=white)](https://jqlang.github.io/jq/)
[![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white)](https://git-scm.com/)

</div>

| Tool / technology | Purpose |
|---|---|
| **Bash** | Main scripting language and workflow automation |
| **Kali Linux / Debian-based Linux** | Recommended environment |
| **ping** | Basic reachability check |
| **host, nslookup, dig** | DNS lookup and record collection |
| **dnsrecon** | DNS reconnaissance |
| **wafw00f** | WAF fingerprinting |
| **whois** | Domain registration lookup |
| **traceroute** | Network-path inspection |
| **curl** | Retrieves certificate-transparency data from crt.sh |
| **jq** *(optional)* | Parses JSON returned by crt.sh |
| **SecLists / DNS wordlist** | Candidate names for wordlist-based subdomain discovery |

The script checks for `ping`, `host`, `nslookup`, `dig`, `dnsrecon`, `wafw00f`, `whois`, and `traceroute`. `curl` is used for passive discovery, while `jq` improves JSON parsing when installed.

## ⚙️ Installation

### 1. Clone the repository

```bash
git clone https://github.com/gksoni19/domain-osint-tool.git
cd domain-osint-tool
```

### 2. Make the script executable

The repository script is named `domain.sh`.

```bash
chmod +x domain.sh
```

### 3. Install dependencies (Kali Linux)

```bash
sudo apt update
sudo apt install -y iputils-ping dnsutils dnsrecon wafw00f whois traceroute curl jq seclists
```

If a package name differs in your distribution, search for its equivalent using your package manager. The tool expects the commands listed in the dependency-check section to be available before it starts.

### 4. Check the help and version

```bash
./domain.sh --help
./domain.sh --version
```

## 🚀 Usage

General syntax:

```bash
./domain.sh [OPTIONS] DOMAIN
```

Replace `DOMAIN` with a domain you own or are authorised to test. Enter the hostname only; the script also strips a leading `http://` or `https://` and any path.

### Basic scan

```bash
./domain.sh example.com
```

Runs the configured reconnaissance checks and stores the results under the default `./recon` directory.

### Choose a custom output directory

```bash
./domain.sh -o ./results example.com
```

### Use a custom subdomain wordlist

```bash
./domain.sh -w /path/to/wordlist.txt example.com
```

Each line should contain a candidate subdomain label, such as `www` or `mail`.

### Disable passive subdomain discovery

```bash
./domain.sh --no-passive example.com
```

### Disable wordlist-based subdomain discovery

```bash
./domain.sh --no-brute example.com
```

### Use both discovery modes disabled

```bash
./domain.sh --no-passive --no-brute example.com
```

### Quiet mode

```bash
./domain.sh -q example.com
```

### Available options

| Option | Description |
|---|---|
| `-h`, `--help` | Show help |
| `-v`, `--version` | Show version |
| `-w`, `--wordlist FILE` | Use a custom subdomain wordlist |
| `-o`, `--output DIR` | Choose the output directory |
| `-q`, `--quiet` | Reduce normal terminal output |
| `--no-passive` | Disable passive subdomain discovery |
| `--no-brute` | Disable wordlist-based subdomain discovery |

## 📂 Output files

Each run creates a timestamped folder in this format:

```text
recon/
└── example.com/
    └── YYYY-MM-DD_HH-MM-SS/
        ├── summary.txt
        ├── ping.txt
        ├── host.txt
        ├── nslookup.txt
        ├── dig.txt
        ├── dnsrecon.txt
        ├── wafw00f.txt
        ├── whois.txt
        ├── traceroute.txt
        ├── subdomains.txt
        └── passive_subdomains.txt
```

The exact files and their contents depend on which checks run and what information is returned. `summary.txt` records run metadata; the other files contain output from individual checks. Some files may be empty when no results are found or a discovery mode is disabled.

## 🔬 How it works

1. **Validate input:** normalises the supplied domain and checks its basic format.
2. **Check dependencies:** verifies that required command-line tools are installed.
3. **Create a report folder:** makes a domain-specific, timestamped output directory.
4. **Collect network and DNS information:** runs ping, host, nslookup, dig, dnsrecon, and traceroute.
5. **Inspect domain and web protection information:** runs WHOIS and wafw00f.
6. **Discover subdomains:** queries crt.sh for passive results and optionally checks candidate labels from a wordlist.
7. **Save results:** writes outputs to separate files for later analysis.

Results depend on DNS configuration, network connectivity, external service availability, the selected wordlist, and the target's infrastructure. A missing result does **not** prove that a record or subdomain does not exist.

## 🧪 Example workflow

```bash
# 1. Open the project directory
cd domain-osint-tool

# 2. Check dependencies and help
./domain.sh --help

# 3. Run against an authorised test domain
./domain.sh -o ./results example.com

# 4. Review the generated report
find ./results -type f -print
cat ./results/example.com/<timestamp>/summary.txt
```

Replace `<timestamp>` with the actual timestamped folder created by your run.

## ⚠️ Limitations

- This is a Bash command-line tool; it does not provide a graphical interface.
- Passive discovery depends on publicly available certificate-transparency data from crt.sh.
- Wordlist discovery only checks names present in the selected wordlist and may miss valid subdomains.
- DNS responses, ICMP restrictions, WAF fingerprinting, WHOIS data, and traceroute results may be incomplete or blocked.
- The tool collects reconnaissance information; it does not by itself establish whether a system is vulnerable.
- Only one domain is accepted per invocation in the current version.

## 🔐 Legal and ethical use

This project is intended for **education, defensive security, and authorised reconnaissance**.

- Scan only domains you own or have explicit written permission to assess.
- Follow applicable laws, organisational policies, and the target's terms of service.
- Be mindful that repeated DNS queries and reconnaissance traffic may be logged.
- Do not use findings to access, disrupt, or damage systems without authorisation.

The author assumes no responsibility for misuse of this tool. You are responsible for ensuring that your use is lawful and authorised.

## 🛣️ Future improvements

Possible extensions for future versions:

- Export reports to Markdown, JSON, or HTML.
- Add a consolidated summary of discovered subdomains and IP addresses.
- Improve validation and error handling for malformed or internationalised domains.
- Add configurable timeouts and more robust result parsing.
- Add automated tests and sample reports using a controlled lab domain.

## 🤝 Contributing

Contributions, bug reports, and suggestions are welcome. Open an issue or submit a pull request with a clear explanation of the proposed change.

## 👤 Author

**gksoni19**

- GitHub repository: https://github.com/gksoni19/domain-osint-tool

---

<div align="center">

**Built for learning, reconnaissance, and responsible security testing.**

</div>
