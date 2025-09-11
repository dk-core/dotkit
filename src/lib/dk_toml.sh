#!/usr/bin/env bash
# dk_toml.sh - TOML parsing and processing utilities for dotkit

# Global data structures for batch-loaded TOML data
declare -gA _DK_TOML_METADATA      # metadata by file path
declare -gA _DK_TOML_FILES         # file mappings by source file
declare -gA _DK_TOML_EVENTS        # events by type and file
declare -ga _DK_TOML_ERRORS        # collected errors
declare -ga _DK_TOML_WARNINGS      # collected warnings
declare -ga _DK_TOML_ALL_FILES     # all discovered TOML files

# Caching data structures (Phase 3)
declare -gA _DK_TOML_CACHE_MTIME   # file modification times for cache validation
declare -g _DK_TOML_CACHE_VALID=0  # cache validity flag

# Cache validation function (Phase 3)
dk_toml_is_cache_valid() {
    local -a toml_files
    mapfile -t toml_files < <(dk_toml_find_all_fast)
    
    # Check if cache is marked as valid
    if [[ $_DK_TOML_CACHE_VALID -eq 0 ]]; then
        dk_debug "Cache marked as invalid"
        return 1
    fi
    
    # Check if any files have been modified since last cache
    local toml_file current_mtime cached_mtime
    for toml_file in "${toml_files[@]}"; do
        if [[ -f "$toml_file" ]]; then
            current_mtime=$(stat -c %Y "$toml_file" 2>/dev/null || echo "0")
            cached_mtime="${_DK_TOML_CACHE_MTIME[$toml_file]:-0}"
            
            if [[ "$current_mtime" != "$cached_mtime" ]]; then
                dk_debug "File modified since cache: $toml_file"
                return 1
            fi
        fi
    done
    
    dk_debug "Cache is valid"
    return 0
}

# Update cache timestamps (Phase 3)
dk_toml_update_cache_timestamps() {
    local -a toml_files
    mapfile -t toml_files < <(dk_toml_find_all_fast)
    
    local toml_file mtime
    for toml_file in "${toml_files[@]}"; do
        if [[ -f "$toml_file" ]]; then
            mtime=$(stat -c %Y "$toml_file" 2>/dev/null || echo "0")
            _DK_TOML_CACHE_MTIME["$toml_file"]="$mtime"
        fi
    done
    
    _DK_TOML_CACHE_VALID=1
    dk_debug "Cache timestamps updated"
}

# Optimized file discovery for large scale (Phase 4)
dk_toml_find_all_fast() {
    local -a toml_files=()
    
    # Use find for better performance with large directory trees
    if [[ -d "$DK_DOTFILE" ]]; then
        while IFS= read -r -d '' toml_file; do
            toml_files+=("$toml_file")
        done < <(find "$DK_DOTFILE" -name "dotkit.toml" -type f -print0 2>/dev/null)
    fi
    
    if [[ -d "$DK_PROFILE" ]]; then
        while IFS= read -r -d '' toml_file; do
            toml_files+=("$toml_file")
        done < <(find "$DK_PROFILE" -name "dotkit.toml" -type f -print0 2>/dev/null)
    fi
    
    # Store globally for other functions to use
    _DK_TOML_ALL_FILES=("${toml_files[@]}")
    
    # Only print files if we have any - avoid printing empty line
    if [[ ${#toml_files[@]} -gt 0 ]]; then
        printf '%s\n' "${toml_files[@]}"
    fi
    return 0
}

# Discovery Functions
dk_toml_find_all() {
    local -a toml_files=()
    
    dk_debug "Starting TOML file discovery"
    
    # Use optimized discovery for large file counts
    if [[ -d "$DK_DOTFILE/modules" ]] && [[ $(find "$DK_DOTFILE/modules" -maxdepth 1 -type d 2>/dev/null | wc -l) -gt 50 ]]; then
        dk_debug "Using optimized discovery for large module count"
        dk_toml_find_all_fast
        return 0
    fi
    
    # Standard discovery for smaller file counts
    # 1. DK_DOTFILE/dotkit.toml
    if [[ -f "$DK_DOTFILE/dotkit.toml" ]]; then
        toml_files+=("$DK_DOTFILE/dotkit.toml")
        dk_debug "Found dotfile TOML: $DK_DOTFILE/dotkit.toml"
    fi
    
    # 2. DK_DOTFILE/modules/*/dotkit.toml
    for toml_file in "$DK_DOTFILE"/modules/*/dotkit.toml; do
        if [[ -f "$toml_file" ]]; then
            toml_files+=("$toml_file")
            dk_debug "Found dotfile module TOML: $toml_file"
        fi
    done
    
    # 3. DK_PROFILE/dotkit.toml
    if [[ -f "$DK_PROFILE/dotkit.toml" ]]; then
        toml_files+=("$DK_PROFILE/dotkit.toml")
        dk_debug "Found profile TOML: $DK_PROFILE/dotkit.toml"
    fi
    
    # 4. DK_PROFILE/modules/*/dotkit.toml
    for toml_file in "$DK_PROFILE"/modules/*/dotkit.toml; do
        if [[ -f "$toml_file" ]]; then
            toml_files+=("$toml_file")
            dk_debug "Found profile module TOML: $toml_file"
        fi
    done
    
    # Store globally for other functions to use
    _DK_TOML_ALL_FILES=("${toml_files[@]}")
    
    dk_debug "Discovered ${#toml_files[@]} TOML files total"
    
    # Only print files if we have any - avoid printing empty line
    if [[ ${#toml_files[@]} -gt 0 ]]; then
        printf '%s\n' "${toml_files[@]}"
    fi
    return 0  # Always return success - finding 0 files is not an error
}

# Optimized single-pass TOML extraction function
dk_toml_extract_single_pass() {
    local toml_file="$1"
    
    dk_debug "Single-pass extraction for: $toml_file"
    
    # Single yq call to extract all data at once in a parseable format
    local extraction_result
    extraction_result=$(yq -p toml -o tsv '{
        "name": .name,
        "version": .version // "null",
        "description": .description // "null", 
        "type": .type,
        "files": (.files // {} | to_entries | map(.key + "|" + .value) | join(";")),
        "events": (.events // {} | to_entries | map(.key as $type | .value | to_entries | map($type + "|" + .key + "=" + .value)) | flatten | join(";"))
    } | [.name, .version, .description, .type, .files, .events] | @tsv' "$toml_file" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$extraction_result" ]]; then
        _DK_TOML_ERRORS+=("Invalid TOML syntax: $toml_file")
        dk_error "Invalid TOML syntax in $toml_file"
        return 1
    fi
    
    # Parse the TSV result (tab-separated values)
    local name version description type files events
    IFS=$'\t' read -r name version description type files events <<< "$extraction_result"
    
    # Validate required fields
    if [[ -z "$name" || "$name" == "null" ]]; then
        _DK_TOML_ERRORS+=("Missing required field 'name' in $toml_file")
        dk_error "Missing required field 'name' in $toml_file"
        return 1
    fi
    
    if [[ -z "$type" || "$type" == "null" ]]; then
        _DK_TOML_ERRORS+=("Missing required field 'type' in $toml_file")
        dk_error "Missing required field 'type' in $toml_file"
        return 1
    fi
    
    # Validate type field values
    if [[ ! "$type" =~ ^(module|dotfile|profile)$ ]]; then
        _DK_TOML_WARNINGS+=("Unknown type '$type' in $toml_file (expected: module, dotfile, profile)")
        dk_warn "Unknown type '$type' in $toml_file"
    fi
    
    # Store extracted data
    _DK_TOML_METADATA["$toml_file"]="name=$name|version=$version|description=$description|type=$type"
    
    if [[ -n "$files" && "$files" != "null" ]]; then
        _DK_TOML_FILES["$toml_file"]="$files"
    fi
    
    if [[ -n "$events" && "$events" != "null" ]]; then
        _DK_TOML_EVENTS["$toml_file"]="$events"
    fi
    
    dk_debug "Single-pass extraction completed for $toml_file: name=$name, type=$type"
    return 0
}

# Parallel processing helper function
dk_toml_extract_single_pass_parallel() {
    local toml_file="$1"
    
    # Single yq call to extract all data at once in a parseable format
    local extraction_result
    extraction_result=$(yq -p toml -o tsv '{
        "name": .name,
        "version": .version // "null",
        "description": .description // "null", 
        "type": .type,
        "files": (.files // {} | to_entries | map(.key + "|" + .value) | join(";")),
        "events": (.events // {} | to_entries | map(.key as $type | .value | to_entries | map($type + "|" + .key + "=" + .value)) | flatten | join(";"))
    } | [.name, .version, .description, .type, .files, .events] | @tsv' "$toml_file" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$extraction_result" ]]; then
        echo "ERROR:$toml_file:Invalid TOML syntax"
        return 1
    fi
    
    # Parse the TSV result (tab-separated values)
    local name version description type files events
    IFS=$'\t' read -r name version description type files events <<< "$extraction_result"
    
    # Validate required fields
    if [[ -z "$name" || "$name" == "null" ]]; then
        echo "ERROR:$toml_file:Missing required field 'name'"
        return 1
    fi
    
    if [[ -z "$type" || "$type" == "null" ]]; then
        echo "ERROR:$toml_file:Missing required field 'type'"
        return 1
    fi
    
    # Validate type field values
    if [[ ! "$type" =~ ^(module|dotfile|profile)$ ]]; then
        echo "WARNING:$toml_file:Unknown type '$type' (expected: module, dotfile, profile)"
    fi
    
    # Output structured result for parent process to parse
    echo "SUCCESS:$toml_file:$name:$version:$description:$type:$files:$events"
    return 0
}

# Batch Processing Functions
dk_toml_load_all() {
    dk_debug "Starting optimized batch TOML processing"
    
    # Clear previous data
    _DK_TOML_METADATA=()
    _DK_TOML_FILES=()
    _DK_TOML_EVENTS=()
    _DK_TOML_ERRORS=()
    _DK_TOML_WARNINGS=()
    _DK_TOML_ALL_FILES=()
    
    # Discover all TOML files
    local -a toml_files
    mapfile -t toml_files < <(dk_toml_find_all)
    
    # Ensure the global array is set correctly after discovery
    _DK_TOML_ALL_FILES=("${toml_files[@]}")
    
    if [[ ${#toml_files[@]} -eq 0 ]]; then
        dk_debug "No TOML files found"
        return 0
    fi
    
    # Choose processing method based on file count and parallel availability
    if [[ ${#toml_files[@]} -ge 10 ]] && command -v parallel >/dev/null 2>&1; then
        dk_debug "Using parallel processing for ${#toml_files[@]} files"
        dk_toml_load_all_parallel "${toml_files[@]}"
    else
        dk_debug "Using sequential processing for ${#toml_files[@]} files"
        # Process all files using optimized single-pass extraction
        local toml_file
        for toml_file in "${toml_files[@]}"; do
            dk_toml_extract_single_pass "$toml_file"
        done
    fi
    
    # If validation errors exist, report and exit
    if [[ ${#_DK_TOML_ERRORS[@]} -gt 0 ]]; then
        dk_toml_report_errors
        return 1
    fi
    
    # Report any warnings collected during processing
    if [[ ${#_DK_TOML_WARNINGS[@]} -gt 0 ]]; then
        dk_toml_report_warnings
    fi
    
    dk_debug "Optimized batch TOML processing completed successfully"
    return 0
}

# Parallel processing implementation
dk_toml_load_all_parallel() {
    local toml_files=("$@")
    
    dk_debug "Processing ${#toml_files[@]} files in parallel"
    
    # Export the function so parallel can use it
    export -f dk_toml_extract_single_pass_parallel
    
    # Process files in parallel and collect results
    local parallel_results
    parallel_results=$(printf '%s\n' "${toml_files[@]}" | parallel -j+0 dk_toml_extract_single_pass_parallel)
    
    # Parse parallel results
    local line
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        local status toml_file name version description type files events
        IFS=':' read -r status toml_file name version description type files events <<< "$line"
        
        case "$status" in
            "SUCCESS")
                # Store extracted data
                _DK_TOML_METADATA["$toml_file"]="name=$name|version=$version|description=$description|type=$type"
                
                if [[ -n "$files" && "$files" != "null" ]]; then
                    _DK_TOML_FILES["$toml_file"]="$files"
                fi
                
                if [[ -n "$events" && "$events" != "null" ]]; then
                    _DK_TOML_EVENTS["$toml_file"]="$events"
                fi
                
                dk_debug "Parallel extraction completed for $toml_file: name=$name, type=$type"
                ;;
            "ERROR")
                _DK_TOML_ERRORS+=("$name in $toml_file")
                dk_error "$name in $toml_file"
                ;;
            "WARNING")
                _DK_TOML_WARNINGS+=("$name in $toml_file")
                dk_warn "$name in $toml_file"
                ;;
        esac
    done <<< "$parallel_results"
}

dk_toml_batch_validate() {
    local toml_files=("$@")
    
    dk_debug "Validating ${#toml_files[@]} TOML files"
    
    for toml_file in "${toml_files[@]}"; do
        dk_debug "Validating TOML file: $toml_file"
        
        # Test TOML syntax validity by trying to read any field
        if ! yq -p toml '.name' "$toml_file" >/dev/null 2>&1; then
            _DK_TOML_ERRORS+=("Invalid TOML syntax: $toml_file")
            dk_error "Invalid TOML syntax in $toml_file"
            continue
        fi
        
        # Check required fields
        local name type
        name=$(yq -p toml '.name' "$toml_file" 2>/dev/null)
        type=$(yq -p toml '.type' "$toml_file" 2>/dev/null)
        
        if [[ -z "$name" || "$name" == "null" ]]; then
            _DK_TOML_ERRORS+=("Missing required field 'name' in $toml_file")
            dk_error "Missing required field 'name' in $toml_file"
        fi
        
        if [[ -z "$type" || "$type" == "null" ]]; then
            _DK_TOML_ERRORS+=("Missing required field 'type' in $toml_file")
            dk_error "Missing required field 'type' in $toml_file"
        fi
        
        # Validate type field values
        if [[ -n "$type" && ! "$type" =~ ^(module|dotfile|profile)$ ]]; then
            _DK_TOML_WARNINGS+=("Unknown type '$type' in $toml_file (expected: module, dotfile, profile)")
            dk_warn "Unknown type '$type' in $toml_file"
        fi
    done
}

dk_toml_batch_process() {
    local toml_files=("$@")
    
    dk_debug "Batch processing ${#toml_files[@]} TOML files"
    
    # Process metadata for all files
    dk_toml_batch_get_metadata "${toml_files[@]}"
    
    # Process file mappings for all files
    dk_toml_batch_get_files "${toml_files[@]}"
    
    # Process events for all files
    dk_toml_batch_get_events "${toml_files[@]}"
}

dk_toml_batch_get_metadata() {
    local toml_files=("$@")
    
    dk_debug "Extracting metadata from ${#toml_files[@]} TOML files"
    
    for toml_file in "${toml_files[@]}"; do
        dk_debug "Processing metadata for: $toml_file"
        
        local name version description type
        name=$(yq -p toml '.name' "$toml_file" 2>/dev/null)
        version=$(yq -p toml '.version' "$toml_file" 2>/dev/null)
        description=$(yq -p toml '.description' "$toml_file" 2>/dev/null)
        type=$(yq -p toml '.type' "$toml_file" 2>/dev/null)
        
        # Store metadata as structured string
        _DK_TOML_METADATA["$toml_file"]="name=$name|version=$version|description=$description|type=$type"
        
        dk_debug "Stored metadata for $toml_file: name=$name, type=$type"
    done
}

dk_toml_batch_get_files() {
    local toml_files=("$@")
    
    dk_debug "Extracting file mappings from ${#toml_files[@]} TOML files"
    
    for toml_file in "${toml_files[@]}"; do
        dk_debug "Processing file mappings for: $toml_file"
        
        # Check if [files] section exists first
        if ! yq -p toml '.files' "$toml_file" >/dev/null 2>&1; then
            dk_debug "No [files] section in $toml_file"
            continue
        fi
        
        # Extract file mappings using yq's to_entries
        local files_data
        files_data=$(yq -p toml '.files | to_entries | .[] | .key + "|" + .value' "$toml_file" 2>/dev/null | tr '\n' ';')
        
        if [[ -n "$files_data" ]]; then
            _DK_TOML_FILES["$toml_file"]="${files_data%;}"  # Remove trailing semicolon
            dk_debug "Stored file mappings for $toml_file"
        fi
    done
}

dk_toml_batch_get_events() {
    local toml_files=("$@")
    
    dk_debug "Extracting events from ${#toml_files[@]} TOML files"
    
    for toml_file in "${toml_files[@]}"; do
        dk_debug "Processing events for: $toml_file"
        
        # Check if [events] section exists first
        if ! yq -p toml '.events' "$toml_file" >/dev/null 2>&1; then
            dk_debug "No [events] section in $toml_file"
            continue
        fi
        
        # Extract events using yq - get all event types and their commands
        local events_data
        events_data=$(yq -p toml '.events | to_entries | .[] as $event_type | $event_type.value | to_entries | .[] | $event_type.key + "|" + .key + "=" + .value' "$toml_file" 2>/dev/null | tr '\n' ';')
        
        if [[ -n "$events_data" ]]; then
            _DK_TOML_EVENTS["$toml_file"]="${events_data%;}"  # Remove trailing semicolon
            dk_debug "Stored events for $toml_file"
        fi
    done
}

# Accessor Functions for Pre-loaded Data
dk_toml_get_metadata_for_file() {
    local toml_file="$1"
    
    if [[ -n "${_DK_TOML_METADATA[$toml_file]:-}" ]]; then
        echo "${_DK_TOML_METADATA[$toml_file]}"
    else
        dk_debug "No metadata found for $toml_file"
        return 1
    fi
}

dk_toml_get_all_metadata() {
    local toml_file metadata
    
    for toml_file in "${!_DK_TOML_METADATA[@]}"; do
        metadata="${_DK_TOML_METADATA[$toml_file]}"
        echo "$toml_file|$metadata"
    done
}

dk_toml_get_files_for_file() {
    local toml_file="$1"
    
    if [[ -n "${_DK_TOML_FILES[$toml_file]:-}" ]]; then
        echo "${_DK_TOML_FILES[$toml_file]}" | tr ';' '\n'
        return 0
    else
        dk_debug "No file mappings found for $toml_file"
        return 1
    fi
}

dk_toml_get_all_file_mappings() {
    local toml_file files
    
    for toml_file in "${!_DK_TOML_FILES[@]}"; do
        files="${_DK_TOML_FILES[$toml_file]}"
        echo "$toml_file|$files"
    done
}

dk_toml_get_events_for_file() {
    local toml_file="$1"
    
    if [[ -n "${_DK_TOML_EVENTS[$toml_file]:-}" ]]; then
        echo "${_DK_TOML_EVENTS[$toml_file]}" | tr ';' '\n'
        return 0
    else
        dk_debug "No events found for $toml_file"
        return 1
    fi
}

dk_toml_get_events_by_type() {
    local event_type="$1"
    local toml_file events
    
    for toml_file in "${!_DK_TOML_EVENTS[@]}"; do
        events="${_DK_TOML_EVENTS[$toml_file]}"
        # Check if this file has events of the specified type
        if echo "$events" | tr ';' '\n' | grep -q "^$event_type|"; then
            echo "$toml_file|$event_type"
        fi
    done
}

# Error and Warning Reporting
dk_toml_report_errors() {
    if [[ ${#_DK_TOML_ERRORS[@]} -gt 0 ]]; then
        dk_error_list "TOML Processing Errors" "${_DK_TOML_ERRORS[@]}"
    fi
}

dk_toml_report_warnings() {
    if [[ ${#_DK_TOML_WARNINGS[@]} -gt 0 ]]; then
        dk_warn_list "TOML Processing Warnings" "${_DK_TOML_WARNINGS[@]}"
    fi
}

# Validation Functions
dk_toml_validate() {
    local toml_file="$1"
    
    if [[ ! -f "$toml_file" ]]; then
        dk_error "TOML file does not exist: $toml_file"
        return 1
    fi
    
    # Test TOML syntax by trying to read any field
    if ! yq -p toml '.name' "$toml_file" >/dev/null 2>&1; then
        dk_error "Invalid TOML syntax in $toml_file"
        return 1
    fi
    
    # Check required fields
    local name type
    name=$(yq -p toml '.name' "$toml_file" 2>/dev/null)
    type=$(yq -p toml '.type' "$toml_file" 2>/dev/null)
    
    if [[ -z "$name" || "$name" == "null" ]]; then
        dk_error "Missing required field 'name' in $toml_file"
        return 1
    fi
    
    if [[ -z "$type" || "$type" == "null" ]]; then
        dk_error "Missing required field 'type' in $toml_file"
        return 1
    fi
    
    dk_debug "TOML validation passed for $toml_file"
    return 0
}

# Utility Functions
dk_toml_list_discovered_files() {
    printf '%s\n' "${_DK_TOML_ALL_FILES[@]}"
}

dk_toml_count_files() {
    echo "${#_DK_TOML_ALL_FILES[@]}"
}

# Bulk processing mode for extreme scale (Phase 5)
dk_toml_load_all_bulk() {
    local toml_files=("$@")
    
    dk_debug "Using bulk processing mode for ${#toml_files[@]} files"
    
    # Create temporary file for bulk processing
    local temp_bulk_file
    temp_bulk_file=$(mktemp)
    
    # Combine all TOML files with metadata separators
    local toml_file
    for toml_file in "${toml_files[@]}"; do
        echo "---BULK_FILE:$toml_file"
        cat "$toml_file" 2>/dev/null || echo "# ERROR: Could not read file"
    done > "$temp_bulk_file"
    
    # Process the bulk file with a single yq operation
    local bulk_results
    bulk_results=$(awk '
        BEGIN { current_file = ""; content = "" }
        /^---BULK_FILE:/ { 
            if (current_file != "") {
                print "FILE:" current_file
                print content
                print "---END---"
            }
            current_file = substr($0, 13)
            content = ""
            next
        }
        { content = content $0 "\n" }
        END {
            if (current_file != "") {
                print "FILE:" current_file
                print content
                print "---END---"
            }
        }
    ' "$temp_bulk_file" | while IFS= read -r line; do
        if [[ "$line" =~ ^FILE: ]]; then
            current_file="${line#FILE:}"
        elif [[ "$line" == "---END---" ]]; then
            # Process accumulated content for current_file
            echo "PROCESSED:$current_file"
        fi
    done)
    
    # Clean up temporary file
    rm -f "$temp_bulk_file"
    
    # Fall back to parallel processing for now
    # (Bulk processing is complex and would need more development)
    dk_toml_load_all_parallel "${toml_files[@]}"
}

dk_toml_clear_cache() {
    _DK_TOML_METADATA=()
    _DK_TOML_FILES=()
    _DK_TOML_EVENTS=()
    _DK_TOML_ERRORS=()
    _DK_TOML_WARNINGS=()
    _DK_TOML_ALL_FILES=()
    _DK_TOML_CACHE_MTIME=()
    _DK_TOML_CACHE_VALID=0
    dk_debug "TOML cache cleared"
}
