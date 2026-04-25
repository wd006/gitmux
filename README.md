<div align="center">

```text
   _______ __  __  ___          
  / ____(_) /_/  |/  /_  ___  __
 / / __/ / __/ /|_/ / / / / |/_/
/ /_/ / / /_/ /  / / /_/ />  <  
\____/_/\__/_/  /_/\__,_/_/|_|  
```

**Multi-Profile Identity & Security Manager for Git**

[![Latest Version](https://img.shields.io/github/v/tag/wd006/gitmux?sort=semver&color=blue&label=version)](https://github.com/wd006/gitmux/tags)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)]()
[![Top Language](https://img.shields.io/github/languages/top/wd006/gitmux?color=green)](https://github.com/wd006/gitmux)
[![License](https://img.shields.io/github/license/wd006/gitmux)](LICENSE)

</div>

<br>

## 📑 Table of Contents
- [❔ What is Gitmux](#-what-is-gitmux)
- [✨ Features](#-features)
- [🚀 Quick Start](#-quick-start)
- [📖 How it Works](#-how-it-works)
- [⚙️ Under the Hood (Architecture)](#️-under-the-hood-architecture)
- [🧹 Cleanup & Uninstall](#-cleanup--uninstall)
- [📄 License](#-license)
- [🤝 Contributing](#-contributing)
- [📬 Contact](#-contact)


## ❔ What is GitMux?

Managing multiple Git identities (like Work and Personal) on the same machine usually means dealing with manual SSH tweaks, generating GPG keys, and remembering to set `user.email` for every repository you clone.

**GitMux is a standalone bash script that automates this entire setup process.**

It acts as a one-time configuration wizard. You define your profiles and assign them to specific base directories (e.g., `~/Work` and `~/Personal`). GitMux then uses Git's native `includeIf` directive to route your identities based on the folder you are in. Any repository cloned inside `~/Work` will automatically use your work email, SSH key, and GPG signature.

> [!NOTE]
> GitMux is not an application you install. It has no background daemons or runtime dependencies. It simply generates native Git and OpenSSH configurations, creates the necessary keys, and exits. Once the script finishes, your system continues to use vanilla Git.


## ✨ Features

- **👻 Zero Bloat:** Works purely as a one-time setup wizard. No background processes, no installations. It just configures your native Git/SSH and exits.
- **📂 Directory-Based Routing:** Automatically switches your Git user and email based on the directory you are working in using Git's native `includeIf` directive. No more `--local` configs.
- **🔑 Automated SSH Management:** Generates ED25519 SSH keys securely. Choose between transparent routing (`core.sshCommand`) or classic SSH aliases.
- **🛡️ GPG Commit Signing:** Automatically detects or generates RSA-4096 GPG keys in unattended batch mode. Configures `commit.gpgsign` to give your commits that shiny "Verified" badge.
- **🔁 Idempotent & Safe:** Run it as many times as you want. System modifications are isolated within marker blocks, ensuring your custom global settings are never touched.
- **🖥️ Interactive UI & Export:** Outputs a neatly formatted, step-by-step terminal dashboard and automatically saves a backup log (`gitmux_summary.log`) to help you easily copy your public keys to GitHub/GitLab

## 🚀 Quick Start

You can download and run GitMux using a single curl command. No Node.js, Python, or external dependencies required.

```bash
curl -O https://raw.githubusercontent.com/wd006/gitmux/main/gitmux.sh && chmod +x gitmux.sh && ./gitmux.sh
```

### Prerequisites
- Bash (macOS or Linux)
- `gpg` (Optional, but required if you want the Verified badge on your commits. Install via `brew install gnupg` or `apt install gnupg`).


## 📖 How It Works

Once executed, the CLI wizard will guide you through the setup. For each profile you want to configure, you will be asked:

1. **Profile Info:** Name (e.g., `work`), Git username, and email.
2. **Base Directory:** The root folder for this profile (e.g., `~/Projects/Work`).
3. **SSH Routing Method:**
   - **Transparent (Recommended):** Injects `core.sshCommand` into your Git config. You can keep using standard clone URLs (`git clone git@github.com:repo.git`).
   - **Classic (Alias):** Modifies your `~/.ssh/config`. Requires using alias clone URLs (`git clone git@github-work:repo.git`).
4. **GPG Setup:** Choose whether to auto-generate a GPG key for the "Verified" badge.
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

---
<div align="center">
  <sub>by <b><a href="https://github.com/wd006">wd006</a></b></sub>
</div>
