#!/bin/bash
# MOTD Service Status Monitor - Pure Bash Version
# Monitors programs and Docker containers with zero dependencies

# Colors
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RESET=$'\e[0m'

# Symbols
CHECK="✓"
CROSS="✗"
QUESTION="?"

# Column layout
NAME_WIDTH=${NAME_WIDTH:-14}   # characters reserved for the service name
GAP=${GAP:-2}                  # spaces between columns

# Default config file - use hostname if no argument provided
if [[ $# -eq 0 ]]; then
    FULL_HOSTNAME=$(hostname)
    SHORT_HOSTNAME=${FULL_HOSTNAME%%.*}
    
    # Try FQDN first, then short hostname, then default
    FQDN_CONFIG="$(dirname "$0")/${FULL_HOSTNAME}.conf"
    SHORT_CONFIG="$(dirname "$0")/${SHORT_HOSTNAME}.conf"
    DEFAULT_CONFIG="$(dirname "$0")/config.conf"
    
    if [[ -f "$FQDN_CONFIG" ]]; then
        CONFIG_FILE="$FQDN_CONFIG"
    elif [[ -f "$SHORT_CONFIG" ]]; then
        CONFIG_FILE="$SHORT_CONFIG"
    else
        CONFIG_FILE="$DEFAULT_CONFIG"
    fi
else
    CONFIG_FILE="$1"
fi

# Load configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Configuration file not found at $CONFIG_FILE"
        exit 1
    fi
    
    # Source the config file
    source "$CONFIG_FILE"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check program status
check_program() {
    local name="$1"
    local cmd="$2"
    local expected="$3"

    local output exit_code
    if command -v timeout >/dev/null 2>&1; then
        output=$(timeout 5 bash -c "$cmd" 2>/dev/null)
    else
        output=$(bash -c "$cmd" 2>/dev/null)
    fi
    exit_code=$?

    local sym color
    if [[ $exit_code -ne 0 ]]; then
        sym="$CROSS"; color="$RED"
    elif [[ -n "$expected" && "$output" != *"$expected"* ]]; then
        sym="$CROSS"; color="$RED"
    else
        sym="$CHECK"; color="$GREEN"
    fi

    # Pad only the name (visible chars), keep ANSI around the symbol
    local padded
    printf -v padded '%-*s' "$NAME_WIDTH" "$name"
    printf '%s%s%s %s' "$color" "$sym" "$RESET" "$padded"
}

# Check Docker container status
check_container() {
    local name="$1"
    local container="$2"

    local sym color
    if ! command -v docker >/dev/null 2>&1; then
        sym="$QUESTION"; color="$YELLOW"
    else
        local status
        status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)
        case "$status" in
            running) sym="$CHECK"; color="$GREEN" ;;
            "")      sym="$CROSS"; color="$RED" ;;
            *)       sym="$CROSS"; color="$RED" ;;
        esac
    fi

    local padded
    printf -v padded '%-*s' "$NAME_WIDTH" "$name"
    printf '%s%s%s %s' "$color" "$sym" "$RESET" "$padded"
}

# Main function
main() {
    load_config

    echo "Services:"

    # Determine terminal width with safe fallbacks
    local term_cols
    if [[ -n "${COLUMNS:-}" ]]; then
        term_cols="$COLUMNS"
    else
        term_cols=$(tput cols 2>/dev/null || echo 80)
    fi

    # Each cell is: 1(symbol) + 1(space) + NAME_WIDTH visible chars
    local CELL_WIDTH=$((1 + 1 + NAME_WIDTH))
    local cols_per_line=$(( (term_cols + GAP) / (CELL_WIDTH + GAP) ))
    (( cols_per_line < 1 )) && cols_per_line=1

    local col=0

    # Emit a cell, handle wrapping
    emit_cell() {
        local cell="$1"
        printf '%s' "$cell"
        col=$((col + 1))
        if (( col % cols_per_line == 0 )); then
            printf '\n'
        else
            printf '%*s' "$GAP" ""   # gap between columns
        fi
    }

    # Programs
    if [[ ${#PROGRAMS[@]} -gt 0 ]]; then
        for ((i=0; i<${#PROGRAMS[@]}; i++)); do
            IFS='|' read -r name command expected <<< "${PROGRAMS[i]}"
            emit_cell "$(check_program "$name" "$command" "$expected")"
        done
    fi

    # Containers
    if [[ ${#CONTAINERS[@]} -gt 0 ]]; then
        for ((i=0; i<${#CONTAINERS[@]}; i++)); do
            IFS='|' read -r name container <<< "${CONTAINERS[i]}"
            emit_cell "$(check_container "$name" "$container")"
        done
    fi

    # Ensure trailing newline if last line wasn't complete
    (( col % cols_per_line != 0 )) && printf '\n'
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi