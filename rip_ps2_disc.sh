#!/bin/bash

# Default values
DEFAULT_DISK="/dev/disk2"
DEFAULT_OUTPUT_PATH="$HOME/Desktop"
DEFAULT_BS="4m"

# Function to display usage information
usage() {
  echo "Usage: $0 [--if <disk>] [--of <output_file>] [--bs <block_size>]"
  echo "  --if       : Source disk (e.g., /dev/disk2)"
  echo "  --of       : Output file path (e.g., ~/Desktop/file.iso)"
  echo "  --bs       : Block size (e.g., 4m)"
  exit 1
}

# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --if)
      DISK="$2"
      shift 2
      ;;
    --of)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --bs)
      BS="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

# Set defaults if parameters are not provided
DISK="${DISK:-$DEFAULT_DISK}"
BS="${BS:-$DEFAULT_BS}"

# Validate the disk
if [ ! -b "$DISK" ]; then
  echo "Error: Disk $DISK does not exist or is not a valid block device."
  exit 1
fi

# Get the volume name of the disk and trim whitespace
VOLUME_NAME=$(diskutil info "$DISK" | grep "Volume Name" | awk -F': ' '{print $2}' | xargs)

# Check if volume name was found
if [ -z "$VOLUME_NAME" ]; then
  echo "Error: Could not determine the volume name of $DISK."
  #exit 1
  VOLUME_NAME="UNTITLED"
  echo "Setting Volume Name static $VOLUME_NAME"
fi

# Update OUTPUT_FILE if not explicitly provided and include volume name
if [ -z "$OUTPUT_FILE" ]; then
  OUTPUT_FILE="$DEFAULT_OUTPUT_PATH/${VOLUME_NAME}.iso"
fi

# Display the trimmed volume name
echo "Volume Name: $VOLUME_NAME"

# Extract the size in bytes from the "Disk Size" line
DISK_SIZE_BYTES=$(diskutil info "$DISK" | grep "Disk Size" | awk -F'[(]' '{print $2}' | awk -F' ' '{print $1}')

# Convert disk size to megabytes
DISK_SIZE_MB=$(echo "scale=2; $DISK_SIZE_BYTES / 1048576" | bc)

# Get available free space in the output directory in megabytes
FREE_SPACE_MB=$(df -m "$(dirname "$OUTPUT_FILE")" | awk 'NR==2 {print $4}')

# Check if there is enough free space and display in appropriate unit
if (( $(echo "$DISK_SIZE_MB > 1024" | bc -l) )); then
  if (( $(echo "$FREE_SPACE_MB < $DISK_SIZE_MB" | bc -l) )); then
    echo "Error: Not enough free space in $(dirname "$OUTPUT_FILE"). Required: ${DISK_SIZE_MB}MB, Available: ${FREE_SPACE_MB}MB."
    exit 1
  fi
else
  if (( "$FREE_SPACE_MB" < "$(echo "$DISK_SIZE_MB" | awk '{print int($0)}')" )); then
    echo "Error: Not enough free space in $(dirname "$OUTPUT_FILE"). Required: ${DISK_SIZE_MB}MB, Available: ${FREE_SPACE_MB}MB."
    exit 1
  fi
fi

# Confirm with the user before proceeding
echo "You are about to start dumping the disk $DISK to $OUTPUT_FILE."
echo "This process will unmount the disk and write the entire disk content to an ISO file."
echo "Block size is set to $BS."
echo "Do you want to continue? (yes/no)"
read -r CONFIRMATION

if [[ "$CONFIRMATION" != "yes" ]]; then
  echo "Operation canceled by the user."
  exit 0
fi

# Unmount the disk
echo "Unmounting $DISK..."
diskutil unmountDisk "$DISK"

# Check if unmount was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to unmount $DISK."
  exit 1
fi

# Start the disk dump process with pv for progress reporting
echo "Starting disk dump process to $OUTPUT_FILE with block size of $BS..."

# Perform the disk dump with pv
pv -tpreb "$DISK" | dd bs="$BS" of="$OUTPUT_FILE"

# Check if dd was successful
if [ $? -eq 0 ]; then
  echo "Disk dump completed successfully. ISO saved at $OUTPUT_FILE."
else
  echo "Error: Disk dump failed."
  exit 1
fi

# Eject the disk
echo "Ejecting $DISK..."
diskutil eject "$DISK"

# Check if eject was successful
if [ $? -eq 0 ]; then
  echo "Disk $DISK ejected successfully."
else
  echo "Error: Failed to eject $DISK."
  exit 1
fi
