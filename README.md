# 🔐 SSH Key Manager (ssh-key-manager.sh)

An interactive shell script to create, switch, and manage multiple SSH key profiles (Ed25519) seamlessly on Linux and macOS.

## 🚀 Getting Started

### 1. Installation (Clone)
First, clone the repository to your local machine.

### 2. Permissions & Execution
You can run the script in two ways:

- **Option A**: Run with Bash directly (No permission change needed)
- **Option B**: Make it executable (Recommended)

## 🛠 Usage Guide

### A. Switching Active Keys
When you run the script, it scans `~/.ssh/` for existing profiles.
- Enter the number corresponding to the profile you want to use.
- The script updates the symbolic links (`id_ed25519`) and adds the key to your `ssh-agent`.

### B. Creating a New Profile
- Press `n` for a new profile.
- Enter a folder name (this becomes your profile name, e.g., `github-work`).
- (Optional) Enter an identity/email for the key comment.
- The script generates a secure Ed25519 key pair and sets permissions to `600`.

### C. Registering to GitHub
After every switch or creation, the script automatically prints your Public Key.
- Simply copy the output starting with `ssh-ed25519`.
- Paste it into your GitHub SSH settings.

## 💡 Pro Tip: Run from Anywhere
Tired of navigating to this folder? Create a symbolic link in your system's `bin` directory to run it using the command `swkey`.

## 📂 Directory Structure
The script organizes your `.ssh` directory into isolated profiles.

## 🔒 Security
- **Isolation**: Each key is kept in its own subdirectory.
- **Permission Hardening**: Private keys are automatically set to `600` for SSH compliance.
- **No Overwrites**: Prevents accidental deletion of existing key folders.

---
**Author**: ppugend
**License**: MIT
