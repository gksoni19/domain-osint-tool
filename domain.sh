#!/usr/bin/bash

# ============================================================
# Domain Recon - Authorized OSINT / Reconnaissance Tool
# Version: 1.0
#
# Usage:
#   ./domain_recon.sh [OPTIONS] DOMAIN
#
# Examples:
#   ./domain_recon.sh example.com
#   ./domain_recon.sh -w wordlist.txt example.com
#   ./domain_recon.sh -o ./results example.com
#   ./domain_recon.sh --no-passive example.com
#
# Use only against domains you own or are authorized to assess.
# ============================================================

set -u
set -o pipefail

VERSION="1.0"

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

WORDLIST=""
OUTPUT_DIR="./recon"
PASSIVE=true
BRUTE=true
QUIET=false

# Controlled concurrency
MAX_JOBS=20

# Default wordlist candidates
DEFAULT_WORDLISTS=(
    "/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
    "/usr/share/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt"
    "/usr/share/wordlists/dnsmap.txt"
)

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------

usage() {
    cat <<EOF

${BOLD}${CYAN}
============================================================
                 DOMAIN RECON TOOL v${VERSION}
============================================================
${RESET}

${BOLD}Usage:${RESET}
    $0 [OPTIONS] DOMAIN

${BOLD}Options:${RESET}
    -h, --help              Show this help
    -v, --version           Show version
    -w, --wordlist FILE     Use custom subdomain wordlist
    -o, --output DIR        Output directory
    -q, --quiet             Minimal terminal output

    --no-passive            Disable passive subdomain discovery
    --no-brute              Disable wordlist subdomain discovery

${BOLD}Examples:${RESET}

    $0 example.com

    $0 -w wordlist.txt example.com

    $0 -o ./results example.com

    $0 --no-passive example.com

    $0 --no-brute example.com

${BOLD}Tools used:${RESET}

    ping
    host
    nslookup
    dig
    dnsrecon
    wafw00f
    whois
    traceroute

${BOLD}Output:${RESET}

    Results are stored under:

        OUTPUT-DIR/DOMAIN/TIMESTAMP/

${BOLD}Note:${RESET}
    Use this tool only against domains you own or have
    explicit authorization to assess.

EOF
}

version() {
    echo "Domain Recon Tool v${VERSION}"
}

die() {
    echo -e "${RED}[!] $1${RESET}"
    exit 1
}

info() {
    if [[ "$QUIET" == false ]]; then
        echo -e "${BLUE}[*]${RESET} $1"
    fi
}

success() {
    if [[ "$QUIET" == false ]]; then
        echo -e "${GREEN}[+]${RESET} $1"
    fi
}

warning() {
    echo -e "${YELLOW}[!]${RESET} $1"
}

section() {
    if [[ "$QUIET" == false ]]; then
        echo
        echo -e "${BOLD}${MAGENTA}"
        echo "============================================================"
        echo " $1"
        echo "============================================================"
        echo -e "${RESET}"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

DOMAIN=""

while [[ $# -gt 0 ]]; do

    case "$1" in

        -h|--help)
            usage
            exit 0
            ;;

        -v|--version)
            version
            exit 0
            ;;

        -w|--wordlist)
            [[ $# -lt 2 ]] && die "Missing argument for $1"
            WORDLIST="$2"
            shift 2
            ;;

        -o|--output)
            [[ $# -lt 2 ]] && die "Missing argument for $1"
            OUTPUT_DIR="$2"
            shift 2
            ;;

        -q|--quiet)
            QUIET=true
            shift
            ;;

        --no-passive)
            PASSIVE=false
            shift
            ;;

        --no-brute)
            BRUTE=false
            shift
            ;;

        -*)
            die "Unknown option: $1"

        ;;

        *)
            if [[ -z "$DOMAIN" ]]; then
                DOMAIN="$1"
            else
                die "Multiple domains supplied. This version accepts one domain."
            fi
            shift
            ;;
    esac

done

[[ -z "$DOMAIN" ]] && die "No domain supplied."

# ------------------------------------------------------------
# Domain normalization
# ------------------------------------------------------------

DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN%%/*}"
DOMAIN="${DOMAIN%.}"

# Basic validation
if [[ ! "$DOMAIN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?)$ ]]; then
    die "Invalid domain: $DOMAIN"
fi

# ------------------------------------------------------------
# Output directory
# ------------------------------------------------------------

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

RESULT_DIR="${OUTPUT_DIR}/${DOMAIN}/${TIMESTAMP}"

mkdir -p "$RESULT_DIR" || die "Cannot create output directory."

SUMMARY="$RESULT_DIR/summary.txt"

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

if [[ "$QUIET" == false ]]; then

    echo -e "${CYAN}"
    echo "============================================================"
    echo "                 DOMAIN RECON TOOL"
    echo "============================================================"
    echo -e "${RESET}"

    echo -e "${BOLD}Target:${RESET}  $DOMAIN"
    echo -e "${BOLD}Output:${RESET}  $RESULT_DIR"
    echo

fi

# ------------------------------------------------------------
# Dependency check
# ------------------------------------------------------------

REQUIRED_TOOLS=(
    ping
    host
    nslookup
    dig
    dnsrecon
    wafw00f
    whois
    traceroute
)

MISSING=()

for TOOL in "${REQUIRED_TOOLS[@]}"; do
    if ! command_exists "$TOOL"; then
        MISSING+=("$TOOL")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then

    echo -e "${RED}${BOLD}"
    echo "Missing required tools:"
    echo -e "${RESET}"

    for TOOL in "${MISSING[@]}"; do
        echo "    - $TOOL"
    done

    echo
    echo -e "${YELLOW}Install missing tools on Kali with:${RESET}"
    echo
    echo "    sudo apt update"
    echo "    sudo apt install dnsutils dnsrecon wafw00f whois traceroute"
    echo

    exit 1
fi

# ------------------------------------------------------------
# Save metadata
# ------------------------------------------------------------

{
    echo "Domain Recon Report"
    echo "==================="
    echo
    echo "Target       : $DOMAIN"
    echo "Started      : $(date)"
    echo "Output       : $RESULT_DIR"
    echo "Passive      : $PASSIVE"
    echo "Wordlist     : ${WORDLIST:-default}"
    echo "Max jobs     : $MAX_JOBS"
    echo
} > "$SUMMARY"

# ------------------------------------------------------------
# Ping
# ------------------------------------------------------------

section "PING"

info "Running ping..."

ping -c 4 -W 2 "$DOMAIN" 2>&1 \
    | tee "$RESULT_DIR/ping.txt"

echo "Ping completed." >> "$SUMMARY"

# ------------------------------------------------------------
# HOST
# ------------------------------------------------------------

section "HOST"

info "Running host..."

host "$DOMAIN" 2>&1 \
    | tee "$RESULT_DIR/host.txt"

# ------------------------------------------------------------
# NSLOOKUP
# ------------------------------------------------------------

section "NSLOOKUP"

info "Running nslookup..."

nslookup "$DOMAIN" 2>&1 \
    | tee "$RESULT_DIR/nslookup.txt"

# ------------------------------------------------------------
# DIG
# ------------------------------------------------------------

section "DNS RECORDS - DIG"

DIG_FILE="$RESULT_DIR/dig.txt"

: > "$DIG_FILE"

for TYPE in A AAAA MX NS TXT CNAME SOA CAA; do

    echo "==================================================" \
        >> "$DIG_FILE"

    echo "DNS RECORD: $TYPE" \
        >> "$DIG_FILE"

    echo "==================================================" \
        >> "$DIG_FILE"

    dig "$DOMAIN" "$TYPE" +noall +answer \
        >> "$DIG_FILE" 2>&1

    echo \
        >> "$DIG_FILE"

done

cat "$DIG_FILE"

# ------------------------------------------------------------
# DNSRECON
# ------------------------------------------------------------

section "DNSRECON"

info "Running dnsrecon..."

dnsrecon -d "$DOMAIN" 2>&1 \
    | tee "$RESULT_DIR/dnsrecon.txt"

# ------------------------------------------------------------
# WAFW00F
# ------------------------------------------------------------

section "WAF DETECTION"

info "Running wafw00f..."

wafw00f "https://${DOMAIN}" 2>&1 \
    | tee "$RESULT_DIR/wafw00f.txt"

# ------------------------------------------------------------
# WHOIS
# ------------------------------------------------------------

section "WHOIS"

info "Running whois..."

whois "$DOMAIN" 2>&1 \
    | tee "$RESULT_DIR/whois.txt"

# ------------------------------------------------------------
# TRACEROUTE
# ------------------------------------------------------------

section "TRACEROUTE"

info "Running traceroute..."

traceroute -m 12 -w 2 "$DOMAIN" 2>&1 \
    | tee "$RESULT_DIR/traceroute.txt"

# ============================================================
# SUBDOMAIN ENUMERATION
# ============================================================

SUBDOMAIN_FILE="$RESULT_DIR/subdomains.txt"
PASSIVE_FILE="$RESULT_DIR/passive_subdomains.txt"

touch "$SUBDOMAIN_FILE"
touch "$PASSIVE_FILE"

# ------------------------------------------------------------
# Passive discovery using crt.sh
# ------------------------------------------------------------

if [[ "$PASSIVE" == true ]]; then

    section "PASSIVE SUBDOMAIN DISCOVERY"

    info "Querying certificate transparency data..."

    if command_exists curl; then

        CRT_DATA=$(curl -fsS \
            --max-time 20 \
            "https://crt.sh/?q=%25.${DOMAIN}&output=json" 2>/dev/null || true)

        if [[ -n "$CRT_DATA" ]]; then

            if command_exists jq; then

                echo "$CRT_DATA" \
                    | jq -r '.[].name_value' 2>/dev/null \
                    | tr '\r' '\n' \
                    | sed 's/\*\.//g' \
                    | grep -E "(^|\.)${DOMAIN}$" \
                    | sort -u \
                    > "$PASSIVE_FILE"

            else

                echo "$CRT_DATA" \
                    | grep -oE '"name_value":"[^"]+"' \
                    | cut -d '"' -f4 \
                    | tr '\\n' '\n' \
                    | sed 's/\*\.//g' \
                    | grep -E "(^|\.)${DOMAIN}$" \
                    | sort -u \
                    > "$PASSIVE_FILE"

            fi

        fi

    else
        warning "curl is not installed. Passive discovery skipped."
    fi

    if [[ -s "$PASSIVE_FILE" ]]; then

        success "Passive subdomains found: $(wc -l < "$PASSIVE_FILE")"

        cat "$PASSIVE_FILE"

    else

        warning "No passive subdomains found."

    fi

fi

# ------------------------------------------------------------
# Select wordlist
# ------------------------------------------------------------

if [[ "$BRUTE" == true ]]; then

    if [[ -n "$WORDLIST" ]]; then

        if [[ ! -f "$WORDLIST" ]]; then
            die "Wordlist does not exist: $WORDLIST"
        fi

    else

        for WL in "${DEFAULT_WORDLISTS[@]}"; do
            if [[ -f "$WL" ]]; then
                WORDLIST="$WL"
                break
            fi
        done

    fi

fi

# ------------------------------------------------------------
# Wordlist subdomain enumeration
# ------------------------------------------------------------

if [[ "$BRUTE" == true ]]; then

    section "WORDLIST SUBDOMAIN DISCOVERY"

    if [[ -z "$WORDLIST" ]]; then

        warning "No default wordlist found."

        echo "Install SecLists with:"
        echo
        echo "    sudo apt install seclists"
        echo

    else

        info "Using wordlist: $WORDLIST"
        info "Concurrency: $MAX_JOBS"

        BRUTE_RAW="$RESULT_DIR/.subdomain_raw"

        rm -f "$BRUTE_RAW"
        touch "$BRUTE_RAW"

        check_subdomain() {

            local SUB="$1"
            local FQDN="${SUB}.${DOMAIN}"

            if host "$FQDN" >/dev/null 2>&1; then

                IP=$(host "$FQDN" 2>/dev/null \
                    | awk '/has address/ {print $NF}' \
                    | head -n 1)

                if [[ -n "$IP" ]]; then
                    echo "$FQDN -> $IP" >> "$BRUTE_RAW"
                else
                    echo "$FQDN" >> "$BRUTEs
