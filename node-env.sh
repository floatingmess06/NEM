#!/usr/bin/env bash

set -e

NODE_ENV_HOME="$HOME/.node-environments"
GLOBAL_PACKAGES="$NODE_ENV_HOME/.global_packages"

check_nvm() {
    if ! command -v nvm &> /dev/null; then
        echo "Error: nvm (Node Version Manager) is not found."
        echo "Please install nvm or ensure it's properly loaded in your shell."
        echo "You can install nvm from: https://github.com/nvm-sh/nvm"
        echo "After installation, you may need to restart your terminal or run:"
        echo "  source ~/.nvm/nvm.sh"
        exit 1
    fi
}

# Function to download and install Node.js
install_node() {
    local version=$1
    local install_dir=$2
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    local url

    case $arch in
        x86_64)
            arch="x64"
            ;;
        aarch64 | arm64)
            arch="arm64"
            ;;
        *)
            echo "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    url="https://nodejs.org/dist/v${version}/node-v${version}-${os}-${arch}.tar.gz"
    
    echo "Downloading Node.js v${version}..."
    curl -sL "$url" | tar xz -C "$install_dir" --strip-components=1
    
    echo "Node.js v${version} installed in $install_dir"
}


create_environment() {
    local env_name="$1"
    local node_version="$2"
    local env_path="$NODE_ENV_HOME/$env_name"
    
    if [ -d "$env_path" ]; then
        echo "Environment '$env_name' already exists."
        exit 1
    fi
    
    mkdir -p "$env_path/node_modules"
    mkdir -p "$GLOBAL_PACKAGES/node_modules"
    
    if [ -n "$node_version" ]; then
        echo "$node_version" > "$env_path/.node-version"
        install_node "$node_version" "$env_path"
    else
        node --version | sed 's/^v//' > "$env_path/.node-version"
        node_version=$(cat "$env_path/.node-version")
        install_node "$node_version" "$env_path"
    fi
    
    echo "{}" > "$env_path/package.json"
    echo "{}" > "$GLOBAL_PACKAGES/package.json"
    
    echo "Created environment '$env_name' with Node $(cat "$env_path/.node-version")"
}


activate_environment() {
    local env_name="$1"
    local env_path="$NODE_ENV_HOME/$env_name"
    
    if [ ! -d "$env_path" ]; then
        echo "Environment '$env_name' does not exist."
        exit 1
    fi
    
    local node_version=$(cat "$env_path/.node-version")
    
    export PATH="$env_path/bin:$env_path/node_modules/.bin:$GLOBAL_PACKAGES/node_modules/.bin:$PATH"
    export NODE_PATH="$env_path/node_modules:$GLOBAL_PACKAGES/node_modules"
    export NODE_ENV_ACTIVE="$env_name"
    
    echo "Activated environment '$env_name' with Node $node_version"
}

deactivate_environment() {
    if [ -z "$NODE_ENV_ACTIVE" ]; then
        echo "No active environment to deactivate."
        return
    fi
    
    local env_path="$NODE_ENV_HOME/$NODE_ENV_ACTIVE"
    local old_path=$PATH
    export PATH=$(echo $old_path | sed -E "s|$env_path/bin:$env_path/node_modules/.bin:$GLOBAL_PACKAGES/node_modules/.bin:||")
    unset NODE_PATH
    unset NODE_ENV_ACTIVE
    echo "Deactivated environment"
}

install_package() {
    local env_name="$1"
    local package="$2"
    local global_flag="$3"
    local install_path
    local npm_path
    
    if [ "$global_flag" = "--global" ]; then
        install_path="$GLOBAL_PACKAGES"
        npm_path="$NODE_ENV_HOME/$env_name/bin/npm"
        echo "Installing $package globally"
    else
        install_path="$NODE_ENV_HOME/$env_name"
        npm_path="$install_path/bin/npm"
        if [ ! -d "$install_path" ]; then
            echo "Environment '$env_name' does not exist."
            exit 1
        fi
        echo "Installing $package in environment '$env_name'"
    fi
    
    (cd "$install_path" && "$npm_path" install "$package")
    echo "Installed $package"
}

uninstall_package() {
    local env_name="$1"
    local package="$2"
    local global_flag="$3"
    local uninstall_path
    
    if [ "$global_flag" = "--global" ]; then
        uninstall_path="$GLOBAL_PACKAGES"
        echo "Uninstalling $package globally"
    else
        uninstall_path="$NODE_ENV_HOME/$env_name"
        if [ ! -d "$uninstall_path" ]; then
            echo "Environment '$env_name' does not exist."
            exit 1
        fi
        echo "Uninstalling $package from environment '$env_name'"
    fi
    
    (cd "$uninstall_path" && npm uninstall "$package")
    echo "Uninstalled $package"
}

clone_environment() {
    local source_env="$1"
    local target_env="$2"
    local source_path="$NODE_ENV_HOME/$source_env"
    local target_path="$NODE_ENV_HOME/$target_env"
    
    if [ ! -d "$source_path" ]; then
        echo "Source environment '$source_env' does not exist."
        exit 1
    fi
    
    if [ -d "$target_path" ]; then
        echo "Target environment '$target_env' already exists."
        exit 1
    fi
    
    cp -R "$source_path" "$target_path"
    echo "Cloned environment '$source_env' to '$target_env'"
}

list_environments() {
    echo "Available environments:"
    
    for env in "$NODE_ENV_HOME"/*; do
        if [ -d "$env" ] && [ "$(basename "$env")" != ".global_packages" ]; then
            local env_name=$(basename "$env")
            local env_path="$NODE_ENV_HOME/$env_name"
            local node_version=$(cat "$env_path/.node-version")
            echo "- $env_name (Node $node_version)"
        fi
    done
}

list_packages() {
    local env_name="$1"
    local global_flag="$2"
    local list_path
    
    if [ "$global_flag" = "--global" ]; then
        list_path="$GLOBAL_PACKAGES"
        echo "Global packages:"
    else
        list_path="$NODE_ENV_HOME/$env_name"
        if [ ! -d "$list_path" ]; then
            echo "Environment '$env_name' does not exist."
            exit 1
        fi
        echo "Packages in environment '$env_name':"
    fi
    
    (cd "$list_path" && npm list --depth=0)
}

link_global_package() {
    local env_name="$1"
    local package="$2"
    local env_path="$NODE_ENV_HOME/$env_name"
    local global_package_path="$GLOBAL_PACKAGES/node_modules/$package"
    
    if [ ! -d "$env_path" ]; then
        echo "Environment '$env_name' does not exist."
        exit 1
    fi
    
    if [ ! -d "$global_package_path" ]; then
        echo "Global package '$package' is not installed."
        exit 1
    fi
    
    local link_path="$env_path/node_modules/$package"
    
    if [ -e "$link_path" ]; then
        echo "Package '$package' is already linked or installed in environment '$env_name'."
        exit 1
    fi
    
    ln -s "$global_package_path" "$link_path"
    echo "Linked global package '$package' to environment '$env_name'"
}

unlink_global_package() {
    local env_name="$1"
    local package="$2"
    local env_path="$NODE_ENV_HOME/$env_name"
    local link_path="$env_path/node_modules/$package"
    
    if [ ! -d "$env_path" ]; then
        echo "Environment '$env_name' does not exist."
        exit 1
    fi
    
    if [ ! -L "$link_path" ]; then
        echo "Package '$package' is not linked in environment '$env_name'."
        exit 1
    fi
    
    rm "$link_path"
    echo "Unlinked global package '$package' from environment '$env_name'"
}

list_linked_packages() {
    local env_name="$1"
    local env_path="$NODE_ENV_HOME/$env_name"
    
    if [ ! -d "$env_path" ]; then
        echo "Environment '$env_name' does not exist."
        exit 1
    fi
    
    echo "Linked global packages in environment '$env_name':"
    find "$env_path/node_modules" -type l -exec basename {} \;
}

case "$1" in
    create)
        create_environment "$2" "$3"
        ;;
    activate)
        activate_environment "$2"
        ;;
    deactivate)
        deactivate_environment
        ;;
    install)
        install_package "$2" "$3" "$4"
        ;;
    uninstall)
        uninstall_package "$2" "$3" "$4"
        ;;
    clone)
        clone_environment "$2" "$3"
        ;;
    list)
        list_environments
        ;;
    list-packages)
        list_packages "$2" "$3"
        ;;
    link)
        link_global_package "$2" "$3"
        ;;
    unlink)
        unlink_global_package "$2" "$3"
        ;;
    list-linked)
        list_linked_packages "$2"
        ;;
    *)
        echo "Usage: $0 {create|activate|deactivate|install|uninstall|clone|list|list-packages|link|unlink|list-linked} [args...]"
        echo "  create <env_name> [node_version]"
        echo "  activate <env_name>"
        echo "  deactivate"
        echo "  install <env_name> <package> [--global]"
        echo "  uninstall <env_name> <package> [--global]"
        echo "  clone <source_env> <target_env>"
        echo "  list"
        echo "  list-packages <env_name> [--global]"
        echo "  link <env_name> <global_package>"
        echo "  unlink <env_name> <global_package>"
        echo "  list-linked <env_name>"
        exit 1
        ;;
esac
