# VirusTotal File Upload Bash Script (`vt_upload.sh`)

This script allows you to upload files to VirusTotal for analysis directly from your Linux or macOS command line using `curl` and `jq`.

## Features

* Uploads files to the VirusTotal API v3.
* Retrieves API key from the `VIRUSTOTAL_API_KEY` environment variable or a command-line argument (`-k` or `--api-key`).
* Automatically attempts to use the correct VirusTotal endpoint for files larger than 32MB (requires a premium API key for files > 32MB, standard endpoint used otherwise).
* Checks for necessary command-line tools (`curl`, `jq`, `stat`).
* Provides the direct URL to the analysis report on the VirusTotal website upon successful upload.
* Includes basic error handling and user feedback.

## Prerequisites

1.  **Bash:** A standard Bash shell (usually default on Linux and macOS).
2.  **`curl`:** Command-line tool for transferring data. Usually pre-installed.
3.  **`jq`:** Command-line JSON processor. Install if needed:
    * **Debian/Ubuntu:** `sudo apt update && sudo apt install jq`
    * **macOS (Homebrew):** `brew install jq`
    * **Fedora/CentOS/RHEL:** `sudo dnf install jq` or `sudo yum install jq`
4.  **`stat`:** Command-line utility to display file status. Usually pre-installed on Linux and macOS.
5.  **VirusTotal API Key:** A free or premium API key from VirusTotal.
    * Sign up/log in: [https://www.virustotal.com/](https://www.virustotal.com/)
    * Find your key under Profile Settings -> API Key.

## Setup

1.  **Save the Script:** Save the script code to a file named `vt_upload.sh`.
2.  **Make Executable:** Open your terminal and run:
    ```bash
    chmod +x vt_upload.sh
    ```
3.  **Configure API Key (Recommended Method):** Set the `VIRUSTOTAL_API_KEY` environment variable. Add this line to your shell's configuration file (e.g., `~/.bashrc`, `~/.zshrc`, `~/.profile`) for persistence:
    ```bash
    export VIRUSTOTAL_API_KEY='YOUR_API_KEY_HERE'
    ```
    Reload your shell or run `source ~/.bashrc` (or the relevant file) after adding the line.

## Usage

Run the script from your terminal, providing the path to the file you want to upload.

**Using Environment Variable for API Key:**

```bash
./vt_upload.sh /path/to/your/file/to/scan.exe

Providing API Key via Command-Line Argument:

./vt_upload.sh /path/to/your/document.pdf -k YOUR_API_KEY_HERE

or

./vt_upload.sh /path/to/archive.zip --api-key YOUR_API_KEY_HERE

Output:

Upon successful upload, the script will output:

Using API key from VIRUSTOTAL_API_KEY environment variable.
File: scan.exe
Size: 1.50 MB
Uploading to [https://www.virustotal.com/api/v3/files](https://www.virustotal.com/api/v3/files)...
Upload successful!
Analysis ID: u-abc123def456...-1678886400
View analysis details at: [https://www.virustotal.com/gui/file-analysis/u-abc123def456...-1678886400](https://www.virustotal.com/gui/file-analysis/u-abc123def456...-1678886400)
Note: Analysis may take some time to complete.

Notes
The free VirusTotal API has limitations on the number of requests per minute and potentially the file size (officially 32MB for the standard endpoint).

Uploading files larger than 32MB typically requires a premium VirusTotal API key to successfully use the large file upload endpoint. The script attempts this automatically if the file size exceeds the limit but may fail without a premium key.

Keep your API key confidential
