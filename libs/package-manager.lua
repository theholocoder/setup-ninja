local fs = require("libs.filesystem")
local sys = require("libs.system")
local config = require("libs.config")

local M = {}

local get_package_manager = function(distro)
  if distro == "arch" then
    if sys.command_exists("yay") then
      return "yay -S --needed"
    else
      return "sudo pacman -S --needed"
    end
  elseif distro == "debian" then
    return "sudo apt install -y"
  elseif distro == "fedora" then
    return "sudo dnf install -y"
  end
  return nil
end

-- Package management functions
local update_package_lists = function(distro)
  if config.dry_run then
    print("[DRY RUN] Would update package lists for " .. distro)
    return
  end

  print("Updating package lists...")
  if distro == "debian" then
    sys.execute_command("sudo apt update")
  elseif distro == "arch" then
    sys.execute_command("sudo pacman -Sy")
  elseif distro == "fedora" then
    sys.execute_command("sudo dnf check-update")
  else
    print("No update command defined for " .. distro)
  end
end

local load_packages = function(filename)
  if not fs.file_exists(filename) then
    error("Config file '" .. filename .. "' not found!")
  end

  local success, packages = pcall(dofile, filename)
  if not success then
    error("Error loading config file: " .. packages)
  end

  return packages
end

--- Executes pre/post-install commands for a package
--- @param commands table|nil: Array of commands to execute
--- @param stage string: "pre" or "post" for logging
--- @param package_name string: Name of the package for logging
--- @return boolean: Returns true if all commands succeeded
local execute_commands = function(commands, stage, package_name)
  if not commands or type(commands) ~= "table" then
    return true
  end

  for _, command in ipairs(commands) do
    if config.dry_run then
      print(string.format("  [DRY RUN] Would execute %s-install: %s", stage, command))
    else
      print(string.format("  Executing %s-install command: %s", stage, command))
      if not sys.execute_command(command) then
        print(string.format("  ⚠️  Failed to execute %s-install command for %s", stage, package_name))
        return false
      end
    end
  end
  return true
end

M.install_packages = function(distro)
  local package_manager = get_package_manager(distro)
  if not package_manager then
    error("No package manager found for " .. distro)
  end

  local packages = load_packages(config.config_file)

  update_package_lists(distro)

  print("")
  if config.dry_run then
    print("=== DRY RUN MODE - No packages will be installed ===")
    print("Package manager would be: " .. package_manager)
  else
    print("=== Installing packages ===")
    print("Using package manager: " .. package_manager)
  end
  print("")

  local install_count = 0
  local skip_count = 0
  local command_failures = 0

  -- Sort packages by name for consistent output
  local sorted_names = {}
  for name in pairs(packages) do
    table.insert(sorted_names, name)
  end
  table.sort(sorted_names)

  for _, name in ipairs(sorted_names) do
    local pkg_info = packages[name]
    local package_name = pkg_info[distro]

    if package_name then
      if config.dry_run then
        print(string.format("[DRY RUN] Would install: %s -> %s (%s)",
          name, package_name, pkg_info.description or ""))

        -- Show pre-install commands in dry run
        if pkg_info.pre_install and pkg_info.pre_install[distro] then
          print("  Pre-install commands:")
          execute_commands(pkg_info.pre_install[distro], "pre", name)
        end

        print("  [DRY RUN] Would execute: " .. package_manager .. " " .. package_name)

        -- Show post-install commands in dry run
        if pkg_info.post_install and pkg_info.post_install[distro] then
          print("  Post-install commands:")
          execute_commands(pkg_info.post_install[distro], "post", name)
        end

        install_count = install_count + 1
      else
        print(string.format("Installing %s (%s)...", name, package_name))

        -- Execute pre-install commands
        local pre_success = true
        if pkg_info.pre_install and pkg_info.pre_install[distro] then
          pre_success = execute_commands(pkg_info.pre_install[distro], "pre", name)
        end

        if pre_success then
          -- Install the package
          local cmd = package_manager .. " " .. package_name
          if sys.execute_command(cmd) then
            -- Execute post-install commands
            local post_success = true
            if pkg_info.post_install and pkg_info.post_install[distro] then
              post_success = execute_commands(pkg_info.post_install[distro], "post", name)
            end

            if post_success then
              install_count = install_count + 1
            else
              print("  ⚠️  Package installed but post-install commands failed for " .. name)
              command_failures = command_failures + 1
            end
          else
            print("  ⚠️  Failed to install " .. package_name)
          end
        else
          print("  ⚠️  Pre-install commands failed for " .. name .. ", skipping package installation")
          command_failures = command_failures + 1
        end
      end
    else
      print(string.format("  ⚠️  No package mapping found for %s on %s", name, distro))
      skip_count = skip_count + 1
    end
  end

  print("")
  print("=== Summary ===")
  if config.dry_run then
    print("Would install: " .. install_count .. " packages")
  else
    print("Installed: " .. install_count .. " packages")
  end
  if skip_count > 0 then
    print("Skipped: " .. skip_count .. " packages")
  end
  if command_failures > 0 then
    print("Command failures: " .. command_failures .. " packages")
  end
end

return M
