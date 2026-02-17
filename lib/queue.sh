#!/bin/bash

# Forge Queue Management Library  
# Bash helpers for task queue management and atom execution

set -euo pipefail

# Source state management functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/state.sh"

# Find next ready atom for execution
next_atom() {
    local project_id="$1"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    
    if [[ ! -d "$project_dir" ]]; then
        echo "Project $project_id not found" >&2
        return 1
    fi
    
    # Look through all atoms in all features to find next ready one
    find "$project_dir" -name "*.md" -path "*/atoms/*" | while read -r atom_file; do
        # Extract path components
        local atom_name=$(basename "$atom_file" .md)
        local atoms_dir=$(dirname "$atom_file")
        local feature_dir=$(dirname "$atoms_dir")
        local features_dir=$(dirname "$feature_dir")
        local epic_dir=$(dirname "$features_dir")
        
        local feature_id=$(basename "$feature_dir")
        local epic_id=$(basename "$epic_dir")
        
        # Read atom status from file
        local atom_status=$(get_atom_status "$project_id" "$epic_id" "$feature_id" "$atom_name")
        
        if [[ "$atom_status" == "READY" ]]; then
            echo "$epic_id/$feature_id/$atom_name"
            return 0
        fi
    done
    
    echo "No ready atoms found" >&2
    return 1
}

# Get atom status from atom.md file  
get_atom_status() {
    local project_id="$1"
    local epic_id="$2"
    local feature_id="$3"
    local atom_name="$4"
    
    local atom_file="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/features/$feature_id/atoms/$atom_name.md"
    
    if [[ ! -f "$atom_file" ]]; then
        echo "MISSING"
        return 1
    fi
    
    # Extract status from atom file (look for "Status: PLANNED/READY/..." in dependencies section)
    grep -E "^- \*\*Status\*\*:" "$atom_file" | sed 's/.*Status\*\*: \([A-Z_]*\).*/\1/' || echo "UNKNOWN"
}

# Set atom status in atom.md file
set_atom_status() {
    local project_id="$1"
    local epic_id="$2"
    local feature_id="$3"
    local atom_name="$4"
    local new_status="$5"
    
    local atom_file="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/features/$feature_id/atoms/$atom_name.md"
    
    if [[ ! -f "$atom_file" ]]; then
        echo "Atom file not found: $atom_file" >&2
        return 1
    fi
    
    # Update status line in atom file
    sed -i "s/^- \*\*Status\*\*: [A-Z_]*/- **Status**: $new_status/" "$atom_file"
    
    echo "Updated atom $atom_name status to $new_status"
}

# Mark atom with new status and update timestamps
mark_atom() {
    local project_id="$1"
    local epic_id="$2"  
    local feature_id="$3"
    local atom_name="$4"
    local new_status="$5"
    local worker_session="${6:-}"
    
    local atom_file="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/features/$feature_id/atoms/$atom_name.md"
    
    if [[ ! -f "$atom_file" ]]; then
        echo "Atom file not found: $atom_file" >&2
        return 1
    fi
    
    # Update status
    set_atom_status "$project_id" "$epic_id" "$feature_id" "$atom_name" "$new_status"
    
    # Update timestamps in atom file based on status
    local timestamp=$(date -Iseconds)
    case "$new_status" in
        "IN_PROGRESS")
            # Update assigned and started fields
            sed -i "s/^- \*\*Assigned\*\*: .*/- **Assigned**: $worker_session/" "$atom_file"
            sed -i "s/^- \*\*Started\*\*: .*/- **Started**: $timestamp/" "$atom_file"
            ;;
        "DONE"|"FAILED"|"BLOCKED")
            # Update completed field
            sed -i "s/^- \*\*Completed\*\*: .*/- **Completed**: $timestamp/" "$atom_file"
            
            # Update project-level counters
            case "$new_status" in
                "DONE")
                    increment_state "$project_id" "scales.atoms.done"
                    ;;
                "FAILED") 
                    increment_state "$project_id" "scales.atoms.failed"
                    ;;
                "BLOCKED")
                    increment_state "$project_id" "scales.atoms.blocked"
                    ;;
            esac
            ;;
    esac
    
    # Update project current work if this is the active atom
    if [[ "$new_status" == "IN_PROGRESS" ]]; then
        set_state "$project_id" "currentWork.epic" "$epic_id"
        set_state "$project_id" "currentWork.feature" "$feature_id" 
        set_state "$project_id" "currentWork.atom" "$atom_name"
        set_state "$project_id" "currentWork.workerSession" "$worker_session"
    elif [[ "$new_status" == "DONE" || "$new_status" == "FAILED" || "$new_status" == "BLOCKED" ]]; then
        # Clear current work if this was the active atom
        local current_atom=$(get_state "$project_id" "currentWork.atom")
        if [[ "$current_atom" == "$atom_name" ]]; then
            set_state "$project_id" "currentWork.epic" "null"
            set_state "$project_id" "currentWork.feature" "null"
            set_state "$project_id" "currentWork.atom" "null"
            set_state "$project_id" "currentWork.workerSession" "null"
        fi
    fi
    
    echo "Marked atom $atom_name as $new_status"
}

# Check if atom dependencies are satisfied
atom_dependencies_ready() {
    local project_id="$1"
    local epic_id="$2"
    local feature_id="$3"
    local atom_name="$4"
    
    local atom_file="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/features/$feature_id/atoms/$atom_name.md"
    
    if [[ ! -f "$atom_file" ]]; then
        return 1
    fi
    
    # Extract prerequisite atoms from the Dependencies section
    local in_prereqs=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^###[[:space:]]*Prerequisites ]]; then
            in_prereqs=true
            continue
        elif [[ "$line" =~ ^### ]] && [[ "$in_prereqs" == true ]]; then
            # Hit next section, stop reading prereqs
            break
        elif [[ "$in_prereqs" == true && "$line" =~ ^-[[:space:]]*\[[[:space:]]*\][[:space:]]*Atom ]]; then
            # Found a prerequisite: - [ ] Atom XXX: description
            local prereq_atom=$(echo "$line" | sed -E 's/.*Atom ([^:]*).*/\1/')
            
            # Check if this prerequisite is complete
            local prereq_status=$(get_atom_status "$project_id" "$epic_id" "$feature_id" "$prereq_atom")
            if [[ "$prereq_status" != "DONE" ]]; then
                echo "Dependency not ready: $prereq_atom ($prereq_status)" >&2
                return 1
            fi
        fi
    done < "$atom_file"
    
    return 0
}

# Update all atom statuses based on dependencies
refresh_atom_queue() {
    local project_id="$1"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    
    echo "Refreshing atom queue for project $project_id..." >&2
    
    # Find all atoms
    find "$project_dir" -name "*.md" -path "*/atoms/*" | while read -r atom_file; do
        # Extract path components
        local atom_name=$(basename "$atom_file" .md)
        local atoms_dir=$(dirname "$atom_file")
        local feature_dir=$(dirname "$atoms_dir")
        local features_dir=$(dirname "$feature_dir")
        local epic_dir=$(dirname "$features_dir")
        
        local feature_id=$(basename "$feature_dir")
        local epic_id=$(basename "$epic_dir")
        
        local current_status=$(get_atom_status "$project_id" "$epic_id" "$feature_id" "$atom_name")
        
        # Only update PLANNED atoms
        if [[ "$current_status" == "PLANNED" ]]; then
            if atom_dependencies_ready "$project_id" "$epic_id" "$feature_id" "$atom_name"; then
                set_atom_status "$project_id" "$epic_id" "$feature_id" "$atom_name" "READY"
                echo "  $epic_id/$feature_id/$atom_name: PLANNED -> READY" >&2
            fi
        fi
    done
    
    echo "Queue refresh complete" >&2
}

# List all atoms with their current status
list_atoms() {
    local project_id="$1"
    local project_dir="$FORGE_PROJECTS_DIR/$project_id"
    local filter_status="${2:-}"
    
    if [[ ! -d "$project_dir" ]]; then
        echo "Project $project_id not found" >&2
        return 1
    fi
    
    echo "Atoms in project $project_id:"
    echo "Epic/Feature/Atom Status"
    echo "========================="
    
    # Find all atoms and display with status
    find "$project_dir" -name "*.md" -path "*/atoms/*" | sort | while read -r atom_file; do
        # Extract path components  
        local atom_name=$(basename "$atom_file" .md)
        local atoms_dir=$(dirname "$atom_file")
        local feature_dir=$(dirname "$atoms_dir")
        local features_dir=$(dirname "$feature_dir")
        local epic_dir=$(dirname "$features_dir")
        
        local feature_id=$(basename "$feature_dir")
        local epic_id=$(basename "$epic_dir")
        
        local atom_status=$(get_atom_status "$project_id" "$epic_id" "$feature_id" "$atom_name")
        
        # Apply status filter if specified
        if [[ -n "$filter_status" && "$atom_status" != "$filter_status" ]]; then
            continue
        fi
        
        printf "%-60s %s\n" "$epic_id/$feature_id/$atom_name" "$atom_status"
    done
}

# Get queue statistics
queue_stats() {
    local project_id="$1"
    
    echo "Queue Statistics for $project_id:"
    echo "=================================="
    
    local total=0
    local planned=0
    local ready=0
    local in_progress=0
    local done=0
    local failed=0
    local blocked=0
    
    list_atoms "$project_id" | tail -n +4 | while read -r line; do
        if [[ -n "$line" ]]; then
            local status=$(echo "$line" | awk '{print $NF}')
            case "$status" in
                "PLANNED") ((planned++)) ;;
                "READY") ((ready++)) ;;
                "IN_PROGRESS") ((in_progress++)) ;;
                "DONE") ((done++)) ;;
                "FAILED") ((failed++)) ;;
                "BLOCKED") ((blocked++)) ;;
            esac
            ((total++))
        fi
    done
    
    # Since we're in a subshell, we need to recalculate
    # This is inefficient but works for the counts we need
    total=$(list_atoms "$project_id" | tail -n +4 | wc -l)
    planned=$(list_atoms "$project_id" "PLANNED" | tail -n +4 | wc -l)
    ready=$(list_atoms "$project_id" "READY" | tail -n +4 | wc -l)
    in_progress=$(list_atoms "$project_id" "IN_PROGRESS" | tail -n +4 | wc -l)
    done=$(list_atoms "$project_id" "DONE" | tail -n +4 | wc -l)
    failed=$(list_atoms "$project_id" "FAILED" | tail -n +4 | wc -l)
    blocked=$(list_atoms "$project_id" "BLOCKED" | tail -n +4 | wc -l)
    
    echo "Total atoms: $total"
    echo "Planned: $planned"
    echo "Ready: $ready"  
    echo "In Progress: $in_progress"
    echo "Done: $done"
    echo "Failed: $failed"
    echo "Blocked: $blocked"
    
    if (( total > 0 )); then
        local completion_pct=$((done * 100 / total))
        echo "Completion: $completion_pct%"
    fi
}

# Find atoms ready for execution (no dependencies blocking)
find_ready_atoms() {
    local project_id="$1"
    local limit="${2:-5}"
    
    echo "Ready atoms (limit $limit):"
    list_atoms "$project_id" "READY" | head -n $((limit + 3))
}

# Check if a feature is complete (all atoms done)
feature_complete() {
    local project_id="$1"
    local epic_id="$2"
    local feature_id="$3"
    
    local feature_dir="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id/features/$feature_id"
    
    if [[ ! -d "$feature_dir/atoms" ]]; then
        return 1
    fi
    
    # Check if any atoms are not DONE
    find "$feature_dir/atoms" -name "*.md" | while read -r atom_file; do
        local atom_name=$(basename "$atom_file" .md)
        local status=$(get_atom_status "$project_id" "$epic_id" "$feature_id" "$atom_name")
        
        if [[ "$status" != "DONE" ]]; then
            return 1
        fi
    done
}

# Check if an epic is complete (all features complete)
epic_complete() {
    local project_id="$1"
    local epic_id="$2"
    
    local epic_dir="$FORGE_PROJECTS_DIR/$project_id/epics/$epic_id"
    
    if [[ ! -d "$epic_dir/features" ]]; then
        return 1
    fi
    
    # Check all features in the epic
    for feature_dir in "$epic_dir/features"/*; do
        if [[ -d "$feature_dir" ]]; then
            local feature_id=$(basename "$feature_dir")
            if ! feature_complete "$project_id" "$epic_id" "$feature_id"; then
                return 1
            fi
        fi
    done
    
    return 0
}

# Export functions for sourcing
export -f next_atom find_ready_atoms
export -f get_atom_status set_atom_status mark_atom
export -f atom_dependencies_ready refresh_atom_queue
export -f list_atoms queue_stats  
export -f feature_complete epic_complete