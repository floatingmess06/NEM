# NEM : A Node.js Environment Manager

NEM is a tool that simplifies managing Node.js environments and packages. It enables you to create, activate, and control multiple environments with distinct Node.js versions and packages. Each environment remains isolated, allowing you to develop and test various projects concurrently without conflicts.

### Features

* **Global Packages Directory:** Stores globally installed packages in a centralized location, accessible from all environments.
* **Linking Feature:** Links global packages to specific environments, facilitating the use of the same package across multiple environments without redundant installations.
* **Environment Deactivation:** Removes an environment from your system's PATH and unsets the `NODE_PATH` environment variable when you deactivate it.
* **Package Uninstallation:** Uninstalls a package from either a specific environment or globally.
* **Environment Cloning:** Creates a duplicate of an existing environment, including its Node.js version.
* **Version Management for Node.js:** Each environment stores its Node.js version within a `.nvmrc` file, enabling effortless switching between different versions.

### Technical Details

* **Environment Structure:** Each environment resides in a separate directory within `~/.node-environments/`.
* **Package Installation:** Packages are installed in the `node_modules` subdirectory of each environment using `npm install`.
* **Error Handling:** The script incorporates basic error handling to verify the existence or non-existence of environments.
* **Integration with nvm:** This script leverages nvm to manage Node.js versions.

### Commands

The script offers a range of commands:

* `node-env create myenv 14.17.0`: Creates an environment with a specific Node.js version (e.g., 14.17.0).
* `source node-env activate myenv`: Activates a designated environment.
* `node-env install myenv express`: Installs a package (e.g., `express`) in a particular environment.
* `node-env uninstall myenv express`: Uninstalls a package from a specific environment.
* `node-env list-packages myenv`: Retrieves a list of packages installed in an environment.
* `node-env clone myenv myenv-clone`: Creates a copy of an existing environment.
* `source node-env deactivate`: Deactivates the currently active environment.
* `node-env install myenv typescript --global`: Installs a package globally for use in all environments.
* `node-env uninstall myenv typescript --global`: Uninstalls a global package.
* `node-env list-packages myenv --global`: Lists packages installed globally.

### Setup

1. **Clone the Repository:**
   ```bash
   git clone [https://github.com/floatingmess06/NEM.git](https://github.com/floatingmess06/NEM.git)
   ```

2. **Navigate to the Cloned Directory:**
   ```bash
   cd NEM
   ```

3. **Make the Script Executable:**
   ```bash
   chmod +x node-env.sh
   ```

4. **Move the Script to Your PATH:**
   ```bash
   sudo mv node-env.sh /usr/local/bin/node-env
   ```

5. **Create a Base Directory for Environments** (Optional - the script creates this if needed)

   The script utilizes `$HOME/.node-environments/` as the default base directory.

**Note:** This script necessitates the installation and configuration of `nvm` on your system.

### Contributing
Contributions, issues, and feature requests are welcome. Feel free to check [issues page](https://github.com/floatingmess06/NEM/issues) if you want to contribute.
