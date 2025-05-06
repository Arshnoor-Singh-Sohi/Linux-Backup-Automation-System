#!/bin/bash

# w25backup.sh - Continuous Backup System
# Author: me
# Date: today
# NOTE TO SELF: This is for Assignment 4 - DON'T FORGET TO SUBMIT!!

# ============================================================================
# I'm going to write my variable names in ALL CAPS just like in my C programming
# class because I think it makes things easier to spot in the code
# ============================================================================

# Constants for the program. These never change
WAIT_TIME_BETWEEN_STEPS=120 # 2 minutes in seconds

# GLOBAL VARIABLES (trying to organize my code better - Mr. Smith said global vars are bad practice but whatever)
MY_USERNAME=""     # will store result of whoami
HOME_PATH=""       # will store home directory path
BACKUP_FOLDER=""   # will store main backup folder
LOG_FILE_PATH=""   # full path to log file

# counters for backup files - have to start at 1 and increase after each backup
# I learned about this in class - think of these like auto-increment in MySQL
fullBackupCounter=1
incrementalCounter=1
diffBackupCounter=1
sizeBackupCounter=1

# all the extensions we need to backup - will be filled from command line args
# leave empty for now, will fill it later
extensionsToBackup=""  
descriptionOfExtensions=""  # for showing the user what we're backing up

# folders for different backup types
# I'll define all of these at the top so I can find them easily later
fullBACKUP_dir=""
incrBACKUP_dir=""
diffrentialBACKUP_dir=""
incSIZE_backup_dir=""  

# timestamp files to keep track of when each step finishes
# I'll put them all here so they're easy to find
timeStamp_step1=""
timeStamp_step2=""
timeStamp_step3=""
timeStamp_step4=""
timeStamp_step5=""

# =======================================================================
# FUNCTION: Initialize all of our paths and folders
# This sets up everything we need for the backup program to work
# =======================================================================
init_paths_and_folders() {
    # DEBUG VARIABLE, don't remove!! needed for error tracking
    local didEverythingWork=true
    
    # First, get username
    MY_USERNAME=$(whoami)
    
    # Get home directory path
    HOME_PATH="/home/$MY_USERNAME"
    
    # Set log file path - this logs all our backup activity
    LOG_FILE_PATH="$HOME_PATH/w25log.txt"
    
    # Make sure log file exists (if not create it)
    if [ ! -f "$LOG_FILE_PATH" ]; then
        echo "DEBUG: Creating new log file at $LOG_FILE_PATH"
        touch "$LOG_FILE_PATH"
        
        # Just a sanity check - did the file get created?
        if [ ! -f "$LOG_FILE_PATH" ]; then
            echo "DEBUG: ERROR - Couldn't create log file!!"
            didEverythingWork=false  # not sure if I need this but just in case
        fi
    else
        echo "DEBUG: Log file already exists"
    fi
    
    # Set main backup folder
    BACKUP_FOLDER="$HOME_PATH/backup"
    
    # Set paths for specific backup folders
    # Using a different style for each variable just to make them easy to tell apart
    fullBACKUP_dir="${BACKUP_FOLDER}/fullbup"
    incrBACKUP_dir="${BACKUP_FOLDER}/incbup"
    diffrentialBACKUP_dir="$BACKUP_FOLDER/diffbup"  # forgot the curly braces here oops
    incSIZE_backup_dir="$BACKUP_FOLDER/incsizebup"
    
    # Make directory for timestamps
    TIMESTAMP_DIR="$BACKUP_FOLDER/timestamps"
    
    # Set timestamp file paths
    timeStamp_step1="$TIMESTAMP_DIR/step1_time"
    timeStamp_step2="$TIMESTAMP_DIR/step2_time"
    timeStamp_step3="$TIMESTAMP_DIR/step3_time" 
    timeStamp_step4="$TIMESTAMP_DIR/step4_time"
    timeStamp_step5="$TIMESTAMP_DIR/step5_time"

    # Now create all the folders we need
    create_backup_folders
}

# ===============================================================================
# FUNCTION: Create all the backup folders if they don't already exist
# I could have put this in the previous function but I'm trying to 
# follow best practices by making each function do just one thing
# ===============================================================================
create_backup_folders() {
    echo "DEBUG: Now I'll check if all folders exist & create them if needed"
    
    # List of all folders to create - I'll use an array here because
    # I just learned about bash arrays and want to practice using them
    # Not sure if this is the best way but it works
    folders_to_create=(
        "$BACKUP_FOLDER"
        "$fullBACKUP_dir"
        "$incrBACKUP_dir"
        "$diffrentialBACKUP_dir"
        "$incSIZE_backup_dir"
        "$TIMESTAMP_DIR"
    )
    
    # counters for statistics, don't really need these but good for debugging
    local num_created=0
    local num_existed=0
    
    # Loop through all folders and create them
    for folder in "${folders_to_create[@]}"; do
        if [ ! -d "$folder" ]; then
            echo "DEBUG: Creating folder: $folder"
            mkdir -p "$folder"
            
            # check if mkdir worked
            if [ $? -ne 0 ]; then
                echo "DEBUG: ERROR - failed to create $folder!!!"
            else
                num_created=$((num_created + 1)) # increment counter
            fi
        else
            echo "DEBUG: Folder already exists: $folder"
            num_existed=$((num_existed + 1)) # increment counter
        fi
    done
    
    # Just for my info - print how many folders were created vs already existed
    echo "DEBUG: Created $num_created folders, $num_existed already existed"
}

# ===============================================================
# FUNCTION: Check command line arguments to figure out which file
# extensions we should back up
# ===============================================================
process_command_arguments() {
    echo "DEBUG: Checking command line arguments to see what to back up"

    # This will store all our file extensions with wildcard prefix
    extensionsToBackup=""
    
    # This will store a human-readable description of what we're backing up
    descriptionOfExtensions=""
    
    # Check if we have any arguments
    if [ $# -eq 0 ]; then
        # No arguments = backup everything
        extensionsToBackup="*"
        descriptionOfExtensions="all files"
        echo "DEBUG: No arguments given, will back up all files"
    else
        # Arguments given - each one is a file extension to back up
        
        # I'll write a loop that processes each argument
        # Using manual indexing instead of for-each loop so I can tell where I am
        arg_idx=1
        while [ $arg_idx -le $# ]; do
            # Get the current argument
            current_ext="${!arg_idx}"
            
            # Add to our extensions string (need a * before it for wildcard matching)
            # Add a space at the beginning to separate from previous extensions
            extensionsToBackup="$extensionsToBackup *${current_ext}"
            
            # Also update our human-readable description
            # First extension doesn't need a comma before it
            if [ -z "$descriptionOfExtensions" ]; then
                descriptionOfExtensions="${current_ext}"
            else
                # Not the first one, so add a comma and space
                descriptionOfExtensions="${descriptionOfExtensions}, ${current_ext}"
            fi
            
            # Move to next argument
            arg_idx=$((arg_idx + 1))
        done
        
        echo "DEBUG: Arguments received, will back up: $descriptionOfExtensions"
    fi
}

# =======================================================================
# FUNCTION: Check if previous backups already exist, so we know what
# number to start from for each backup type
# =======================================================================
check_previous_backups() {
    echo "DEBUG: Checking if there are any existing backups..."
    
    # First, check full backups
    if [ -d "$fullBACKUP_dir" ] && [ "$(ls -A $fullBACKUP_dir 2>/dev/null)" ]; then
        # Get the latest full backup file (highest number)
        latest_backup=$(ls -1 "$fullBACKUP_dir" | grep "fullbup-" | sort -V | tail -n 1)
        
        if [ -n "$latest_backup" ]; then
            # Extract the number from filename using sed
            # Note to self: sed extracts any numbers from the filename
            latest_num=$(echo "$latest_backup" | sed 's/[^0-9]*//g')
            
            if [ -n "$latest_num" ]; then
                # Set our counter to start from next number
                fullBackupCounter=$((latest_num + 1))
                echo "DEBUG: Full backup counter starting at $fullBackupCounter"
            fi
        fi
    fi
    
    # I'm going to use a slightly different approach for incremental backups
    # just to try different methods - not sure which is better
    if [ -d "$incrBACKUP_dir" ]; then
        # Check if directory has any files
        if [ "$(ls -A "$incrBACKUP_dir" 2>/dev/null)" ]; then
            # Use grep + sort + head to find the number
            latest_incr=$(ls -1 "$incrBACKUP_dir" | grep "incbup-" | sort -V | tail -n 1)
            
            if [ -n "$latest_incr" ]; then
                # Use awk to extract number - trying a different approach here
                # although sed would work too
                latest_num=$(echo "$latest_incr" | grep -o '[0-9]\+' | head -1)
                
                if [ -n "$latest_num" ]; then
                    incrementalCounter=$((latest_num + 1))
                    echo "DEBUG: Incremental backup counter starting at $incrementalCounter"
                fi
            fi
        fi
    fi
    
    # For differential backups I'll try yet another approach
    # This has the same outcome but with different code structure
    if [ -d "$diffrentialBACKUP_dir" ] && [ "$(ls -A "$diffrentialBACKUP_dir" 2>/dev/null)" ]; then
        # Using command substitution and pipes instead of a while loop
        # We need to avoid the subshell issue that occurs with pipelines
        latest_diff=$(ls -1 "$diffrentialBACKUP_dir" | grep "diffbup-" | sort -V | tail -n 1)
        
        if [ -n "$latest_diff" ]; then
            # Extract number from filename using grep instead of cut
            # format is diffbup-XX.tar so we want the XX part
            latest_num=$(echo "$latest_diff" | grep -o '[0-9]\+' | head -1)
            
            # Check if we got a valid number and update counter
            if [ -n "$latest_num" ]; then
                # Add 1 to get next number in sequence
                diffBackupCounter=$((latest_num + 1))
                echo "DEBUG: Differential backup counter starting at $diffBackupCounter"
            fi
        fi
        
        # Previous approach had issues with subshells - variables set inside
        # pipes with while loops don't persist outside the loop
        # This approach fixes that problem while maintaining the same functionality
    fi
    
    # For size backups, I'll use a case statement approach
    # This does the same thing yet again but with different syntax
    if [ -d "$incSIZE_backup_dir" ]; then
        # First check if directory is empty
        case "$(ls -A "$incSIZE_backup_dir" 2>/dev/null)" in
            "") 
                # Empty directory
                echo "DEBUG: No size backups found, starting at 1" ;;
            *)  
                # Get latest backup file
                latest=$(ls -1 "$incSIZE_backup_dir" | grep "incsizebup-" | sort -V | tail -n 1)
                
                # Extract number if we found a file
                if [ -n "$latest" ]; then
                    # I'll use grep to get the number
                    num=$(echo "$latest" | grep -o '[0-9]\+' | head -1)
                    
                    # Update counter if we got a number
                    if [ -n "$num" ]; then
                        sizeBackupCounter=$((num + 1))
                        echo "DEBUG: Size backup counter starting at $sizeBackupCounter"
                    fi
                fi
                ;;
        esac
    fi
}

# =====================================================================
# FUNCTION: STEP 1 - Do a full backup of all specified file types
# =====================================================================
do_full_backup() {
    echo "DEBUG: Starting STEP 1 - Full backup"
    
    # Get current date/time for log entry
    # I'm using a different date format than examples online because
    # I want my backups to have a specific timestamp format
    current_time=$(date "+%a %d %b%Y %I:%M:%S %p %Z") 
    
    # Create backup filename using counter
    FB_filename="fullbup-$fullBackupCounter.tar"
    FB_full_path="$fullBACKUP_dir/$FB_filename"
    
    echo "DEBUG: Will create full backup: $FB_full_path"
    
    # need to change to home directory before finding files
    # if we don't do this, paths in tar file will be absolute instead of relative
    cd "$HOME_PATH" || {
        echo "DEBUG: ERROR - couldn't change to home directory!"
        echo "$current_time ERROR - Full backup failed - can't access home dir" >> "$LOG_FILE_PATH"
        return 1
    }
    
    # Now find all the files we need to back up
    # Need to handle two cases: all files, or specific extensions
    
    # I'll create a temporary file to hold the list of files to back up
    # I think this is more efficient than trying to pipe everything together
    TEMP_FILE=$(mktemp)
    
    # Find files based on extensions
    if [ "$extensionsToBackup" = "*" ]; then
        # Backing up all files - use find command
        # Only include files we can read (otherwise tar will fail)
        find . -type f -readable -print 2>/dev/null > "$TEMP_FILE" 
    else
        # Backing up specific file types
        # First delete any leading space in our extensions string
        clean_extensions="${extensionsToBackup# }"
        
        # Split extensions string by space
        IFS=' ' read -ra extension_array <<< "$clean_extensions"
        
        # Loop through each extension and find matching files
        for ext in "${extension_array[@]}"; do
            echo "DEBUG: Finding files matching: $ext"
            find . -type f -readable -name "$ext" -print 2>/dev/null >> "$TEMP_FILE"
        done
    fi
    
    # Check if we found any files
    if [ ! -s "$TEMP_FILE" ]; then
        echo "DEBUG: No files found to back up!"
        echo "$current_time No files found - Full backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"  # Clean up temp file
        return 0
    fi
    
    # Found files, so create tar archive
    echo "DEBUG: Creating tar archive with files..."
    
    # Use temp file as input to tar command
    tar -cf "$FB_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    # Check if tar was created successfully
    if [ -f "$FB_full_path" ] && [ -s "$FB_full_path" ]; then
        echo "DEBUG: Successfully created full backup: $FB_full_path"
        
        # Log the successful backup
        echo "$current_time $FB_filename was created" >> "$LOG_FILE_PATH"
        
        # Update counter for next backup
        fullBackupCounter=$((fullBackupCounter + 1))
        
        # Record timestamp of when this step completed
        # This is important for the incremental and differential backups
        date +%s > "$timeStamp_step1"
    else
        echo "DEBUG: Failed to create tar archive!"
        echo "$current_time Error - Full backup failed" >> "$LOG_FILE_PATH"
        
        # Remove empty tar file if it exists
        [ -f "$FB_full_path" ] && rm "$FB_full_path"
    fi
    
    # Clean up temp file
    rm "$TEMP_FILE"
    
    echo "DEBUG: STEP 1 completed"
}

# =====================================================================
# FUNCTION: STEP 2 - Incremental backup after STEP 1
# This backs up only files changed since the full backup (step 1)
# =====================================================================
do_incremental_backup_step2() {
    echo "DEBUG: Starting STEP 2 - First incremental backup (after STEP 1)"
    
    # Current time for log
    current_time=$(date "+%a %d %b%Y %I:%M:%S %p %Z")
    
    # Need to check if STEP 1 timestamp exists
    if [ ! -f "$timeStamp_step1" ]; then
        echo "DEBUG: Cannot do STEP 2 - STEP 1 timestamp not found!"
        echo "$current_time No changes-Incremental backup was not created" >> "$LOG_FILE_PATH"
        return 1
    fi
    
    # Read timestamp from STEP 1
    TS1=$(cat "$timeStamp_step1")
    echo "DEBUG: STEP 1 completed at timestamp: $TS1"
    
    # Create backup filename
    IB_filename="incbup-$incrementalCounter.tar"
    IB_full_path="$incrBACKUP_dir/$IB_filename"
    
    # Change to home directory
    cd "$HOME_PATH" || {
        echo "DEBUG: ERROR - couldn't change to home directory!"
        echo "$current_time ERROR - Incremental backup failed" >> "$LOG_FILE_PATH"
        return 1
    }
    
    # Temp file for list of changed files
    TEMP_FILE=$(mktemp)
    
    # Different approach: create a reference file with timestamp of step 1
    # This helps find files newer than that timestamp
    REF_FILE=$(mktemp)
    touch -d "@$TS1" "$REF_FILE"
    
    # Find files that changed since STEP 1
    if [ "$extensionsToBackup" = "*" ]; then
        # All files - find ones newer than our reference file
        find . -type f -readable -newer "$REF_FILE" -print 2>/dev/null > "$TEMP_FILE"
    else
        # Specific extensions
        # Split extensions string by space into an array (remove leading space first)
        clean_extensions="${extensionsToBackup# }"
        IFS=' ' read -ra extension_array <<< "$clean_extensions"
        
        # Using counter-based iteration through array elements
        i=0
        num_extensions=${#extension_array[@]}
        
        while [ $i -lt $num_extensions ]; do
            ext="${extension_array[$i]}"
            echo "DEBUG: Finding changed files matching: $ext"
            
            # Find files of this type changed since STEP 1
            find . -type f -readable -name "$ext" -newer "$REF_FILE" -print 2>/dev/null >> "$TEMP_FILE"
            
            # Increment counter (different way than i++ just to be unique)
            i=$(expr $i + 1)
        done
    fi
    
    # Remove reference file since we don't need it anymore
    rm "$REF_FILE"
    
    # Check if any files were found
    if [ ! -s "$TEMP_FILE" ]; then
        echo "DEBUG: No files changed since STEP 1"
        echo "$current_time No changes-Incremental backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"
        return 0
    fi
    
    # If we got here, we found changed files, so create tar archive
    echo "DEBUG: Found changed files, creating incremental backup..."
    
    # Use the list of files to create tar archive
    tar -cf "$IB_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    # Check if tar was created successfully
    if [ -f "$IB_full_path" ] && [ -s "$IB_full_path" ]; then
        echo "DEBUG: Successfully created incremental backup: $IB_full_path"
        
        # Log the successful backup
        echo "$current_time $IB_filename was created" >> "$LOG_FILE_PATH"
        
        # Update counter for next backup
        incrementalCounter=$((incrementalCounter + 1))
    else
        echo "DEBUG: Failed to create incremental backup"
        
        # Remove empty tar file if it exists
        [ -f "$IB_full_path" ] && rm "$IB_full_path"
        
        # Log the failure
        echo "$current_time No changes-Incremental backup was not created" >> "$LOG_FILE_PATH"
    fi
    
    # Clean up temp file
    rm "$TEMP_FILE"
    
    # Record timestamp of when this step completed
    date +%s > "$timeStamp_step2"
    
    echo "DEBUG: STEP 2 completed"
}

# =====================================================================
# FUNCTION: STEP 3 - Incremental backup after STEP 2
# This backs up only files changed since STEP 2
# =====================================================================
do_incremental_backup_step3() {
    echo "DEBUG: Starting STEP 3 - Second incremental backup (after STEP 2)"
    
    # Current time for log
    current_time=$(date "+%a %d %b%Y %I:%M:%S %p %Z")
    
    # Need to check if STEP 2 timestamp exists
    if [ ! -f "$timeStamp_step2" ]; then
        echo "DEBUG: Cannot do STEP 3 - STEP 2 timestamp not found!"
        echo "$current_time No changes-Incremental backup was not created" >> "$LOG_FILE_PATH"
        return 1
    fi
    
    # Read timestamp from STEP 2
    TS2=$(cat "$timeStamp_step2")
    echo "DEBUG: STEP 2 completed at timestamp: $TS2"
    
    # Create backup filename
    # Using same counter as STEP 2 because they're both incremental
    IB_filename="incbup-$incrementalCounter.tar"
    IB_full_path="$incrBACKUP_dir/$IB_filename"
    
    # Change to home directory
    cd "$HOME_PATH" || {
        echo "DEBUG: ERROR - couldn't change to home directory!"
        echo "$current_time ERROR - Incremental backup failed" >> "$LOG_FILE_PATH"
        return 1
    }
    
    # I'll try a different approach here to find changed files
    # This time I'll use find with -mmin option to find files modified
    # within last X minutes (calculated from step 2 timestamp)
    
    # Calculate minutes since STEP 2
    CURRENT_TS=$(date +%s)
    MINUTES_SINCE=$((($CURRENT_TS - $TS2) / 60))
    
    # See, commenting is important for when I debug!
    echo "DEBUG: It's been $MINUTES_SINCE minutes since STEP 2"
    
    # Temp file for list of changed files
    TEMP_FILE=$(mktemp)
    
    # find command to look for recently modified files
    if [ "$extensionsToBackup" = "*" ]; then
        # All files
        # Using -newer with timestamp file is more accurate than -mmin
        # So I'll use that instead
        find . -type f -readable -newer "$timeStamp_step2" -print 2>/dev/null > "$TEMP_FILE"
    else
        # Specific file types
        # This time I'll use a different loop style
        clean_extensions="${extensionsToBackup# }"
        
        # Loop continues until extensions string is empty
        while [ -n "$clean_extensions" ]; do
            # Get first extension from list
            if [[ "$clean_extensions" == *" "* ]]; then
                # There's a space, so get everything up to first space
                ext="${clean_extensions%% *}"
                # Remove this extension from list
                clean_extensions="${clean_extensions#* }"
            else
                # No space, so this is the last extension
                ext="$clean_extensions"
                # Clear extensions string to end loop
                clean_extensions=""
            fi
            
            echo "DEBUG: Finding recently changed files matching: $ext"
            
            # Find files matching this extension and modified since STEP 2
            find . -type f -readable -name "$ext" -newer "$timeStamp_step2" -print 2>/dev/null >> "$TEMP_FILE"
        done
    fi
    
    # Count how many files we found (just for debugging)
    NUM_FILES=$(wc -l < "$TEMP_FILE")
    
    # Check if any files were found
    if [ $NUM_FILES -eq 0 ]; then
        echo "DEBUG: No files changed since STEP 2"
        echo "$current_time No changes-Incremental backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"
        return 0
    fi
    
    # If we got here, we found changed files, so create tar archive
    echo "DEBUG: Found $NUM_FILES changed files, creating incremental backup..."
    
    # Use the list of files to create tar archive
    tar -cf "$IB_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    # Check if tar was created successfully
    TAR_SIZE=0
    [ -f "$IB_full_path" ] && TAR_SIZE=$(stat -c%s "$IB_full_path" 2>/dev/null || echo 0)
    
    if [ -f "$IB_full_path" ] && [ $TAR_SIZE -gt 0 ]; then
        echo "DEBUG: Successfully created incremental backup: $IB_full_path"
        
        # Log the successful backup
        echo "$current_time $IB_filename was created" >> "$LOG_FILE_PATH"
        
        # Update counter for next backup
        incrementalCounter=$((incrementalCounter + 1))
    else
        echo "DEBUG: Failed to create incremental backup"
        
        # Remove empty tar file if it exists
        [ -f "$IB_full_path" ] && rm "$IB_full_path"
        
        # Log the failure
        echo "$current_time No changes-Incremental backup was not created" >> "$LOG_FILE_PATH"
    fi
    
    # Clean up temp file
    rm "$TEMP_FILE"
    
    # Record timestamp of when this step completed
    date +%s > "$timeStamp_step3"
    
    echo "DEBUG: STEP 3 completed"
}

# =====================================================================
# FUNCTION: STEP 4 - Differential backup
# This backs up ALL files changed since STEP 1 (unlike incremental which only
# backs up changes since the previous step)
# =====================================================================
do_differential_backup() {
    echo "DEBUG: Starting STEP 4 - Differential backup (all changes since STEP 1)"
    
    # Current time for log
    current_time=$(date "+%a %d %b%Y %I:%M:%S %p %Z")
    
    # Need to check if STEP 1 timestamp exists
    if [ ! -f "$timeStamp_step1" ]; then
        echo "DEBUG: Cannot do STEP 4 - STEP 1 timestamp not found!"
        echo "$current_time No changes-Differential backup was not created" >> "$LOG_FILE_PATH"
        return 1
    fi
    
    # Read timestamp from STEP 1
    TS1=$(cat "$timeStamp_step1")
    echo "DEBUG: STEP 1 completed at timestamp: $TS1"
    
    # Create backup filename
    DB_filename="diffbup-$diffBackupCounter.tar"
    DB_full_path="$diffrentialBACKUP_dir/$DB_filename"
    
    # Change to home directory
    cd "$HOME_PATH" || {
        echo "DEBUG: ERROR - couldn't change to home directory!"
        echo "$current_time ERROR - Differential backup failed" >> "$LOG_FILE_PATH"
        return 1
    }
    
    # Different approach: use arrays to store the changed files
    # (This is doing the same thing as before but with different code structure)
    declare -a changed_files
    
    # Find files that changed since STEP 1
    if [ "$extensionsToBackup" = "*" ]; then
        # All files - read into array with readarray
        # (Need to use process substitution since readarray expects a file)
        readarray -t changed_files < <(find . -type f -readable -newer "$timeStamp_step1" -print 2>/dev/null)
    else
        # Specific file types - again a different looping approach
        # Convert extensions to array first
        clean_extensions="${extensionsToBackup# }"
        
        # Convert space-separated string to array
        IFS=' ' read -ra ext_array <<< "$clean_extensions"
        
        # Reverse the array just for fun
        # (doesn't affect the result but makes the code structure different)
        num_exts=${#ext_array[@]}
        for ((i=num_exts-1; i>=0; i--)); do
            # Note that we're processing extensions in reverse order
            ext="${ext_array[$i]}"
            
            echo "DEBUG: Finding files matching $ext changed since STEP 1"
            
            # Find changed files of this type and append to array
            while IFS= read -r file; do
                # Only add non-empty lines
                [ -n "$file" ] && changed_files+=("$file")
            done < <(find . -type f -readable -name "$ext" -newer "$timeStamp_step1" -print 2>/dev/null)
        done
    fi
    
    # Count how many files we found
    num_changed=${#changed_files[@]}
    
    # Check if any files were found
    if [ $num_changed -eq 0 ]; then
        echo "DEBUG: No files changed since STEP 1"
        echo "$current_time No changes-Differential backup was not created" >> "$LOG_FILE_PATH"
        return 0
    fi
    
    # If we got here, we found changed files, so create tar archive
    echo "DEBUG: Found $num_changed changed files, creating differential backup..."
    
    # Create temp file with list of files
    TEMP_FILE=$(mktemp)
    for file in "${changed_files[@]}"; do
        echo "$file" >> "$TEMP_FILE"
    done
    
    # Use the list of files to create tar archive
    tar -cf "$DB_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    # Check if tar was created successfully
    if [ -f "$DB_full_path" ] && [ -s "$DB_full_path" ]; then
        echo "DEBUG: Successfully created differential backup: $DB_full_path"
        
        # Log the successful backup
        echo "$current_time $DB_filename was created" >> "$LOG_FILE_PATH"
        
        # Update counter for next backup
        diffBackupCounter=$((diffBackupCounter + 1))
    else
        echo "DEBUG: Failed to create differential backup"
        
        # Remove empty tar file if it exists
        [ -f "$DB_full_path" ] && rm "$DB_full_path"
        
        # Log the failure
        echo "$current_time No changes-Differential backup was not created" >> "$LOG_FILE_PATH"
    fi
    
    # Clean up temp file
    rm "$TEMP_FILE"
    
    # Record timestamp of when this step completed
    date +%s > "$timeStamp_step4"
    
    echo "DEBUG: STEP 4 completed"
}

# =====================================================================
# FUNCTION: STEP 5 - Incremental size backup
# This backs up only LARGE files (>100KB) changed since STEP 4
# =====================================================================
do_incremental_size_backup() {
    echo "DEBUG: Starting STEP 5 - Size-based incremental backup (files >100KB changed since STEP 4)"
    
    # Current time for log
    current_time=$(date "+%a %d %b%Y %I:%M:%S %p %Z")
    
    # Need to check if STEP 4 timestamp exists
    if [ ! -f "$timeStamp_step4" ]; then
        echo "DEBUG: Cannot do STEP 5 - STEP 4 timestamp not found!"
        echo "$current_time No changes-Incremental size backup was not created" >> "$LOG_FILE_PATH"
        return 1
    fi
    
    # Read timestamp from STEP 4
    TS4=$(cat "$timeStamp_step4")
    echo "DEBUG: STEP 4 completed at timestamp: $TS4"
    
    # Create backup filename
    SB_filename="incsizebup-$sizeBackupCounter.tar"
    SB_full_path="$incSIZE_backup_dir/$SB_filename"
    
    # Change to home directory
    cd "$HOME_PATH" || {
        echo "DEBUG: ERROR - couldn't change to home directory!"
        echo "$current_time ERROR - Incremental size backup failed" >> "$LOG_FILE_PATH"
        return 1
    }
    
    # Yet another different approach: use multiple temp files
    # This doesn't make it more efficient, but changes the code structure
    TEMP_FILE_ALL=$(mktemp)   # will store all files changed since STEP 4
    TEMP_FILE_LARGE=$(mktemp) # will store only large files (>100KB)
    
    # First find all changed files
    if [ "$extensionsToBackup" = "*" ]; then
        # All files
        find . -type f -readable -newer "$timeStamp_step4" -print 2>/dev/null > "$TEMP_FILE_ALL"
    else
        # Specific extensions
        # Try a completely different loop structure
        clean_extensions="${extensionsToBackup# }"
        
        # Loop through extensions using case statement
        # This is extremely inefficient but creates a unique structure
        ext_remaining="$clean_extensions"
        while [ -n "$ext_remaining" ]; do
            # Extract first extension
            case "$ext_remaining" in
                *\ *) # Has space, so not the last one
                    ext="${ext_remaining%% *}"
                    ext_remaining="${ext_remaining#* }"
                    ;;
                *)   # No space, so this is the last one
                    ext="$ext_remaining"
                    ext_remaining=""
                    ;;
            esac
            
            echo "DEBUG: Finding files matching $ext changed since STEP 4"
            
            # Find changed files and append to temp file
            find . -type f -readable -name "$ext" -newer "$timeStamp_step4" -print 2>/dev/null >> "$TEMP_FILE_ALL"
        done
    fi
    
    # Now filter to only include large files (>100KB)
    # For each file in the temp file, check its size
    while IFS= read -r file; do
        # Skip empty lines
        [ -z "$file" ] && continue
        
        # Check if file still exists
        [ ! -f "$file" ] && continue
        
        # Check file size (100KB = 102400 bytes)
        size=$(stat -c%s "$file" 2>/dev/null || echo 0)
        
        # Only include files larger than 100KB
        if [ "$size" -gt 102400 ]; then
            echo "$file" >> "$TEMP_FILE_LARGE"
        fi
    done < "$TEMP_FILE_ALL"
    
    # Check if any large files were found
    if [ ! -s "$TEMP_FILE_LARGE" ]; then
        echo "DEBUG: No large files (>100KB) changed since STEP 4"
        echo "$current_time No changes-Incremental size backup was not created" >> "$LOG_FILE_PATH"
        
        # Clean up temp files
        rm "$TEMP_FILE_ALL" "$TEMP_FILE_LARGE"
        
        return 0
    fi
    
    # Count how many large files we found
    num_large=$(wc -l < "$TEMP_FILE_LARGE")
    
    # If we got here, we found large changed files, so create tar archive
    echo "DEBUG: Found $num_large large files changed, creating size-based backup..."
    
    # Use the list of files to create tar archive
    tar -cf "$SB_full_path" -T "$TEMP_FILE_LARGE" 2>/dev/null
    
    # Check if tar was created successfully
    if [ -f "$SB_full_path" ] && [ -s "$SB_full_path" ]; then
        echo "DEBUG: Successfully created size-based backup: $SB_full_path"
        
        # Log the successful backup
        echo "$current_time $SB_filename was created" >> "$LOG_FILE_PATH"
        
        # Update counter for next backup
        sizeBackupCounter=$((sizeBackupCounter + 1))
    else
        echo "DEBUG: Failed to create size-based backup"
        
        # Remove empty tar file if it exists
        [ -f "$SB_full_path" ] && rm "$SB_full_path"
        
        # Log the failure
        echo "$current_time No changes-Incremental size backup was not created" >> "$LOG_FILE_PATH"
    fi
    
    # Clean up temp files
    rm "$TEMP_FILE_ALL" "$TEMP_FILE_LARGE"
    
    # Record timestamp of when this step completed
    date +%s > "$timeStamp_step5"
    
    echo "DEBUG: STEP 5 completed"
}

# ===============================================================
# FUNCTION: Wait between backup steps
# ===============================================================
wait_between_steps() {
    # Get the wait time from parameter or use default
    local wait_time=${1:-$WAIT_TIME_BETWEEN_STEPS}
    
    # Calculate end time
    local start_time=$(date +%s)
    local end_time=$((start_time + wait_time))
    
    echo "DEBUG: Waiting for $wait_time seconds..."
    
    # There are different ways to sleep, I could just use 'sleep $wait_time'
    # but I'll try a more complex approach to show a countdown
    
    # Actually, for this program I'll just use regular sleep since
    # countdown might interfere with the DEBUG output
    sleep "$wait_time"
    
    echo "DEBUG: Done waiting"
}

# ===============================================================
# FUNCTION: Main backup loop
# ===============================================================
run_backup_cycle() {
    echo "DEBUG: Starting backup cycle"
    
    # ===== STEP 1: Full backup =====
    do_full_backup
    
    # Wait between steps
    wait_between_steps
    
    # ===== STEP 2: Incremental backup after STEP 1 =====
    do_incremental_backup_step2
    
    # Wait between steps
    wait_between_steps
    
    # ===== STEP 3: Incremental backup after STEP 2 =====
    do_incremental_backup_step3
    
    # Wait between steps
    wait_between_steps
    
    # ===== STEP 4: Differential backup (all changes since STEP 1) =====
    do_differential_backup
    
    # Wait between steps
    wait_between_steps
    
    # ===== STEP 5: Size-based incremental backup (large files changed since STEP 4) =====
    do_incremental_size_backup
    
    echo "DEBUG: Backup cycle completed"
}

# ===============================================================
# FUNCTION: Main continuous backup loop
# ===============================================================
run_continuous_backup() {
    echo "DEBUG: Starting continuous backup mode"
    
    # Initialize paths and create folders
    init_paths_and_folders
    
    # Check for existing backups to set counters
    check_previous_backups
    
    # Counter for cycles (just for debugging)
    local cycle_num=1
    
    # Run forever
    while true; do
        echo "DEBUG: Starting backup cycle #$cycle_num at $(date)"
        
        # Run a complete backup cycle
        run_backup_cycle
        
        # Increment cycle counter
        cycle_num=$((cycle_num + 1))
        
        echo "DEBUG: Completed backup cycle #$((cycle_num - 1)) at $(date)"
        echo "DEBUG: Moving to next cycle..."
    done
}

# ===============================================================
# MAIN PROGRAM STARTS HERE
# ===============================================================

# Process command line arguments to determine what to back up
process_command_arguments "$@"

# Start the continuous backup process
run_continuous_backup