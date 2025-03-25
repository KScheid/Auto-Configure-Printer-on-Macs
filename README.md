# macOS Printer Auto-Configuration Script

This repository contains a Bash script designed to automate the configuration of network printers on macOS devices *after* the necessary drivers have been installed. It uses the manufacturer-provided PPD files to ensure full printer functionality.

**Prerequisites:**

* **Printer Drivers Installed:** The correct macOS printer driver package for your specific printer model **must** be installed on the target Mac *before* running this script. Driver installation typically places the required PPD file in `/Library/Printers/PPDs/Contents/Resources/`.
* **Printer Network Information:** You need the printer's IP address.

## Table of Contents

1.  [I. Using the Printer Configuration Script](#i-using-the-printer-configuration-script)
2.  [II. Script Configuration Guide](#ii-script-configuration-guide)
    * [A. Variables to Modify](#a-variables-to-modify)
    * [B. Network Considerations (Ping Check)](#b-network-considerations-ping-check)
    * [C. Script Template](#c-script-template)
3.  [III. Script Testing](#iii-script-testing)
    * [A. Prepare the Script](#a-prepare-the-script)
    * [B. Test the Script](#b-test-the-script)

---

## I. Using the Printer Configuration Script

This script is designed to be run on a macOS machine where the printer drivers are already present.

1.  **Configure:** Modify the script template in Section II.C below with your specific printer's details.
2.  **Save:** Save the modified script to a file (e.g., `configure_printer.sh`).
3.  **Make Executable (Optional but recommended):** Open Terminal and run `chmod +x configure_printer.sh`.
4.  **Run:** Execute the script with administrator privileges using `sudo` in the Terminal:
    ```bash
    sudo ./configure_printer.sh
    ```
5.  **Deployment (Optional):** This script can also be incorporated into deployment tools (like Jamf Pro, Munki, etc.) as a post-install script or policy payload, ensuring it runs *after* the driver installation is confirmed.

---

## II. Script Configuration Guide

This section details how to modify the script for your specific printer. You _must_ customize the variables at the beginning of the script.

### A. Variables to Modify

You'll need to change the following variables at the beginning of the script. Each is explained below:

* **`printer_name_orig`:**
    * **Description:** A friendly, descriptive name for the printer. This is what users will see in the printer list. It _can_ contain spaces.
    * **Example:** `printer_name_orig="Marketing Department Printer"`

* **`printer_ip`:**
    * **Description:** The printer's IP address on your network.
    * **Example:** `printer_ip="192.168.1.75"`

* **`ppd_path_orig`:**
    * **Description:** The _full path_ to the printer's PPD file (`.ppd.gz` or `.PPD`). Since the driver is assumed to be installed, the PPD file will usually be in `/Library/Printers/PPDs/Contents/Resources/`. You might need to look in subfolders within `Resources` to find the correct file matching your printer model. The path _can_ contain spaces.
    * **Example:** `ppd_path_orig="/Library/Printers/PPDs/Contents/Resources/Canon/MyCanonPrinter.ppd.gz"`
    * **Example:** `ppd_path_orig="/Library/Printers/PPDs/Contents/Resources/Xerox WorkCentre 7855.PPD"`

* **Handling Spaces in PPD Paths:**
    * **Problem:** While less common now, spaces within file paths or names can sometimes cause problems in shell scripts if not handled carefully.
    * **Solution in this Script:** This script is designed to handle spaces in the `ppd_path_orig` correctly.
        * It does **not** attempt to rename the PPD file on the disk.
        * The variable `$ppd_path` (which holds the final path used) is consistently enclosed in double quotes (`"`) whenever it's used in commands (e.g., `if [ ! -f "$ppd_path" ]`, `lpadmin -P "$ppd_path"`).
        * Enclosing variables containing paths in double quotes is the standard and correct way in Bash to ensure the shell treats the entire string, including spaces, as a single argument.
        * Additionally, the script prioritizes using the compressed `.ppd.gz` version if it exists, which often follows more consistent naming conventions.

### B. Network Considerations (Ping Check)

The script includes a `ping` command to check if the printer is reachable on the network. This is useful for printers on the _same_ network as the Mac.

* **If the printer is on a *different* network (e.g., a different subnet, behind a firewall):** The `ping` check might fail even if the printer is accessible via CUPS. In this case, you should _comment out_ the `ping` check by adding a `#` at the beginning of each line in that section. See the example in the script template below.

### C. Script Template

```bash
#!/bin/bash

# --- FILL THESE IN WITH YOUR PRINTER'S INFORMATION ---
printer_name_orig="**Your Printer Name Here**"  # e.g., "Reception Printer"
printer_ip="**Your.Printer.IP.Address**"  # e.g., "10.0.1.20"
ppd_path_orig="**/Path/To/Your/PPD/File.ppd.gz**"  # e.g., "/Library/Printers/PPDs/Contents/Resources/MyPrinter.ppd.gz"
# -------------------------------------------------------------

# --- Network Check (Comment out if printer is on a different network) ---
echo "Checking if printer is reachable at $printer_ip..."
if ! ping -c 1 -W 2 "$printer_ip" &>/dev/null; then
    echo "Error: Printer at $printer_ip is not reachable. Check network connectivity."
    exit 1
fi
echo "Printer is reachable."

# --- To comment out the ping check, add '#' at the beginning of the lines above, like this:
# echo "Checking if printer is reachable at $printer_ip..."
# if ! ping -c 1 -W 2 "$printer_ip" &>/dev/null; then
#     echo "Error: Printer at <span class="math-inline">printer\_ip is not reachable\. Check network connectivity\."
\#     exit 1
\# fi
\# echo "Printer is reachable\."
\# \-\-\- End of Network Check \-\-\-
\# Convert printer name to a format without spaces for CUPS
printer\_name\=</span>(echo "<span class="math-inline">printer\_name\_orig" \| tr ' ' '\_'\)
\# Handle PPD file \(compressed or uncompressed\)
ppd\_dir\=</span>(dirname "<span class="math-inline">ppd\_path\_orig"\)
ppd\_filename\=</span>(basename "$ppd_path_orig")
ppd_path="$ppd_path_orig"  # Initially set to the original path

# Check for both .PPD and .ppd.gz files
if [ ! -f "<span class="math-inline">ppd\_path" \]; then
ppd\_filename\_gz\="</span>{ppd_filename%.PPD}.ppd.gz"
    ppd_path="$ppd_dir/$ppd_filename_gz"
    if [ ! -f "$ppd_path" ]; then
        echo "Error: Neither $ppd_filename nor $ppd_filename_gz found in $ppd_dir."
        echo "Make sure the correct PPD file is installed and accessible."
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

# Duplex printing is OFF by default. Users can enable it in the print dialog.

echo "Printer '$printer_name' has been added and configured successfully."
exit 0
