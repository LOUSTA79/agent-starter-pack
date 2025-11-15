#!/bin/bash
################################################################################
# Chat Conversation Backup Script
# Version: 2.0
# Description: Complete solution for backing up chat conversations
################################################################################

set -e  # Exit on error

# Configuration
BACKUP_DIR="${HOME}/chat_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="chat_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Colors for output
RED='[0;31m'
GREEN='[0;32m'
YELLOW='[1;33m'
BLUE='[0;34m'
NC='[0m'

# Functions
print_header() {
    echo -e "${BLUE}=================================="
    echo -e "💾 Chat Backup Tool v2.0"
    echo -e "==================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ ${1}${NC}"
}

print_error() {
    echo -e "${RED}❌ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  ${1}${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  ${1}${NC}"
}

# Create backup directory structure
create_directories() {
    mkdir -p "${BACKUP_PATH}"/text
    mkdir -p "${BACKUP_PATH}"/html
    mkdir -p "${BACKUP_PATH}"/json
    mkdir -p "${BACKUP_PATH}"/media
    mkdir -p "${BACKUP_PATH}"/logs
    print_success "Backup directories created"
}

# Save clipboard content
save_clipboard() {
    print_info "Saving clipboard content..."

    if command -v xclip &> /dev/null; then
        xclip -selection clipboard -o > "${BACKUP_PATH}/text/clipboard.txt" 2>/dev/null
        print_success "Clipboard saved (xclip)"
    elif command -v xsel &> /dev/null; then
        xsel --clipboard --output > "${BACKUP_PATH}/text/clipboard.txt" 2>/dev/null
        print_success "Clipboard saved (xsel)"
    elif command -v pbpaste &> /dev/null; then
        pbpaste > "${BACKUP_PATH}/text/clipboard.txt" 2>/dev/null
        print_success "Clipboard saved (macOS)"
    elif command -v powershell.exe &> /dev/null; then
        powershell.exe -command "Get-Clipboard" > "${BACKUP_PATH}/text/clipboard.txt" 2>/dev/null
        print_success "Clipboard saved (Windows/WSL)"
    else
        print_warning "No clipboard tool found"
        echo "Manual paste required" > "${BACKUP_PATH}/text/clipboard.txt"
    fi
}

# Save chat history with formatting
save_chat_history() {
    print_info "Creating formatted chat history..."

    local input_file="${BACKUP_PATH}/text/clipboard.txt"
    local output_file="${BACKUP_PATH}/text/chat_history.txt"

    if [[ -f "${input_file}" && -s "${input_file}" ]]; then
        {
            echo "=========================================="
            echo "CHAT CONVERSATION BACKUP"
            echo "=========================================="
            echo "Date: $(date '+%B %d, %Y at %H:%M:%S %Z')"
            echo "Backup ID: ${BACKUP_NAME}"
            echo "=========================================="
            echo ""
            cat "${input_file}"
            echo ""
            echo "=========================================="
            echo "End of conversation"
            echo "Total lines: $(wc -l < "${input_file}")"
            echo "=========================================="
        } > "${output_file}"
        print_success "Chat history formatted and saved"
    else
        print_warning "No clipboard content found"
    fi
}

# Convert to HTML format
convert_to_html() {
    print_info "Converting to HTML format..."

    local input_file="${BACKUP_PATH}/text/clipboard.txt"
    local output_file="${BACKUP_PATH}/html/chat_conversation.html"

    if [[ -f "${input_file}" && -s "${input_file}" ]]; then
        local line_count
        line_count=$(wc -l < "${input_file}")
        local word_count
        word_count=$(wc -w < "${input_file}")
        local char_count
        char_count=$(wc -m < "${input_file}")

        cat > "${output_file}" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chat Conversation Backup</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            line-height: 1.6;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 { font-size: 2em; margin-bottom: 10px; }
        .content { padding: 40px; }
        .message {
            margin-bottom: 20px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .stats {
            background: #f8f9fa;
            padding: 20px;
            margin-top: 30px;
            border-radius: 8px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        .stat-item {
            text-align: center;
            padding: 15px;
            background: white;
            border-radius: 6px;
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }
        .footer {
            background: #343a40;
            color: white;
            padding: 20px;
            text-align: center;
        }
        pre { white-space: pre-wrap; word-wrap: break-word; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>💬 Chat Conversation Backup</h1>
            <div>Saved on $(date '+%B %d, %Y at %H:%M:%S')</div>
        </div>
        <div class="content">
            <div class="message">
                <pre>$(cat "${input_file}")</pre>
            </div>
            <div class="stats">
                <div class="stat-item">
                    <div class="stat-value">${line_count}</div>
                    <div class="stat-label">Lines</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${word_count}</div>
                    <div class="stat-label">Words</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${char_count}</div>
                    <div class="stat-label">Characters</div>
                </div>
            </div>
        </div>
        <div class="footer">
            <p>📦 Backup created by Chat Backup Tool v2.0</p>
        </div>
    </div>
</body>
</html>
HTML
        print_success "HTML version created"
    fi
}

# Convert to JSON format
convert_to_json() {
    print_info "Converting to JSON format..."

    local input_file="${BACKUP_PATH}/text/clipboard.txt"
    local output_file="${BACKUP_PATH}/json/chat_data.json"

    if [[ -f "${input_file}" && -s "${input_file}" ]]; then
        local content
        content=$(sed 's/"/\"/g' "${input_file}" | sed ':a;N;$!ba;s/\n/\\n/g')
        cat > "${output_file}" <<EOF
{
  "backup_info": {
    "backup_id": "${BACKUP_NAME}",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "version": "2.0"
  },
  "statistics": {
    "lines": $(wc -l < "${input_file}"),
    "words": $(wc -w < "${input_file}"),
    "characters": $(wc -m < "${input_file}")
  },
  "content": "${content}"
}
EOF
        print_success "JSON version created"
    fi
}

# Create summary report
create_summary() {
    print_info "Creating summary report..."

    local summary_file="${BACKUP_PATH}/BACKUP_SUMMARY.txt"

    cat > "${summary_file}" <<EOF
╔════════════════════════════════════════════════════════════╗
║           CHAT BACKUP SUMMARY REPORT                       ║
╚════════════════════════════════════════════════════════════╝

Backup ID: ${BACKUP_NAME}
Date: $(date '+%B %d, %Y at %H:%M:%S %Z')
Location: ${BACKUP_PATH}

┌─────────────────────────────────────────────────────────┐
│ FILES CREATED:                                          │
└─────────────────────────────────────────────────────────┘
EOF

    find "${BACKUP_PATH}" -type f | while read -r file; do
        local size
        size=$(du -h "${file}" | cut -f1)
        local rel_path
        rel_path=${file#"${BACKUP_PATH}/"}
        echo "  📄 ${rel_path} (${size})" >> "${summary_file}"
    done

    cat >> "${summary_file}" <<EOF

┌─────────────────────────────────────────────────────────┐
│ BACKUP STATISTICS:                                      │
└─────────────────────────────────────────────────────────┘
  Total Size: $(du -sh "${BACKUP_PATH}" | cut -f1)
  Total Files: $(find "${BACKUP_PATH}" -type f | wc -l)

╔════════════════════════════════════════════════════════════╗
║ Backup completed successfully! ✅                          ║
╚════════════════════════════════════════════════════════════╝
EOF

    print_success "Summary report created"
    cat "${summary_file}"
}

# Compress backup
compress_backup() {
    print_info "Compressing backup..."

    (cd "${BACKUP_DIR}" && tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}" 2>/dev/null)

    if [[ -f "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" ]]; then
        local compressed_size
        compressed_size=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)
        print_success "Backup compressed: ${BACKUP_NAME}.tar.gz (${compressed_size})"
    else
        print_warning "Compression failed, but files are still available"
    fi
}

# Main execution
main() {
    print_header

    echo ""
    print_info "Starting backup process..."
    echo ""

    create_directories
    save_clipboard
    save_chat_history
    convert_to_html
    convert_to_json
    create_summary
    compress_backup

    echo ""
    print_success "🎉 Backup completed successfully!"
    echo ""
    print_info "Backup location: ${BACKUP_PATH}"
    print_info "Compressed file: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    echo ""
}

# Run main function
main "$@"
