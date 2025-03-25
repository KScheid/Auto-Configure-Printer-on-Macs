# macOS Printer Auto-Configuration Script

This repository contains a Bash script designed to automate the configuration of network printers on macOS devices. It uses the manufacturer-provided PPD files to ensure full printer functionality and can be deployed as a post-install script using tools like NinjaRMM.

## Table of Contents

1.  [I. Installing the Printer Driver via NinjaRMM](#i-installing-the-printer-driver-via-ninjarmm)
2.  [II. Adding the Printer Configuration Script to NinjaRMM](#ii-adding-the-printer-configuration-script-to-ninjarmm)
3.  [III. Script Configuration Guide](#iii-script-configuration-guide)
    * [A. Variables to Modify](#a-variables-to-modify)
    * [B. Network Considerations (Ping Check)](#b-network-considerations-ping-check)
    * [C. Script Template](#c-script-template)
4.  [IV. Script Saving and Testing](#iv-script-saving-and-testing)
    * [A. Save the Script and Add to NinjaRMM](#a-save-the-script-and-add-to-ninjarmm)
    * [B. Test the Driver Install and Script](#b-test-the-driver-install-and-script)

---

## I. Installing the Printer Driver via NinjaRMM

This section guides you through adding a new printer driver installation application within NinjaRMM, which will deploy the driver files needed by the configuration script.

### A. Add New Installation Application

1.  **Name:** Enter a descriptive name for the application (e.g., "Canon iR-ADV C5840i Driver").
2.  **Description (Optional):** Add a brief description of the driver.
3.  **Operating System:** Select "macOS".
4.  **Architecture:** Select "64-bit" (this is almost always the correct choice for modern Macs).
5.  **Installer:** This is the _critical_ part.
    * **Download:** Download the appropriate driver package (`.pkg`, `.dmg`, or `.zip`) from the printer manufacturer's website (e.g., Canon, Kyocera, HP). Make sure it's for the *exact* printer model and macOS.
    * **Upload:** Add the downloaded `.pkg` file to NinjaRMM.
    * **IMPORTANT: NO SPACES IN FILENAME:** Ensure the filename of the `.pkg` file *does not contain any spaces*. If it does, rename it, replacing spaces with underscores (`_`) *before* uploading it to Ninja. Spaces will break the installation process.
6.  **Run As:** Select "System".

### B. Additional Settings (Optional)

1.  **Helper Files:**
    * If you downloaded a `.dmg` file, and it contained files *other* than the `.pkg` installer, add those files/folders here. This is less common; most macOS printer drivers are self-contained `.pkg` files.
2.  **Installer Icon:** You can optionally choose a custom icon (e.g., the printer brand's logo). The image must be 32x32 pixels. You might need to use an image downscaler to achieve this size.
3.  **Pre-Install Script:** Add any script you'd want to run *prior* to the driver installation.
4.  **Post Install Script:** **This is where you will add the configuration script from Section III.C.**

### C. Submit

1.  NinjaRMM might prompt for a Two-Factor Authentication (2FA) code. Enter the code if required.
2.  Click "Add" to save the new application.

---

## II. Adding the Printer Configuration Script to NinjaRMM

This section covers adding the configuration script itself within NinjaRMM, typically as a post-install action for the driver application created above.

### A. Script Details (in NinjaRMM)

1.  **Script (Code Area):** Paste the entire script (from the template in Section III.C) into the script editor area.
2.  **Name:** Enter a descriptive name for the script (e.g., "Configure Canon Office Printer").
3.  **Description:** Add a helpful description.
4.  **Language:** Select "ShellScript".
5.  **Operating System:** Select "macOS".
6.  **Architecture:** Select "64-bit".
7.  **Run As:** Select "System".
8.  **Parameters:** Leave this blank (no parameters are needed).

---

## III. Script Configuration Guide

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
    * **Description:** The _full path_ to the printer's PPD file (`.ppd.gz` or `.PPD`). After the driver is installed (via Ninja in Section I), the PPD file will usually be in `/Library/Printers/PPDs/Contents/Resources/`. You might need to look in subfolders within `Resources` to find the correct file. The path _can_ contain spaces.
    * **Example:** `ppd_path_orig="/Library/Printers/PPDs/Contents/Resources/Canon/MyCanonPrinter.ppd.gz"`
    * **Example:** `ppd_path_orig="/Library/Printers/PPDs/Contents/Resources/Xerox WorkCentre 7855.PPD"`

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
        echo "Make sure the correct PPD file is installed."
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
