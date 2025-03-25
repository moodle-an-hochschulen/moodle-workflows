#!/bin/bash

# Moodle workflows CLI - Moodle Plugin CI Trigger Script.
#
# @copyright  2025 Alexander Bias <bias@alexanderbias.de>
# @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later

# Constants.
EVENT_TYPE="moodle-plugin-ci"

# Options.
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
OWNER="moodle-an-hochschulen"
REPO=""
MOODLE_CORE=""
PLUGIN_BRANCH=""

# Function to display usage.
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --token TOKEN       GitHub Personal Access Token (required)"
    echo "  -r, --repo REPO         Repository name (required)"
    echo "  -c, --core CORE         Moodle core branch to test against (optional, default: auto-detect)"
    echo "  -b, --branch BRANCH     Plugin repository branch to trigger (optional, default: main)"
    echo "  -o, --owner OWNER       Repository owner (optional, default: moodle-an-hochschulen)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -t ghp_xxx -r theme_boost_union                                    # Auto-detect core branch, use main plugin branch"
    echo "  $0 -t ghp_xxx -r theme_boost_union -c MOODLE_500_STABLE               # Specific core branch, main plugin branch"
    echo "  $0 -t ghp_xxx -r theme_boost_union -b feature-branch                  # Main core branch, specific plugin branch"
    echo "  $0 -t ghp_xxx -r theme_boost_union -c MOODLE_500_STABLE -b my-feature # Specific core and plugin branches"
    echo ""
    echo "Environment Variables:"
    echo "  GITHUB_TOKEN            Can be used instead of -t option"
    echo ""
    echo "GitHub Token Permissions Required:"
    echo "  - actions:write"
    echo "  - contents:write"
    echo "  - metadata:read"
}

# Parse command line arguments.
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -c|--core)
            MOODLE_CORE="$2"
            shift 2
            ;;
        -b|--branch)
            PLUGIN_BRANCH="$2"
            shift 2
            ;;
        -o|--owner)
            OWNER="$2"
            shift 2
            ;;
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo ""
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters.
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GitHub token is required"
    echo "Use -t option or set GITHUB_TOKEN environment variable"
    echo ""
    usage
    exit 1
fi
if [ -z "$REPO" ]; then
    echo "Error: Repository name is required"
    echo "Use -r option to specify the target repository"
    echo ""
    usage
    exit 1
fi

# Determine API method and prepare payload/URL
if [ -n "$PLUGIN_BRANCH" ]; then
    # Use workflow_dispatch for specific branch
    API_METHOD="workflow_dispatch"
    URL="https://api.github.com/repos/$OWNER/$REPO/actions/workflows/moodle-plugin-ci.yml/dispatches"

    if [ -n "$MOODLE_CORE" ]; then
        PAYLOAD="{\"ref\": \"$PLUGIN_BRANCH\", \"inputs\": {\"moodle-core-branch\": \"$MOODLE_CORE\"}}"
        echo "Triggering CI workflow for repository $OWNER/$REPO on plugin branch '$PLUGIN_BRANCH' with Moodle core branch $MOODLE_CORE"
    else
        PAYLOAD="{\"ref\": \"$PLUGIN_BRANCH\"}"
        echo "Triggering CI workflow for repository $OWNER/$REPO on plugin branch '$PLUGIN_BRANCH' and auto-detecting Moodle core branch"
    fi
else
    # Use repository_dispatch for default branch
    API_METHOD="repository_dispatch"
    URL="https://api.github.com/repos/$OWNER/$REPO/dispatches"

    if [ -n "$MOODLE_CORE" ]; then
        PAYLOAD="{\"event_type\": \"$EVENT_TYPE\", \"client_payload\": {\"moodle-core-branch\": \"$MOODLE_CORE\"}}"
        echo "Triggering CI workflow for repository $OWNER/$REPO with Moodle core branch $MOODLE_CORE"
    else
        PAYLOAD="{\"event_type\": \"$EVENT_TYPE\"}"
        echo "Triggering CI workflow for repository $OWNER/$REPO with plugin branch main and auto-detecting Moodle core branch"
    fi
fi

# Make API call
echo "Sending $API_METHOD event..."
RESPONSE=$(curl -s -w "%{http_code}" \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$URL")

# Extract HTTP status code (last 3 characters)
HTTP_CODE="${RESPONSE: -3}"
RESPONSE_BODY="${RESPONSE%???}"

# Check response
if [ "$HTTP_CODE" = "204" ]; then
    echo ""
    echo "✅ Workflow triggered successfully!"
    echo ""
    echo "You can monitor the workflow at:"
    echo "https://github.com/$OWNER/$REPO/actions"
    exit 0
else
    echo ""
    echo "❌ Failed to trigger workflow!"
    echo ""
    echo "HTTP Status: $HTTP_CODE"
    if [ -n "$RESPONSE_BODY" ]; then
        echo "Response: $RESPONSE_BODY"
    fi
    exit 1
fi