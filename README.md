# Linux Backup Automation System


[![Bash Version](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![OS](https://img.shields.io/badge/OS-Linux-orange.svg)](https://www.linux.org/)

## 📋 Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Features](#features)
- [Understanding Backup Types](#understanding-backup-types)
- [Installation](#installation)
- [Usage](#usage)
- [Workflow Details](#workflow-details)
- [Directory Structure](#directory-structure)
- [Code Explanation](#code-explanation)
- [Logging System](#logging-system)
- [Performance Considerations](#performance-considerations)
- [Limitations](#limitations)
- [Future Enhancements](#future-enhancements)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🔍 Overview

The Linux Backup Automation System is a comprehensive backup solution implemented as a bash script that automates the process of creating and managing multiple types of backups for specified file types in a Linux environment. This system continuously runs in the background, performing five different backup operations at regular intervals:

1. **Full Backup**: Creates a complete backup of all specified file types
2. **Incremental Backup (Step 2)**: Backs up only files modified since the full backup
3. **Incremental Backup (Step 3)**: Backs up only files modified since the previous incremental backup
4. **Differential Backup**: Backs up all files modified since the full backup
5. **Incremental Size Backup**: Backs up only large files (>100KB) modified since the differential backup

Each backup operation occurs at 2-minute intervals, creating a continuous automated backup system that provides multiple recovery points and optimizes storage usage through different backup strategies.

This project was developed as part of COMP 8567 (Advanced Systems Programming) to demonstrate proficiency in Linux shell scripting, file operations, and system programming concepts.

## 🏗️ System Architecture

The backup system follows a modular architecture with the following components:

```
                                 ┌─────────────────────┐
                                 │  Command Arguments  │
                                 │ (.c, .txt, .pdf...) │
                                 └──────────┬──────────┘
                                            │
                                            ▼
┌─────────────────────┐          ┌─────────────────────┐
│   Initialization    │◄─────────┤   Main Controller   │
│                     │          │                     │
│ - Path Setup        │          │ - Process Arguments │
│ - Folder Creation   │          │ - Continuous Loop   │
│ - Counter Management│          │ - Cycle Management  │
└─────────┬───────────┘          └─────────┬───────────┘
          │                                │
          │                                ▼
          │                      ┌─────────────────────┐
          │                      │   Backup Cycle      │
          │                      │                     │
          │                      │ - 5 Backup Steps    │
          │                      │ - Interval Waiting  │
          │                      └─────────┬───────────┘
          │                                │
          ▼                                ▼
┌─────────────────────┐          ┌─────────────────────┐
│  Support Functions  │          │   Backup Steps      │
│                     │          │                     │
│ - File Finding      │◄─────────┤ 1. Full Backup      │
│ - Tar Creation      │          │ 2. Incremental 1    │
│ - Timestamp Mgmt    │          │ 3. Incremental 2    │
│ - Logging           │          │ 4. Differential     │
└─────────────────────┘          │ 5. Size-Based       │
                                 └─────────────────────┘
```

## ✨ Features

- **Multiple Backup Types**: Implements full, incremental, differential, and size-based backups in a single system
- **Flexible File Selection**: Accepts up to 4 file extensions as command-line arguments
- **Sequential File Management**: Automatically numbers backup files in sequence
- **Detailed Logging**: Maintains a comprehensive log file tracking all backup activities
- **Continuous Operation**: Runs as a background process, continuously creating backups
- **Smart Resumption**: Can detect existing backups and continue sequence numbering
- **Timestamp Tracking**: Uses timestamps to precisely track file changes between backup stages
- **Optimization**: Efficiently targets only necessary files in incremental and differential backups
- **Size-Based Selection**: Includes special handling for large files (>100KB)

## 📚 Understanding Backup Types

The system implements several different backup strategies, each with its own advantages:

| Backup Type | Description | Advantages | Storage Usage | Recovery Speed |
|-------------|-------------|------------|---------------|----------------|
| **Full** | Complete backup of all specified files | Simple recovery, complete point-in-time snapshot | High | Fast |
| **Incremental** | Only files changed since the previous backup | Efficient storage, faster backups | Low | Slower (requires multiple backups) |
| **Differential** | All files changed since the last full backup | Balance of storage and recovery speed | Medium | Medium |
| **Size-Based** | Only large files (>100KB) that have changed | Prioritizes important data, saves space | Very Low | Fast for large files |

### Visual Representation of Backup Types

```
     ┌───────┐     ┌───────┐     ┌───────┐     ┌───────┐     ┌───────┐
     │Full   │     │Inc    │     │Inc    │     │Diff   │     │Inc    │
     │Backup │ ─►  │Backup │ ─►  │Backup │ ─►  │Backup │ ─►  │Size   │
     │(Step 1)│     │(Step 2)│     │(Step 3)│     │(Step 4)│     │(Step 5)│
     └───────┘     └───────┘     └───────┘     └───────┘     └───────┘
        │             │             │             │             │
        ▼             ▼             ▼             ▼             ▼
 ┌─────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐
 │ All files   │ │New/      │ │New/      │ │All       │ │New/modified  │
 │of specified │ │modified  │ │modified  │ │modified  │ │files >100KB  │
 │type         │ │since     │ │since     │ │since     │ │since Step 4  │
 │             │ │Step 1    │ │Step 2    │ │Step 1    │ │              │
 └─────────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────┘
```

## 🔧 Installation

### Prerequisites

- Linux operating system
- Bash shell (version 4.0 or higher)
- `tar` utility (typically pre-installed on most Linux distributions)
- Sufficient disk space for backups

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Arshnoor-Singh-Sohi/Linux-Backup-Automation-System.git
   cd Linux-Backup-Automation-System
   ```

2. Make the script executable:
   ```bash
   chmod +x w25backup.sh
   ```

3. Create a symbolic link to make the script accessible from anywhere (optional):
   ```bash
   sudo ln -s $(pwd)/w25backup.sh /usr/local/bin/w25backup
   ```

## 🚀 Usage

### Basic Usage

Run the script with file extensions as arguments:

```bash
./w25backup.sh .txt .pdf .jpg .c
```

This will back up all files with the specified extensions (.txt, .pdf, .jpg, .c) in your home directory.

### Backing Up All Files

Run the script without arguments to back up all files:

```bash
./w25backup.sh
```

### Running in Background

To run the script in the background:

```bash
./w25backup.sh .txt .pdf &
```

Or with nohup to keep it running after logout:

```bash
nohup ./w25backup.sh .txt .pdf &
```

### Terminating the Process

To terminate the script running in the background:

```bash
# Find the process ID
ps aux | grep w25backup.sh

# Kill the process
kill <PID>
```

## 🔄 Workflow Details

The system operates in a continuous loop with the following steps:

1. **Initialization**
   - Set up paths and variables
   - Create necessary directories
   - Check for existing backups to determine starting sequence numbers

2. **Process Command-Line Arguments**
   - Parse file extensions from command-line arguments
   - If no arguments are provided, set up to back up all files

3. **Backup Cycle**
   - **Step 1**: Full backup of all specified file types
   - Wait 2 minutes
   - **Step 2**: Incremental backup (files changed since Step 1)
   - Wait 2 minutes
   - **Step 3**: Incremental backup (files changed since Step 2)
   - Wait 2 minutes
   - **Step 4**: Differential backup (all files changed since Step 1)
   - Wait 2 minutes
   - **Step 5**: Size-based incremental backup (large files >100KB changed since Step 4)
   - Return to Step 1 and repeat indefinitely

4. **For Each Backup Step**
   - Find relevant files based on extension and modification time criteria
   - Create a tar archive of the files
   - Update the log file with timestamp and backup information
   - Update timestamp markers for tracking changes

### Backup Cycle Process Flow

```
           ┌──────────────────┐
           │  Initialize      │
           │  System          │
           └────────┬─────────┘
                    │
                    ▼
           ┌──────────────────┐
┌──────────┤  Start Backup    │◄─────────┐
│          │  Cycle           │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Step 1:         │          │
│          │  Full Backup     │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Wait 2 Minutes  │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Step 2:         │          │
│          │  Incremental 1   │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Wait 2 Minutes  │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Step 3:         │          │
│          │  Incremental 2   │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Wait 2 Minutes  │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Step 4:         │          │
│          │  Differential    │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Wait 2 Minutes  │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
│          │  Step 5:         │          │
│          │  Size Backup     │          │
│          └────────┬─────────┘          │
│                   │                    │
│                   ▼                    │
│          ┌──────────────────┐          │
└──────────┤  Return to       │          │
           │  Start           ├──────────┘
           └──────────────────┘
```

## 📁 Directory Structure

The system creates the following directory structure for organizing backups:

```
~/backup/
|
├── fullbup/              # Full backups
|   ├── fullbup-1.tar     # First full backup
|   ├── fullbup-2.tar     # Second full backup
|   └── ...
|
├── incbup/               # Incremental backups
|   ├── incbup-1.tar      # First incremental backup
|   ├── incbup-2.tar      # Second incremental backup
|   └── ...
|
├── diffbup/              # Differential backups
|   ├── diffbup-1.tar     # First differential backup
|   ├── diffbup-2.tar     # Second differential backup
|   └── ...
|
├── incsizebup/           # Size-based incremental backups
|   ├── incsizebup-1.tar  # First size-based backup
|   ├── incsizebup-2.tar  # Second size-based backup
|   └── ...
|
└── timestamps/           # Timestamp files for tracking changes
    ├── step1_time        # Timestamp when Step 1 completed
    ├── step2_time        # Timestamp when Step 2 completed
    ├── step3_time        # Timestamp when Step 3 completed
    ├── step4_time        # Timestamp when Step 4 completed
    └── step5_time        # Timestamp when Step 5 completed
```

Additionally, a log file is created at:

```
~/w25log.txt              # Log file recording all backup operations
```

## 💻 Code Explanation

The script (`w25backup.sh`) is structured into several key functions, each responsible for a specific aspect of the backup system:

### Global Variables and Constants

```bash
# Constants for the program. These never change
WAIT_TIME_BETWEEN_STEPS=120 # 2 minutes in seconds

# GLOBAL VARIABLES
MY_USERNAME=""     # will store result of whoami
HOME_PATH=""       # will store home directory path
BACKUP_FOLDER=""   # will store main backup folder
LOG_FILE_PATH=""   # full path to log file

# Counters for backup files
fullBackupCounter=1
incrementalCounter=1
diffBackupCounter=1
sizeBackupCounter=1

# Extensions to backup (filled from command line args)
extensionsToBackup=""  
descriptionOfExtensions=""  

# Folders for different backup types
fullBACKUP_dir=""
incrBACKUP_dir=""
diffrentialBACKUP_dir=""
incSIZE_backup_dir=""  

# Timestamp files
timeStamp_step1=""
timeStamp_step2=""
timeStamp_step3=""
timeStamp_step4=""
timeStamp_step5=""
```

The script uses multiple global variables to track:
- User information and paths
- Sequence counters for each backup type
- File extensions to back up
- Directory paths for different backup types
- Paths to timestamp files

### Initialization Functions

#### `init_paths_and_folders()`

This function sets up all necessary paths and ensures the log file exists:

```bash
init_paths_and_folders() {
    # Get username and set paths
    MY_USERNAME=$(whoami)
    HOME_PATH="/home/$MY_USERNAME"
    LOG_FILE_PATH="$HOME_PATH/w25log.txt"
    
    # Create log file if needed
    if [ ! -f "$LOG_FILE_PATH" ]; then
        touch "$LOG_FILE_PATH"
    fi
    
    # Set backup directory paths
    BACKUP_FOLDER="$HOME_PATH/backup"
    fullBACKUP_dir="${BACKUP_FOLDER}/fullbup"
    incrBACKUP_dir="${BACKUP_FOLDER}/incbup"
    diffrentialBACKUP_dir="$BACKUP_FOLDER/diffbup"
    incSIZE_backup_dir="$BACKUP_FOLDER/incsizebup"
    TIMESTAMP_DIR="$BACKUP_FOLDER/timestamps"
    
    # Set timestamp file paths
    timeStamp_step1="$TIMESTAMP_DIR/step1_time"
    timeStamp_step2="$TIMESTAMP_DIR/step2_time"
    timeStamp_step3="$TIMESTAMP_DIR/step3_time"
    timeStamp_step4="$TIMESTAMP_DIR/step4_time"
    timeStamp_step5="$TIMESTAMP_DIR/step5_time"

    # Create backup folders
    create_backup_folders
}
```

#### `create_backup_folders()`

This function creates all the necessary directories for storing backups:

```bash
create_backup_folders() {
    # List of folders to create
    folders_to_create=(
        "$BACKUP_FOLDER"
        "$fullBACKUP_dir"
        "$incrBACKUP_dir"
        "$diffrentialBACKUP_dir"
        "$incSIZE_backup_dir"
        "$TIMESTAMP_DIR"
    )
    
    # Create each folder if it doesn't exist
    for folder in "${folders_to_create[@]}"; do
        if [ ! -d "$folder" ]; then
            mkdir -p "$folder"
        fi
    done
}
```

### Command-Line Processing

#### `process_command_arguments()`

This function processes command-line arguments to determine which file extensions to back up:

```bash
process_command_arguments() {
    # Reset variables
    extensionsToBackup=""
    descriptionOfExtensions=""
    
    # Check if we have any arguments
    if [ $# -eq 0 ]; then
        # No arguments = backup everything
        extensionsToBackup="*"
        descriptionOfExtensions="all files"
    else
        # Process each argument (file extension)
        arg_idx=1
        while [ $arg_idx -le $# ]; do
            current_ext="${!arg_idx}"
            
            # Add to extensions string with wildcard
            extensionsToBackup="$extensionsToBackup *${current_ext}"
            
            # Add to human-readable description
            if [ -z "$descriptionOfExtensions" ]; then
                descriptionOfExtensions="${current_ext}"
            else
                descriptionOfExtensions="${descriptionOfExtensions}, ${current_ext}"
            fi
            
            arg_idx=$((arg_idx + 1))
        done
    fi
}
```

### Counter Management

#### `check_previous_backups()`

This function checks for existing backup files to determine the starting sequence numbers:

```bash
check_previous_backups() {
    # Check full backups
    if [ -d "$fullBACKUP_dir" ] && [ "$(ls -A $fullBACKUP_dir 2>/dev/null)" ]; then
        latest_backup=$(ls -1 "$fullBACKUP_dir" | grep "fullbup-" | sort -V | tail -n 1)
        if [ -n "$latest_backup" ]; then
            latest_num=$(echo "$latest_backup" | sed 's/[^0-9]*//g')
            if [ -n "$latest_num" ]; then
                fullBackupCounter=$((latest_num + 1))
            fi
        fi
    fi
    
    # Similar checks for incremental, differential, and size-based backups
    # [Code for checking other backup types omitted for brevity]
}
```

### Backup Functions

Each backup step has its own function responsible for creating the appropriate backup:

#### `do_full_backup()`

Creates a complete backup of all specified file types:

```bash
do_full_backup() {
    # Get current date/time
    current_time=$(date "+%a %d %b%Y %I:%M:%S %p %Z")
    
    # Create backup filename
    FB_filename="fullbup-$fullBackupCounter.tar"
    FB_full_path="$fullBACKUP_dir/$FB_filename"
    
    # Change to home directory
    cd "$HOME_PATH" || return 1
    
    # Create temp file for list of files
    TEMP_FILE=$(mktemp)
    
    # Find files based on extensions
    if [ "$extensionsToBackup" = "*" ]; then
        find . -type f -readable -print 2>/dev/null > "$TEMP_FILE"
    else
        # Process each extension
        clean_extensions="${extensionsToBackup# }"
        IFS=' ' read -ra extension_array <<< "$clean_extensions"
        for ext in "${extension_array[@]}"; do
            find . -type f -readable -name "$ext" -print 2>/dev/null >> "$TEMP_FILE"
        done
    fi
    
    # Check if any files found
    if [ ! -s "$TEMP_FILE" ]; then
        echo "$current_time No files found - Full backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"
        return 0
    fi
    
    # Create tar archive
    tar -cf "$FB_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    # Check if tar creation was successful
    if [ -f "$FB_full_path" ] && [ -s "$FB_full_path" ]; then
        # Log success
        echo "$current_time $FB_filename was created" >> "$LOG_FILE_PATH"
        # Update counter
        fullBackupCounter=$((fullBackupCounter + 1))
        # Record timestamp
        date +%s > "$timeStamp_step1"
    else
        # Log failure
        echo "$current_time Error - Full backup failed" >> "$LOG_FILE_PATH"
        [ -f "$FB_full_path" ] && rm "$FB_full_path"
    fi
    
    # Clean up
    rm "$TEMP_FILE"
}
```

#### Incremental, Differential, and Size-Based Backup Functions

The other backup functions follow a similar pattern but with different file selection criteria:

- `do_incremental_backup_step2()`: Backs up files modified since Step 1
- `do_incremental_backup_step3()`: Backs up files modified since Step 2
- `do_differential_backup()`: Backs up all files modified since Step 1
- `do_incremental_size_backup()`: Backs up large files (>100KB) modified since Step 4

Each function:
1. Checks if the previous step's timestamp exists
2. Finds files that match both the extension criteria and the modification time criteria
3. Creates a tar archive if matching files are found
4. Updates the log and increments the appropriate counter

### Support Functions

#### `wait_between_steps()`

This function pauses execution between backup steps:

```bash
wait_between_steps() {
    local wait_time=${1:-$WAIT_TIME_BETWEEN_STEPS}
    sleep "$wait_time"
}
```

### Main Execution Functions

#### `run_backup_cycle()`

This function orchestrates a single backup cycle by running all five steps with appropriate waiting periods:

```bash
run_backup_cycle() {
    # STEP 1: Full backup
    do_full_backup
    
    # Wait between steps
    wait_between_steps
    
    # STEP 2: Incremental backup after STEP 1
    do_incremental_backup_step2
    
    # Wait between steps
    wait_between_steps
    
    # STEP 3: Incremental backup after STEP 2
    do_incremental_backup_step3
    
    # Wait between steps
    wait_between_steps
    
    # STEP 4: Differential backup
    do_differential_backup
    
    # Wait between steps
    wait_between_steps
    
    # STEP 5: Size-based incremental backup
    do_incremental_size_backup
}
```

#### `run_continuous_backup()`

This function is the main driver of the backup system, running backup cycles indefinitely:

```bash
run_continuous_backup() {
    # Initialize paths and create folders
    init_paths_and_folders
    
    # Check for existing backups
    check_previous_backups
    
    # Run forever
    while true; do
        # Run a complete backup cycle
        run_backup_cycle
    done
}
```

### Main Program Entry Point

The script begins execution at the bottom:

```bash
# Process command line arguments
process_command_arguments "$@"

# Start the continuous backup process
run_continuous_backup
```

## 📝 Logging System

The backup system maintains a detailed log file (`~/w25log.txt`) that records all backup operations. Each entry includes:

- Timestamp (date and time)
- Backup action (file created or message for no changes)
- Backup file name (if applicable)

Example log entries:

```
Thu 8 Mar2025 06:16:08 PM EDT fullbup-1.tar was created
Thu 8 Mar2025 06:18:08 PM EDT incbup-1.tar was created
Thu 8 Mar2025 06:20:08 PM EDT No changes-Incremental backup was not created
Thu 8 Mar2025 06:22:08 PM EDT diffbup-1.tar was created
```

The log file provides a chronological record of all backup activities, making it easy to track when backups were created and identify any issues.

## ⚙️ Performance Considerations

The script includes several optimizations to improve performance and resource usage:

1. **Selective Backup**: Incremental and differential backups only process files that have changed, reducing processing time and storage requirements.

2. **Temporary Files**: Uses temporary files to store lists of files for backup, which is more efficient than piping results directly to tar.

3. **Parallel Processing**: Uses find command efficiently to locate files.

4. **Efficient File Checking**: Various approaches to check file existence and properties to optimize performance.

5. **Error Handling**: Includes error checks to ensure robust operation even when issues occur.

## ⚠️ Limitations

While the system is comprehensive, it has some limitations to be aware of:

1. **Storage Usage**: Continuous operation will eventually consume significant disk space.

2. **Resource Utilization**: The script runs continuously, which uses system resources.

3. **No Compression**: The tar files are not compressed, which could lead to larger backup sizes.

4. **No Remote Backup**: The system only backs up to local directories.

5. **No Rotation/Cleanup**: There's no automated removal of old backups.

## 🔮 Future Enhancements

Potential improvements for future versions:

1. **Compression**: Add options for compressed backups (.tar.gz or .tar.bz2).

2. **Backup Rotation**: Implement automated removal of old backups.

3. **Remote Backup**: Add support for backing up to remote servers.

4. **Scheduling Options**: Allow user-defined backup intervals.

5. **Exclude Patterns**: Add ability to exclude certain files or directories.

6. **Encryption**: Add option to encrypt backups.

7. **Verification**: Implement backup verification steps.

8. **GUI Interface**: Create a graphical interface for easier management.

## 🛠️ Troubleshooting

Common issues and solutions:

### Script Not Running in Background

If the script stops when you log out, use `nohup`:

```bash
nohup ./w25backup.sh .txt .pdf &
```

### No Backup Files Created

1. Check permissions:
   ```bash
   ls -la ~/backup/
   ```

2. Ensure enough disk space:
   ```bash
   df -h
   ```

3. Check log file for errors:
   ```bash
   tail -n 20 ~/w25log.txt
   ```

### Incorrect File Extensions

Make sure to include the dot (.) in file extensions:

```bash
# Correct
./w25backup.sh .txt .pdf

# Incorrect
./w25backup.sh txt pdf
```

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
