# 🦎 Newt Installer for Pangolin

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://www.linux.org/)
[![Backend: Pangolin](https://img.shields.io/badge/Backend-Pangolin-blue.svg)](https://pangolin.net/)

**Newt** is a powerful, lightweight WireGuard-based tunnel client designed to connect your local resources to a [Pangolin](https://pangolin.net/) server. This repository provides a streamlined, automated installation script to get Newt up and running as a persistent system service in seconds.

---

## ✨ Features

- **🚀 Instant Setup**: One-command installation and configuration.
- **🛡️ Secure**: Automatically handles permissions and configuration security.
- **🔄 Multi-Init Support**: Configures either `systemd` or `OpenRC` automatically.
- **📱 Cross-Arch**: Supports both `x86_64` (AMD64) and `aarch64` (ARM64).
- **📝 Informative**: Beautifully formatted terminal output and clear status feedback.

---

## ⚡ Quick Installation

Ready to deploy? Run the following command in your terminal. It will download the latest binary, prompt for your credentials, and set up the service.

```bash
curl -fsSL https://github.com/rezwanahmedratul/install-newt/raw/refs/heads/main/install-newt.sh | bash
```

> [!TIP]
> **Don't have your credentials yet?** Log in to your Pangolin dashboard, navigate to **Sites**, and click **Add Site** to generate your Endpoint, ID, and Secret.

---

## 🛠️ Manual Installation

If you prefer to download and run the script manually:

1. **Clone or Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/rezwanahmedratul/install-newt/main/install-newt.sh
   ```
2. **Make it executable:**
   ```bash
   chmod +x install-newt.sh
   ```
3. **Run with sudo:**
   ```bash
   sudo ./install-newt.sh
   ```

### Command Line Arguments
You can also pass your credentials directly as environment variables to skip the interactive prompts:
```bash
sudo NEWT_ID="your_id" NEWT_SECRET="your_secret" PANGOLIN_ENDPOINT="https://your-endpoint.com" ./install-newt.sh
```

---

## 📊 Management & Logs

Once installed, you can manage the Newt service using standard commands for your init system:

### Systemd (Ubuntu, Debian, CentOS, etc.)
| Action | Command |
| :--- | :--- |
| **Check Status** | `sudo systemctl status newt` |
| **Restart Service** | `sudo systemctl restart newt` |
| **Stop Service** | `sudo systemctl stop newt` |
| **View Live Logs** | `sudo journalctl -u newt -f` |

### OpenRC (Alpine, Gentoo, etc.)
| Action | Command |
| :--- | :--- |
| **Check Status** | `sudo rc-service newt status` |
| **Restart Service** | `sudo rc-service newt restart` |
| **Stop Service** | `sudo rc-service newt stop` |
| **View Logs** | `tail -f /var/log/messages` |

---

## 📁 Configuration Layout

The installer organizes files as follows:

- **Binary**: `/usr/local/bin/newt`
- **Config File**: `/etc/newt/config.json` (chmod 600)
- **Service Unit**: `/etc/systemd/system/newt.service` or `/etc/init.d/newt`

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request if you have ideas for improvements.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ for the Pangolin Community
</p>
