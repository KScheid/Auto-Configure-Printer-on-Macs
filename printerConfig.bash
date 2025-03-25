#!/bin/bash

# Printer Configuration
printer_name_orig="Kyocera TASKalfa 2554ci"
printer_ip="172.18.0.171"
ppd_path_orig="/Library/Printers/PPDs/Contents/Resources/Kyocera TASKalfa 2554ciJ.PPD" #keep this for explanation purposes

# Check if printer is reachable
echo "Checking if printer is reachable at $printer_ip..."
if ! ping -c 1 -W 2 "$printer_ip" &>/dev/null; then
    echo "Error: Printer at $printer_ip is not reachable. Check network connectivity."
    exit 1
fi
echo "Printer is reachable."  # Success message!

# Convert printer name to a format without spaces
printer_name=$(echo "$printer_name_orig" | tr ' ' '_')

# Handle PPD file (compressed or uncompressed)
ppd_dir=$(dirname "$ppd_path_orig")
ppd_filename=$(basename "$ppd_path_orig")
ppd_path="$ppd_path_orig"

# Check for both .PPD and .ppd.gz files
if [ ! -f "$ppd_path" ]; then
    ppd_filename_gz="${ppd_filename%.PPD}.ppd.gz"
    ppd_path="$ppd_dir/$ppd_filename_gz"
    if [ ! -f "$ppd_path" ]; then
        echo "Error: Neither $ppd_filename nor $ppd_filename_gz found in $ppd_dir."
        echo "Make sure the correct Kyocera PPD file is installed."
        exit 1
    fi
fi

# Add the printer using the correct PPD
echo "Adding printer $printer_name..."
if ! lpadmin -p "$printer_name" -E -v "ipp://$printer_ip" -P "$ppd_path"; then
    echo "Error: Failed to add printer. Check CUPS logs for details."
    exit 1
fi

# Set as default printer
lpadmin -d "$printer_name"

# Duplex printing is OFF by default.  Users can enable it in the print dialog.

echo "Printer '$printer_name' has been added and configured successfully."
exit 0
