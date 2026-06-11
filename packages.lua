-- Example package definitions with pre/post-install commands
return {
  -- Simple package without any commands
  editor = {
    description = "Neovim text editor",
    arch = "neovim",
    fedora = "neovim",
    debian = "neovim"
  },

  -- Package with repository setup (common use case)
  docker = {
    description = "Docker container platform",
    arch = "docker",
    fedora = "docker-ce",
    debian = "docker-ce",
    pre_install = {
      debian = {
        "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
        "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
        "sudo apt update"
      },
      fedora = {
        "sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo"
      }
    },
    post_install = {
      arch = {
        "sudo systemctl enable docker",
        "sudo systemctl start docker",
        "sudo usermod -aG docker $USER"
      },
      fedora = {
        "sudo systemctl enable docker",
        "sudo systemctl start docker",
        "sudo usermod -aG docker $USER"
      },
      debian = {
        "sudo systemctl enable docker",
        "sudo systemctl start docker",
        "sudo usermod -aG docker $USER"
      }
    }
  },

  -- Package with configuration setup
  git = {
    description = "Git version control system",
    arch = "git",
    fedora = "git",
    debian = "git",
    post_install = {
      arch = {
        "git config --global init.defaultBranch main"
      },
      fedora = {
        "git config --global init.defaultBranch main"
      },
      debian = {
        "git config --global init.defaultBranch main"
      }
    }
  },

  -- Package requiring kernel headers (common for drivers)
  virtualbox = {
    description = "VirtualBox virtualization software",
    arch = "virtualbox",
    fedora = "VirtualBox",
    debian = "virtualbox",
    pre_install = {
      arch = {
        "sudo pacman -S --needed linux-headers"
      },
      fedora = {
        "sudo dnf install kernel-devel kernel-headers"
      },
      debian = {
        "sudo apt install linux-headers-$(uname -r)"
      }
    },
    post_install = {
      arch = {
        "sudo modprobe vboxdrv"
      },
      fedora = {
        "sudo /sbin/vboxconfig"
      },
      debian = {
        "sudo modprobe vboxdrv"
      }
    }
  },

  -- Package with PPA setup (Ubuntu/Debian specific)
  vscode = {
    description = "Visual Studio Code editor",
    arch = "visual-studio-code-bin",
    fedora = "code",
    debian = "code",
    pre_install = {
      debian = {
        "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg",
        "sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/",
        "sudo sh -c 'echo \"deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\" > /etc/apt/sources.list.d/vscode.list'",
        "sudo apt update"
      },
      fedora = {
        "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc",
        "sudo sh -c 'echo -e \"[code]\\nname=Visual Studio Code\\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\\nenabled=1\\ngpgcheck=1\\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\" > /etc/yum.repos.d/vscode.repo'"
      }
    }
  }
}
