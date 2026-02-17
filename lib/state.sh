#!/bin/bash

# Forge State Management Library
# Bash helpers for reading/writing state.json at all scales

set -euo pipefail

# Global variables
FORGE_PROJECTS_DIR="${FORGE_PROJECTS_DIR:-$(pwd)/projects}"

# Create projects directory if it doesn't exist
ensure_projects_dir() {
    mkdir -p "$FORGE_PROJECTS_DIR"
}

# Initialize a new project directory structure
init_project() {
    local project_id="$1"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    
    echo "Initializing project: $project_id" >&2
    
    # Create directory structure
    mkdir -p "$project_dir"/{epics,reports/daily}
    
    # Create initial project state
    cat > "$project_dir/state.json" << EOF
{
  "projectId": "$project_id",
  "status": "intake",
  "created": "$(date -Iseconds)",
  "updated": "$(date -Iseconds)",
  "scales": {
    "project": "draft",
    "epics": {
      "total": 0,
      "decomposed": 0,
      "approved": 0
    },
    "features": {
      "total": 0,
      "decomposed": 0,
      "approved": 0
    },
    "atoms": {
      "total": 0,
      "done": 0,
      "running": 0,
      "failed": 0,
      "blocked": 0,
      "queued": 0
    }
  },
  "currentWork": {
    "epic": null,
    "feature": null,
    "atom": null,
    "workerSession": null
  },
  "decisions": [],
  "budget": {
    "atomsCompletedToday": 0,
    "estimatedAtomsRemaining": 0,
    "estimatedDaysRemaining": 0
  },
  "git": {
    "repo": null,
    "baseBranch": "main",
    "forgeBranch": "forge/build",
    "lastCommit": null
  }
}
EOF

    echo "Project $project_id initialized at $project_dir"
}

# Initialize epic directory structure
init_epic() {
    local project_id="$1"
    local epic_id="$2"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    local epic_dir="$project_dir/epics/$epic_id"
    
    echo "Initializing epic: $epic_id in project $project_id" >&2
    
    # Create epic directory structure
    mkdir -p "$epic_dir/features"
    
    # Create initial epic state
    cat > "$epic_dir/state.json" << EOF
{
  "epicId": "$epic_id",
  "projectId": "$project_id",
  "status": "planned",
  "created": "$(date -Iseconds)",
  "updated": "$(date -Iseconds)",
  "features": {
    "total": 0,
    "decomposed": 0,
    "approved": 0
  },
  "atoms": {
    "total": 0,
    "done": 0,
    "running": 0,
    "failed": 0,
    "blocked": 0,
    "queued": 0
  }
}
EOF

    echo "Epic $epic_id initialized at $epic_dir"
}

# Initialize feature directory structure  
init_feature() {
    local project_id="$1"
    local epic_id="$2" 
    local feature_id="$3"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    local feature_dir="$project_dir/epics/$epic_id/features/$feature_id"
    
    echo "Initializing feature: $feature_id in epic $epic_id" >&2
    
    # Create feature directory structure
    mkdir -p "$feature_dir/atoms"
    
    # Create initial feature state
    cat > "$feature_dir/state.json" << EOF
{
  "featureId": "$feature_id",
  "epicId": "$epic_id", 
  "projectId": "$project_id",
  "status": "planned",
  "created": "$(date -Iseconds)",
  "updated": "$(date -Iseconds)",
  "atoms": {
    "total": 0,
    "done": 0,
    "running": 0,
    "failed": 0,
    "blocked": 0,
    "queued": 0
  }
}
EOF

    echo "Feature $feature_id initialized at $feature_dir"
}

# Get state value from JSON file
get_state() {
    local project_id="$1"
    local key_path="$2"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    
    if [[ ! -f "$project_dir/state.json" ]]; then
        echo "Project $project_id not found" >&2
        return 1
    fi
    
    jq -r "$key_path" "$project_dir/state.json"
}

# Get epic state value
get_epic_state() {
    local project_id="$1"
    local epic_id="$2"
    local key_path="$3"
    local epic_dir="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id"
    
    if [[ ! -f "$epic_dir/state.json" ]]; then
        echo "Epic $epic_id not found in project $project_id" >&2
        return 1
    fi
    
    jq -r "$key_path" "$epic_dir/state.json"
}

# Get feature state value
get_feature_state() {
    local project_id="$1"
    local epic_id="$2"
    local feature_id="$3"
    local key_path="$4"
    local feature_dir="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/features/$feature_id"
    
    if [[ ! -f "$feature_dir/state.json" ]]; then
        echo "Feature $feature_id not found" >&2
        return 1
    fi
    
    jq -r "$key_path" "$feature_dir/state.json"
}

# Set state value in JSON file with atomic update
set_state() {
    local project_id="$1"
    local key_path="$2"
    local value="$3"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    local state_file="$project_dir/state.json"
    
    if [[ ! -f "$state_file" ]]; then
        echo "Project $project_id not found" >&2
        return 1
    fi
    
    # Create temp file for atomic update
    local temp_file=$(mktemp)
    
    # Update state and timestamp
    jq --arg key "$key_path" --arg val "$value" --arg updated "$(date -Iseconds)" \
        'setpath($key | split("."); $val) | .updated = $updated' \
        "$state_file" > "$temp_file"
    
    # Atomic move
    mv "$temp_file" "$state_file"
    
    echo "Updated $project_id state: $key_path = $value"
}

# Set epic state value
set_epic_state() {
    local project_id="$1"
    local epic_id="$2"
    local key_path="$3"
    local value="$4"
    local epic_dir="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id"
    local state_file="$epic_dir/state.json"
    
    if [[ ! -f "$state_file" ]]; then
        echo "Epic $epic_id not found" >&2
        return 1
    fi
    
    # Create temp file for atomic update
    local temp_file=$(mktemp)
    
    # Update state and timestamp
    jq --arg key "$key_path" --arg val "$value" --arg updated "$(date -Iseconds)" \
        'setpath($key | split("."); $val) | .updated = $updated' \
        "$state_file" > "$temp_file"
    
    # Atomic move
    mv "$temp_file" "$state_file"
    
    echo "Updated epic $epic_id state: $key_path = $value"
}

# Set feature state value
set_feature_state() {
    local project_id="$1"
    local epic_id="$2"
    local feature_id="$3"
    local key_path="$4"
    local value="$5"
    local feature_dir="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/features/$feature_id"
    local state_file="$feature_dir/state.json"
    
    if [[ ! -f "$state_file" ]]; then
        echo "Feature $feature_id not found" >&2
        return 1
    fi
    
    # Create temp file for atomic update
    local temp_file=$(mktemp)
    
    # Update state and timestamp
    jq --arg key "$key_path" --arg val "$value" --arg updated "$(date -Iseconds)" \
        'setpath($key | split("."); $val) | .updated = $updated' \
        "$state_file" > "$temp_file"
    
    # Atomic move
    mv "$temp_file" "$state_file"
    
    echo "Updated feature $feature_id state: $key_path = $value"
}

# Increment numeric state value
increment_state() {
    local project_id="$1"
    local key_path="$2"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    local state_file="$project_dir/state.json"
    
    if [[ ! -f "$state_file" ]]; then
        echo "Project $project_id not found" >&2
        return 1
    fi
    
    # Create temp file for atomic update
    local temp_file=$(mktemp)
    
    # Increment value and update timestamp
    jq --arg key "$key_path" --arg updated "$(date -Iseconds)" \
        'setpath($key | split("."); getpath($key | split(".")) + 1) | .updated = $updated' \
        "$state_file" > "$temp_file"
    
    # Atomic move
    mv "$temp_file" "$state_file"
    
    echo "Incremented $project_id state: $key_path"
}

# List all projects
list_projects() {
    ensure_projects_dir
    for project_dir in "$FORGE_PROJECTS_DIR"/*; do
        if [[ -d "$project_dir" && -f "$project_dir/state.json" ]]; then
            local project_id=$(basename "$project_dir")
            local status=$(get_state "$project_id" ".status")
            echo "$project_id: $status"
        fi
    done
}

# Get current project status summary
project_status() {
    local project_id="$1"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    
    if [[ ! -f "$project_dir/state.json" ]]; then
        echo "Project $project_id not found" >&2
        return 1
    fi
    
    echo "Project: $project_id"
    echo "Status: $(get_state "$project_id" ".status")"
    echo "Created: $(get_state "$project_id" ".created")"
    echo "Updated: $(get_state "$project_id" ".updated")"
    echo ""
    echo "Progress:"
    echo "  Project: $(get_state "$project_id" ".scales.project")"
    echo "  Epics: $(get_state "$project_id" ".scales.epics.approved")/$(get_state "$project_id" ".scales.epics.total")"
    echo "  Features: $(get_state "$project_id" ".scales.features.approved")/$(get_state "$project_id" ".scales.features.total")"
    echo "  Atoms: $(get_state "$project_id" ".scales.atoms.done")/$(get_state "$project_id" ".scales.atoms.total")"
    echo ""
    echo "Current Work:"
    echo "  Epic: $(get_state "$project_id" ".currentWork.epic")"
    echo "  Feature: $(get_state "$project_id" ".currentWork.feature")"
    echo "  Atom: $(get_state "$project_id" ".currentWork.atom")"
    echo "  Worker: $(get_state "$project_id" ".currentWork.workerSession")"
}

# Validate project exists
project_exists() {
    local project_id="$1"
    [[ -f "$FORGE_PROJECTS_DIR/$project_id/state.json" ]]
}

# Validate epic exists
epic_exists() {
    local project_id="$1"
    local epic_id="$2"
    [[ -f "$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/state.json" ]]
}

# Validate feature exists  
feature_exists() {
    local project_id="$1"
    local epic_id="$2"
    local feature_id="$3"
    [[ -f "$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/features/$feature_id/state.json" ]]
}

# Export functions for sourcing
export -f ensure_projects_dir
export -f init_project init_epic init_feature
export -f get_state get_epic_state get_feature_state
export -f set_state set_epic_state set_feature_state
export -f increment_state
export -f list_projects project_status
export -f project_exists epic_exists feature_exists