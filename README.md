<div align="center">

```text
   _______ __  __  ___          
  / ____(_) /_/  |/  /_  ___  __
 / / __/ / __/ /|_/ / / / / |/_/
/ /_/ / / /_/ /  / / /_/ />  <  
\____/_/\__/_/  /_/\__,_/_/|_|  
```

**Multi-Profile Identity & Security Manager for Git**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/wd006/gitmux/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)]()
[![Bash](https://img.shields.io/badge/language-Bash-green.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

</div>

<br>

**GitMux** is a zero-dependency, highly idempotent CLI tool designed for developers who juggle multiple Git identities (e.g., Work, Personal, Freelance) on the same machine. It automates the complex setup of SSH routing, directory-based Git configurations, and GPG commit signing—ensuring you never commit with the wrong email or missing "Verified" badge again.

## 📑 Table of Contents
- [✨ Features](#-features)
- [🚀 Installation & Quick Start](#-installation--quick-start)
- [📖 Documentation & Usage](#-documentation--usage)
- [⚙️ Under the Hood (Architecture)](#️-under-the-hood-architecture)
- [🧹 Cleanup & Uninstall](#-cleanup--uninstall)
- [📄 License](#-license)
- [🤝 Contributing](#-contributing)
- [📬 Contact](#-contact)

## ✨ Features

- **📂 Folder-Based Identity:** Automatically switches your Git user and email based on the directory you are working in using Git's `includeIf` directive.
- **🔑 Automated SSH Management:** Generates ED25519 SSH keys silently and securely. Choose between transparent routing (`core.sshCommand`) or classic SSH aliases.
- **🛡️ GPG Commit Signing:** Automatically detects or generates RSA-4096 GPG keys in unattended batch mode. Configures `commit.gpgsign` to give your commits that shiny "Verified" badge.
- **🔁 Idempotent Execution:** Run it as many times as you want. Safe modifications via marker blocks ensure your custom global settings are never touched.
- **🖥️ Interactive Dashboard:** Outputs a neatly formatted, step-by-step UI to help you copy your SSH and GPG public keys directly to your Git provider.
- **📝 Export Logs:** Automatically saves a safe backup of your public keys to `gitmux_summary.log`.

## 🚀 Installation & Quick Start

You can download and run GitMux using a single curl command. No Node.js, Python, or external dependencies required.

```bash
curl -O https://raw.githubusercontent.com/wd006/gitmux/main/gitmux.sh && chmod +x gitmux.sh && ./gitmux.sh
```

### Prerequisites
- Bash (macOS or Linux)
- `gpg` (Optional, but required if you want the Verified badge on your commits. Install via `brew install gnupg` or `apt install gnupg`).

## 📖 Documentation & Usage

Once executed, the CLI wizard will guide you through the setup. For each profile you want to configure, you will be asked:

1. **Profile Name & Git Info:** Provide a name (e.g., `work`), your Git username, and email.
2. **Base Directory:** Provide the root folder for this profile (e.g., `~/Projects/Work`). Any repository cloned inside this folder will automatically use this profile.
3. **SSH Routing Method:**
   - **Transparent (Recommended):** Injects `core.sshCommand` into your config. You can keep using standard clone URLs like `git clone git@github.com:repo.git`.
   - **Classic (Alias):** Modifies your `~/.ssh/config`. Requires you to change your clone URLs to `git clone git@github-work:repo.git`.
4. **GPG Setup:** Choose whether to enable GPG signing. You can set a passphrase or leave it blank for a passwordless key.
5. **Dashboard:** Follow the on-screen instructions to copy the generated keys to GitHub/GitLab.

## ⚙️ Under the Hood (Architecture)

GitMux is built with system safety in mind. Here is exactly what it does to your system:

- **Isolated Sub-configs:** Creates hidden configuration files for each profile (e.g., `~/.gitconfig-work`).
- **Global Config Injection:** Modifies your global `~/.gitconfig` and `~/.ssh/config` files by wrapping its rules inside `# === BEGIN GITMUX AUTO-GENERATED ===` blocks.
- **Cross-Platform:** Uses standard POSIX `awk` to ensure text replacements work flawlessly across both GNU (Linux) and BSD (macOS) environments.

## 🧹 Cleanup & Uninstall

Made a mistake or want to revert your machine to its original state? You can safely strip all GitMux configurations from your global files.

```bash
./gitmux.sh --clean
```
*(Note: This only removes the routing blocks from `~/.gitconfig` and `~/.ssh/config`. Your generated SSH/GPG keys and project folders will remain untouched).*

---

## 📄 License

This project is licensed under the MIT License. See the [`LICENSE`](LICENSE) file for more details.

## 🤝 Contributing

Contributions are greatly appreciated. Please fork the repository and create a pull request, or open an issue for major changes.

## 📬 Contact

**E-Mail:** [github@wd006.pp.ua](mailto:github@wd006.pp.ua)

**Project Link:** [https://github.com/wd006/gitmux](https://github.com/wd006/gitmux)

For questions, bug reports, or support, please **open an issue** on the GitHub repository.