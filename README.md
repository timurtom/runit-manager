# Runit Service Manager

> 🚀 A simple, interactive CLI tool for managing services on runit-based Linux distributions

[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/timurtom/runit-manager)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0+-brightgreen.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://www.linux.org/)
[![Void Linux](https://img.shields.io/badge/Void_Linux-supported-1793d1.svg)](https://voidlinux.org/)
[![Artix Linux](https://img.shields.io/badge/Artix_Linux-supported-0b7eb4.svg)](https://artixlinux.org/)

## 📋 What is Runit Service Manager?

**Runit Service Manager** is a user-friendly command-line tool designed to **simplify service management** on Linux distributions that use **runit** as their init system (like **Void Linux**, **Artix Linux**, and others).

Managing services on runit traditionally requires remembering multiple commands:
- `ln -s /etc/sv/service /var/service/` to enable
- `rm /var/service/service` to disable
- `sv status service` to check status
- `sv start/stop/restart service` to control services

This tool wraps all these commands into an **intuitive interface** with both an **interactive menu** and **command-line shortcuts**.

---

## 🎯 What is it For?

### Primary Purpose
To make service management on runit-based systems **easier, faster, and more accessible** for everyone - from beginners to experienced sysadmins.

### Who is it For?

- **🆕 Beginners** - No need to memorize complex commands or understand symlinks
- **👨‍💻 System Administrators** - Quick, efficient service management
- **📦 Developers** - Rapidly enable/disable services during development
- **🎓 Students** - Learn about runit service management in an interactive way
- **🔧 Tinkerers** - Experiment with different services without hassle

### Common Use Cases

| Use Case | Traditional Command | With This Tool |
|----------|-------------------|----------------|
| Enable Nginx | `sudo ln -s /etc/sv/nginx /var/service/` | `sudo runit-manager --enable nginx` |
| Check SSH status | `sv status sshd` | `runit-manager --status sshd` |
| View all services | `ls /etc/sv/` | `runit-manager --list` |
| Disable MySQL | `sudo rm /var/service/mysql && sudo sv stop mysql` | `sudo runit-manager --disable mysql` |
| View logs | `tail -n 20 /etc/sv/nginx/log/current` | `runit-manager --logs nginx` |

---

## 🔧 How It Works

### The Problem It Solves

On runit-based systems:
1. **Services are defined** in `/etc/sv/` (each service has its own directory)
2. **Services are enabled** by creating a symlink in `/var/service/` (or `/run/runit/service/`)
3. **Services are managed** using the `sv` command

This means you need to remember:
- Where services are stored
- How to create/remove symlinks
- Various `sv` commands and their options
- Which commands need `sudo`

### How This Tool Simplifies Everything

#### 1. **Unified Interface**
Instead of using multiple commands, everything is accessible through one tool.

#### 2. **Interactive Menu**
```
1) 📁 View available services
2) ⚡ View enabled services
3) 🔗 Enable a service
4) 🔗 Disable a service
5) ▶  Start a service
6) ■  Stop a service
7) ↻  Restart a service
8) 📊 Show service status
9) 📝 View service logs
10) ℹ  Service information
```

#### 3. **Smart Input Handling**
You can use **either**:
- The service name: `nginx`
- The menu number: `3`

#### 4. **Built-in Safety Checks**
- Verifies services exist before enabling
- Checks if services are already enabled
- Gracefully stops services before disabling
- Provides clear error messages

#### 5. **Color-Coded Feedback**
- 🟢 **Green** - Service is running/enabled
- 🟡 **Yellow** - Service is stopped/disabled
- 🔴 **Red** - Errors or warnings

### Behind the Scenes

#### Enabling a Service
```bash
# What you type:
sudo runit-manager --enable nginx

# What happens:
1. Script checks if nginx exists in /etc/sv/
2. Script checks if nginx is already enabled
3. If both checks pass:
   sudo ln -s /etc/sv/nginx /var/service/
4. runit automatically starts the service
5. Script verifies the service is running
```

#### Disabling a Service
```bash
# What you type:
sudo runit-manager --disable mysql

# What happens:
1. Script checks if mysql is enabled
2. If enabled:
   sudo sv stop mysql   # Graceful stop
   sudo rm /var/service/mysql  # Remove symlink
3. Service is now disabled and stopped
```

#### Checking Status
```bash
# What you type:
runit-manager --status sshd

# What happens:
sv status sshd

# Output:
run: sshd: (pid 1234) 56789s
```

#### Listing Services
```bash
# What you type:
runit-manager --list

# What happens:
1. Scans /etc/sv/ for all services
2. Checks each service for symlink in /var/service/
3. Displays with colors and status indicators
```

---

## 📦 Installation

### 🚀 Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/timurtom/runit-manager.git
cd runit-manager

# Run the installer
chmod +x install.sh
./install.sh
```

### 📥 Manual Installation

```bash
# Download the script
curl -sL https://raw.githubusercontent.com/timurtom/runit-manager/main/runit-manager.sh -o runit-manager.sh

# Or with wget
wget https://raw.githubusercontent.com/timurtom/runit-manager/main/runit-manager.sh

# Make it executable
chmod +x runit-manager.sh

# Install system-wide (requires sudo)
sudo mv runit-manager.sh /usr/local/bin/runit-manager

# Verify installation
runit-manager --version
```

### 🎯 One-Line Install

```bash
curl -sL https://raw.githubusercontent.com/timurtom/runit-manager/main/runit-manager.sh | sudo tee /usr/local/bin/runit-manager > /dev/null && sudo chmod +x /usr/local/bin/runit-manager && runit-manager --version
```

### ✅ Post-Installation Verification

```bash
# Check if installed correctly
which runit-manager
# Should output: /usr/local/bin/runit-manager

# Check version
runit-manager --version
# Should output: runit-manager version 1.0

# Test list command
runit-manager --list
# Should show available services
```

### 📋 System Requirements

- **Linux distribution** with runit init system
  - ✅ Void Linux
  - ✅ Artix Linux (runit edition)
  - ✅ Other runit-based distros
- **Bash 4.0+** (usually pre-installed)
- **sudo** (for privileged operations)
- **runit** (should be pre-installed on runit-based distros)

### 🔍 Checking Your System

```bash
# Check if runit is installed
command -v sv
# Should output: /usr/bin/sv

# Check which init system you're using
ps -p 1
# Should show 'runit' or 'runsvdir'

# Check service directories exist
ls /etc/sv/
# Should show your services
```

---

## 🎮 Usage Examples

### Interactive Mode

```bash
# Launch the interactive menu
runit-manager

# Navigate using numbers
Choose an option: 3  # Enable a service
Enter service name: nginx
```

### Command-Line Mode

```bash
# List all available services
runit-manager --list

# List only enabled services
runit-manager --enabled

# Check service status
runit-manager --status sshd

# Enable a service (requires sudo)
sudo runit-manager --enable nginx

# Disable a service (requires sudo)
sudo runit-manager --disable mysql

# Start a service (requires sudo)
sudo runit-manager --start nginx

# Stop a service (requires sudo)
sudo runit-manager --stop sshd

# Restart a service (requires sudo)
sudo runit-manager --restart nginx

# View service logs
runit-manager --logs nginx

# Get detailed service info
runit-manager --info nginx

# Show help
runit-manager --help
```

### Common Workflows

#### Setting Up a Web Server
```bash
# Enable Nginx
sudo runit-manager --enable nginx

# Check if it's running
runit-manager --status nginx

# View logs
runit-manager --logs nginx
```

#### Troubleshooting SSH
```bash
# Check SSH status
runit-manager --status sshd

# If it's not running, restart it
sudo runit-manager --restart sshd

# Check logs
runit-manager --logs sshd
```

#### Disabling Unused Services
```bash
# View all services
runit-manager --list

# Disable a service
sudo runit-manager --disable redis

# Verify it's gone
runit-manager --list
```

---

## 🛠️ Command Reference

### Interactive Menu Options

| Option | Description | What It Does |
|--------|-------------|--------------|
| **1** | 📁 View available services | Lists all services in `/etc/sv/` with status |
| **2** | ⚡ View enabled services | Lists enabled services with running status |
| **3** | 🔗 Enable a service | Creates symlink and starts service |
| **4** | 🔗 Disable a service | Stops service and removes symlink |
| **5** | ▶ Start a service | Starts a stopped service |
| **6** | ■ Stop a service | Stops a running service |
| **7** | ↻ Restart a service | Restarts a service |
| **8** | 📊 Show service status | Shows detailed service information |
| **9** | 📝 View service logs | Shows last 20 lines of logs |
| **10** | ℹ Service information | Shows service details |
| **0** | 🚪 Exit | Quits the program |

### Command-Line Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--list`, `-l` | List available services | `runit-manager --list` |
| `--enabled`, `-e` | List enabled services | `runit-manager --enabled` |
| `--status`, `-s` | Show service status | `runit-manager --status nginx` |
| `--enable` | Enable a service | `sudo runit-manager --enable nginx` |
| `--disable` | Disable a service | `sudo runit-manager --disable mysql` |
| `--start` | Start a service | `sudo runit-manager --start nginx` |
| `--stop` | Stop a service | `sudo runit-manager --stop nginx` |
| `--restart` | Restart a service | `sudo runit-manager --restart nginx` |
| `--logs` | Show service logs | `runit-manager --logs nginx` |
| `--info` | Show service info | `runit-manager --info nginx` |
| `--help`, `-h` | Show help | `runit-manager --help` |
| `--version`, `-v` | Show version | `runit-manager --version` |

---

## 📂 Directory Structure

Understanding the directories the tool works with:

```
/etc/sv/                 # Service definitions (source)
├── nginx/
│   ├── run              # Start script
│   └── log/             # Optional logging
│       └── run          # Log script
├── sshd/
│   └── run
└── mysql/
    └── run

/var/service/            # Enabled services (symlinks)
├── nginx -> /etc/sv/nginx
└── mysql -> /etc/sv/mysql

/run/runit/service/      # Alternative location (some distros)
└── sshd -> /etc/sv/sshd
```

---

## 🔍 How It Works Internally

### Service Discovery
1. Scans `/etc/sv/` for directories (each is a service)
2. Scans `/var/service/` for symlinks (enabled services)
3. Matches services between both directories

### Status Detection
1. Uses `sv status SERVICE` to check running state
2. Checks for symlink existence to determine enabled state
3. Combines both to show complete status

### Enable Flow
```
User selects service
    ↓
Check if service exists in /etc/sv/
    ↓
Check if already enabled in /var/service/
    ↓
Create symlink: ln -s /etc/sv/NAME /var/service/
    ↓
runit automatically starts the service
    ↓
Verify service is running
    ↓
Show success/failure message
```

### Disable Flow
```
User selects service
    ↓
Check if service is enabled
    ↓
Stop service: sv stop NAME
    ↓
Remove symlink: rm /var/service/NAME
    ↓
Show success/failure message
```

---

## 🐛 Troubleshooting

### Common Issues

#### "sv: command not found"
**Problem**: runit is not installed  
**Solution**:
```bash
# Void Linux
sudo xbps-install runit

# Artix Linux
sudo pacman -S runit

# Check if installed
which sv
```

#### "Permission denied"
**Problem**: Need sudo for privileged operations  
**Solution**: Run with sudo
```bash
sudo runit-manager --enable service
```

#### "Service not found"
**Problem**: Service doesn't exist in `/etc/sv/`  
**Solution**: Check available services
```bash
runit-manager --list
```

#### "Service is already enabled"
**Problem**: Trying to enable already enabled service  
**Solution**: Check current status
```bash
runit-manager --status service
```

#### "No /var/service directory"
**Problem**: Some distributions use `/run/runit/service/`  
**Solution**: The script auto-detects this, but you can:
```bash
# Check alternative location
ls /run/runit/service/

# Create symlink manually if needed
sudo ln -s /var/service /run/runit/service
```

#### Tab completion not working
**Problem**: Bash completion not installed  
**Solution**: Add completion manually
```bash
# Add to ~/.bashrc
echo 'source /etc/bash_completion.d/runit-manager' >> ~/.bashrc
source ~/.bashrc
```

### Debug Mode

Run with bash debug to see what's happening:
```bash
bash -x runit-manager --list
```
#### Icons are not showing/showing incorecctly
**Problem**: noto-fonts-emoji not installed
**Solution**: 
```bash
# Void Linux
sudo xbps-install -S noto-fonts-emoji

# Artix Linux
sudo pacman -S noto-fonts-emoji
fc-cache -fv
```

### Logs

Check system logs if services aren't starting:
```bash
# View system logs
runit-manager --logs service

# Or view raw logs
tail -f /etc/sv/service/log/current
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### 🐛 Report Issues
- Check existing issues first
- Provide clear reproduction steps
- Include system information

### 💡 Suggest Features
- Open an issue with "Feature Request" label
- Describe the use case
- Explain how it would help

### 🔧 Submit Pull Requests
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit PR with clear description

### 📚 Improve Documentation
- Fix typos or unclear sections
- Add more examples
- Translate to other languages

### Development Setup
```bash
# Clone your fork
git clone https://github.com/timurtom/runit-manager.git
cd runit-manager

# Make changes to runit-manager.sh

# Test locally
./runit-manager.sh --list

# Run installer to test installation
./install.sh
```

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 timurtom

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **runit** - The awesome init system that makes this possible
- **Void Linux** - For popularizing runit on Linux
- **Artix Linux** - For providing a runit option
- **All contributors** - Who help improve this tool

---

## 📚 Related Resources

- [runit Documentation](http://smarden.org/runit/)
- [Void Linux Handbook](https://docs.voidlinux.org/)
- [Artix Linux Wiki](https://wiki.artixlinux.org/)
- [runit Service Management Guide](https://www.troubleshooters.com/linux/runit/)

---

## ⭐ Support

If you find this tool useful:
- ⭐ Star the repository on GitHub
- 🐦 Share it with others
- 📝 Write about it
- 💬 Spread the word in forums

---

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/timurtom/runit-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/timurtom/runit-manager/discussions)

---

**Made with ❤️ for the runit community**

---

*Last Updated: 29.08.2026*
