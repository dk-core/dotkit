#!/usr/bin/env bash
# dk_toml.sh - toml parsing for dotkit configs

# global storage for toml data - keeps everything in memory after loading
declare -gA _DK_TOML_DATA        # full toml data by file path
declare -ga _DK_TOML_ALL_FILES   # list of discovered toml files
declare -ga _DK_TOML_ERRORS      # validation errors
declare -ga _DK_TOML_WARNINGS    # validation warnings

# simple cache for frequently accessed parsed data
declare -gA _DK_TOML_CACHE_METADATA    # cached metadata results
declare -gA _DK_TOML_CACHE_FILES       # cached file results  
declare -gA _DK_TOML_CACHE_EVENTS      # cached event results

# find all dotkit.toml files in the usual places
dk_toml_find_all() {
    local -a toml_files=()
    
    dk_debug "looking for toml files"
    
    # check if we have tons of modules - use find for better performance
    if [[ -d "$DK_DOTFILE/modules" ]] && [[ $(find "$DK_DOTFILE/modules" -maxdepth 1 -type d 2>/dev/null | wc -l) -gt 50 ]]; then
        dk_debug "lots of modules found, using optimized search"
        
        # use find with null termination for safety
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
    else
        # standard search for smaller setups
        # 1. main dotfile config
        if [[ -f "$DK_DOTFILE/dotkit.toml" ]]; then
            toml_files+=("$DK_DOTFILE/dotkit.toml")
        fi
        
        # 2. dotfile modules
        for toml_file in "$DK_DOTFILE"/modules/*/dotkit.toml; do
            if [[ -f "$toml_file" ]]; then
                toml_files+=("$toml_file")
            fi
        done
        
        # 3. main profile config
        if [[ -f "$DK_PROFILE/dotkit.toml" ]]; then
            toml_files+=("$DK_PROFILE/dotkit.toml")
        fi
        
        # 4. profile modules
        for toml_file in "$DK_PROFILE"/modules/*/dotkit.toml; do
            if [[ -f "$toml_file" ]]; then
                toml_files+=("$toml_file")
            fi
        done
    fi
    
    # store globally so other functions can use it
    _DK_TOML_ALL_FILES=("${toml_files[@]}")
    
    dk_debug "found ${#toml_files[@]} toml files"
    
    # only print if we found files - avoids empty output
    if [[ ${#toml_files[@]} -gt 0 ]]; then
        printf '%s\n' "${toml_files[@]}"
    fi
    
    return 0
}

# read a single toml file and extract all the data we need
# this replaces all the separate batch functions - just read once, parse many times
dk_toml_read_file() {
    local toml_file="$1"
    
    if [[ ! -f "$toml_file" ]]; then
        dk_error "toml file not found: $toml_file"
        return 1
    fi
    
    dk_debug "reading toml file: $toml_file"
    
    # single yq call gets everything at once - this is the fast approach
    local result
    # shellcheck disable=SC2016
    result=$(yq -p toml -o tsv '{
        "name": .name,
        "version": .version // "null",
        "description": .description // "null", 
        "type": .type,
        "files": (.files // {} | to_entries | map(.key + "|" + .value) | join(";")),
        "events": (.events // {} | to_entries | map(.key as $type | .value | to_entries | map($type + "|" + .key + "=" + .value)) | flatten | join(";"))
    } | [.name, .version, .description, .type, .files, .events] | @tsv' "$toml_file" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$result" ]]; then
        _DK_TOML_ERRORS+=("invalid toml syntax: $toml_file")
        dk_error "bad toml syntax in $toml_file"
        return 1
    fi
    
    # parse the tab-separated result
    local name version description type files events
    IFS=$'\t' read -r name version description type files events <<< "$result"
    
    # check required fields
    if [[ -z "$name" || "$name" == "null" ]]; then
        _DK_TOML_ERRORS+=("missing name field in $toml_file")
        dk_error "no name field in $toml_file"
        return 1
    fi
    
    if [[ -z "$type" || "$type" == "null" ]]; then
        _DK_TOML_ERRORS+=("missing type field in $toml_file")
        dk_error "no type field in $toml_file"
        return 1
    fi
    
    # warn about unknown types but don't fail
    if [[ ! "$type" =~ ^(module|dotfile|profile)$ ]]; then
        _DK_TOML_WARNINGS+=("unknown type '$type' in $toml_file")
        dk_warn "weird type '$type' in $toml_file - expected module, dotfile, or profile"
    fi
    
    # store all the data as one string - easy to parse later
    _DK_TOML_DATA["$toml_file"]="name=$name|version=$version|description=$description|type=$type|files=$files|events=$events"
    
    dk_debug "loaded toml data for $toml_file: $name ($type)"
    return 0
}

# parallel processing helper function for large file counts
dk_toml_read_file_parallel() {
    local toml_file="$1"
    
    # single yq call gets everything at once - this is the fast approach
    local result
    # shellcheck disable=SC2016
    result=$(yq -p toml -o tsv '{
        "name": .name,
        "version": .version // "null",
        "description": .description // "null", 
        "type": .type,
        "files": (.files // {} | to_entries | map(.key + "|" + .value) | join(";")),
        "events": (.events // {} | to_entries | map(.key as $type | .value | to_entries | map($type + "|" + .key + "=" + .value)) | flatten | join(";"))
    } | [.name, .version, .description, .type, .files, .events] | @tsv' "$toml_file" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$result" ]]; then
        echo "ERROR:$toml_file:invalid toml syntax"
        return 1
    fi
    
    # parse the tab-separated result
    local name version description type files events
    IFS=$'\t' read -r name version description type files events <<< "$result"
    
    # check required fields
    if [[ -z "$name" || "$name" == "null" ]]; then
        echo "ERROR:$toml_file:missing name field"
        return 1
    fi
    
    if [[ -z "$type" || "$type" == "null" ]]; then
        echo "ERROR:$toml_file:missing type field"
        return 1
    fi
    
    # warn about unknown types but don't fail
    if [[ ! "$type" =~ ^(module|dotfile|profile)$ ]]; then
        echo "WARNING:$toml_file:unknown type '$type'"
    fi
    
    # output structured result for parent process to parse
    echo "SUCCESS:$toml_file:name=$name|version=$version|description=$description|type=$type|files=$files|events=$events"
    return 0
}

# parallel processing implementation for large file counts
dk_toml_load_all_parallel() {
    local toml_files=("$@")
    
    dk_debug "processing ${#toml_files[@]} files in parallel"
    
    # export the function so parallel can use it
    export -f dk_toml_read_file_parallel
    
    # process files in parallel and collect results
    local parallel_results
    parallel_results=$(printf '%s\n' "${toml_files[@]}" | parallel -j+0 dk_toml_read_file_parallel)
    
    # parse parallel results
    local line
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        local status toml_file data
        IFS=':' read -r status toml_file data <<< "$line"
        
        case "$status" in
            "SUCCESS")
                # store extracted data directly
                _DK_TOML_DATA["$toml_file"]="$data"
                dk_debug "parallel extraction completed for $toml_file"
                ;;
            "ERROR")
                _DK_TOML_ERRORS+=("$data in $toml_file")
                dk_error "$data in $toml_file"
                ;;
            "WARNING")
                _DK_TOML_WARNINGS+=("$data in $toml_file")
                dk_warn "$data in $toml_file"
                ;;
        esac
    done <<< "$parallel_results"
}

# load all discovered toml files into memory
# this is the main function - call this once, then use accessors
dk_toml_load_all() {
    dk_debug "loading all toml files"
    
    # clear previous data
    _DK_TOML_DATA=()
    _DK_TOML_ERRORS=()
    _DK_TOML_WARNINGS=()
    _DK_TOML_ALL_FILES=()
    
    # find all files first
    local -a toml_files
    mapfile -t toml_files < <(dk_toml_find_all)
    
    # ensure the global array is set correctly after discovery
    _DK_TOML_ALL_FILES=("${toml_files[@]}")
    
    if [[ ${#toml_files[@]} -eq 0 ]]; then
        dk_debug "no toml files to load"
        return 0
    fi
    
    # choose processing method based on file count and parallel availability
    if [[ ${#toml_files[@]} -ge 10 ]] && command -v parallel >/dev/null 2>&1; then
        dk_debug "using parallel processing for ${#toml_files[@]} files"
        dk_toml_load_all_parallel "${toml_files[@]}"
    else
        dk_debug "using sequential processing for ${#toml_files[@]} files"
        # read each file sequentially
        local toml_file
        for toml_file in "${toml_files[@]}"; do
            dk_toml_read_file "$toml_file"
        done
    fi
    
    # report any errors
    if [[ ${#_DK_TOML_ERRORS[@]} -gt 0 ]]; then
        dk_toml_report_errors
        return 1
    fi
    
    # show warnings but don't fail
    if [[ ${#_DK_TOML_WARNINGS[@]} -gt 0 ]]; then
        dk_toml_report_warnings
    fi
    
    dk_debug "loaded ${#_DK_TOML_DATA[@]} toml files successfully"
    return 0
}

# validate a single toml file without loading it
# useful for quick checks
dk_toml_validate() {
    local toml_file="$1"
    
    if [[ ! -f "$toml_file" ]]; then
        dk_error "toml file not found: $toml_file"
        return 1
    fi
    
    # quick syntax check
    if ! yq -p toml '.name' "$toml_file" >/dev/null 2>&1; then
        dk_error "bad toml syntax in $toml_file"
        return 1
    fi
    
    # check required fields
    local name type
    name=$(yq -p toml '.name' "$toml_file" 2>/dev/null)
    type=$(yq -p toml '.type' "$toml_file" 2>/dev/null)
    
    if [[ -z "$name" || "$name" == "null" ]]; then
        dk_error "missing name field in $toml_file"
        return 1
    fi
    
    if [[ -z "$type" || "$type" == "null" ]]; then
        dk_error "missing type field in $toml_file"
        return 1
    fi
    
    dk_debug "toml validation passed for $toml_file"
    return 0
}

# get the name from a loaded toml file
dk_toml_get_name() {
    local toml_file="$1"
    local data="${_DK_TOML_DATA[$toml_file]:-}"
    
    if [[ -z "$data" ]]; then
        dk_debug "no data for $toml_file"
        return 1
    fi
    
    # extract name from the stored data
    echo "$data" | grep -o 'name=[^|]*' | cut -d= -f2
}

# get the type from a loaded toml file
dk_toml_get_type() {
    local toml_file="$1"
    local data="${_DK_TOML_DATA[$toml_file]:-}"
    
    if [[ -z "$data" ]]; then
        dk_debug "no data for $toml_file"
        return 1
    fi
    
    echo "$data" | grep -o 'type=[^|]*' | cut -d= -f2
}

# get all metadata for a file as key=value pairs
dk_toml_get_metadata() {
    local toml_file="$1"
    
    # check cache first
    if [[ -n "${_DK_TOML_CACHE_METADATA[$toml_file]:-}" ]]; then
        echo "${_DK_TOML_CACHE_METADATA[$toml_file]}"
        return 0
    fi
    
    local data="${_DK_TOML_DATA[$toml_file]:-}"
    
    if [[ -z "$data" ]]; then
        dk_debug "no metadata for $toml_file"
        return 1
    fi
    
    # extract just the metadata parts (name, version, description, type)
    local result
    result=$(echo "$data" | grep -o -E '(name|version|description|type)=[^|]*' | tr '\n' '|' | sed 's/|$//')
    
    # cache the result
    _DK_TOML_CACHE_METADATA["$toml_file"]="$result"
    echo "$result"
}

# get file mappings from a loaded toml file
dk_toml_get_files() {
    local toml_file="$1"
    
    # check cache first
    if [[ -n "${_DK_TOML_CACHE_FILES[$toml_file]:-}" ]]; then
        echo "${_DK_TOML_CACHE_FILES[$toml_file]}"
        return 0
    fi
    
    local data="${_DK_TOML_DATA[$toml_file]:-}"
    
    if [[ -z "$data" ]]; then
        dk_debug "no data for $toml_file"
        return 1
    fi
    
    # extract files section using bash parameter expansion - much faster than sed
    local files_data="${data#*files=}"
    files_data="${files_data%%|events=*}"
    
    if [[ -n "$files_data" && "$files_data" != "null" && "$files_data" != "" ]]; then
        local result
        result=$(echo "$files_data" | tr ';' '\n')
        # cache the result
        _DK_TOML_CACHE_FILES["$toml_file"]="$result"
        echo "$result"
        return 0
    else
        dk_debug "no file mappings in $toml_file"
        return 1
    fi
}

# get events from a loaded toml file
dk_toml_get_events() {
    local toml_file="$1"
    
    # check cache first
    if [[ -n "${_DK_TOML_CACHE_EVENTS[$toml_file]:-}" ]]; then
        echo "${_DK_TOML_CACHE_EVENTS[$toml_file]}"
        return 0
    fi
    
    local data="${_DK_TOML_DATA[$toml_file]:-}"
    
    if [[ -z "$data" ]]; then
        dk_debug "no data for $toml_file"
        return 1
    fi
    
    # extract events section using bash parameter expansion - much faster than sed
    local events_data="${data#*|events=}"
    
    if [[ -n "$events_data" && "$events_data" != "null" && "$events_data" != "" ]]; then
        local result
        result=$(echo "$events_data" | tr ';' '\n')
        # cache the result
        _DK_TOML_CACHE_EVENTS["$toml_file"]="$result"
        echo "$result"
        return 0
    else
        dk_debug "no events in $toml_file"
        return 1
    fi
}

# get events of a specific type from all loaded files
dk_toml_get_events_by_type() {
    local event_type="$1"
    local toml_file data events_data
    
    for toml_file in "${!_DK_TOML_DATA[@]}"; do
        data="${_DK_TOML_DATA[$toml_file]}"
        events_data="${data#*|events=}"
        
        # check if this file has events of the specified type
        if [[ -n "$events_data" && "$events_data" != "null" ]]; then
            if echo "$events_data" | tr ';' '\n' | grep -q "^$event_type|"; then
                echo "$toml_file|$event_type"
            fi
        fi
    done
}

# get all metadata from all loaded files
dk_toml_get_all_metadata() {
    local toml_file data
    
    for toml_file in "${!_DK_TOML_DATA[@]}"; do
        data="${_DK_TOML_DATA[$toml_file]}"
        # extract metadata and format it
        local metadata
        metadata=$(echo "$data" | grep -o -E '(name|version|description|type)=[^|]*' | tr '\n' '|' | sed 's/|$//')
        echo "$toml_file|$metadata"
    done
}

# get all file mappings from all loaded files
dk_toml_get_all_file_mappings() {
    local toml_file data files_data
    
    for toml_file in "${!_DK_TOML_DATA[@]}"; do
        data="${_DK_TOML_DATA[$toml_file]}"
        files_data="${data#*files=}"
        files_data="${files_data%%|events=*}"
        
        if [[ -n "$files_data" && "$files_data" != "null" ]]; then
            echo "$toml_file|$files_data"
        fi
    done
}

# list all discovered toml files
dk_toml_list_discovered_files() {
    printf '%s\n' "${_DK_TOML_ALL_FILES[@]}"
}

# count how many toml files we found
dk_toml_count_files() {
    echo "${#_DK_TOML_ALL_FILES[@]}"
}

# clear all cached data
dk_toml_clear_cache() {
    _DK_TOML_DATA=()
    _DK_TOML_ERRORS=()
    _DK_TOML_WARNINGS=()
    _DK_TOML_ALL_FILES=()
    _DK_TOML_CACHE_METADATA=()
    _DK_TOML_CACHE_FILES=()
    _DK_TOML_CACHE_EVENTS=()
    dk_debug "toml cache cleared"
}

# show collected errors
dk_toml_report_errors() {
    if [[ ${#_DK_TOML_ERRORS[@]} -gt 0 ]]; then
        dk_error_list "toml processing errors" "${_DK_TOML_ERRORS[@]}"
    fi
}

# show collected warnings
dk_toml_report_warnings() {
    if [[ ${#_DK_TOML_WARNINGS[@]} -gt 0 ]]; then
        dk_warn_list "toml processing warnings" "${_DK_TOML_WARNINGS[@]}"
    fi
}
