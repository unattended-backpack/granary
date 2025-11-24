# Granary

> Gather the wheat into my barn.

A simple solution for hosting an [attic](https://github.com/unattended-backpack/attic) server. Attic is a binary cache for Nix. We use it in place of all other Nix substituters to maintain control over our supply chain.

## Running

Granary uses a [Makefile](./Makefile) to simplify common operations. The available targets can be viewed by running `make help`. The most common workflow is outlined below.

### Initial Setup

Before running Granary for the first time, you must initialize the configuration files. Run `make init` to create `.env` and `server.toml` from their example templates. This will copy `.env.example` to `.env` and `server.toml.example` to `server.toml`. Both files must be edited to match your environment.

The `.env` file contains secrets such as database credentials, while `server.toml` contains the main server configuration including listening addresses, cache storage paths, and database connection details. Review both files carefully and populate all required fields before proceeding.

### Bootstrapping

Once configuration is complete, start the services with `make`. This command builds the [bootstrap image](./Dockerfile.bootstrap), starts the attic server, and automatically runs the bootstrap process.

The bootstrap container performs the following operations:
1. Generates an administrative token with full permissions including cache creation, configuration, and deletion.
2. Waits for the attic server to become available.
3. Authenticates with the server using the administrative token.
4. Creates the configured cache if it does not already exist.
5. Generates a read-only token suitable for distribution to clients.

The bootstrap process creates two token files in the `./secrets` directory:
- `admin_token`: This token has full administrative permissions. It should be used for privileged operations such as seeding the cache with initial builds or performing administrative tasks. This token must be kept secure and should not be distributed.
- `read_token`: This token has read-only access to the cache. It is suitable for distribution to users who need to pull packages from the cache but should not have write access.

To use the read-only token on a client machine, configure attic with `attic login <name> <server_url> $(cat read_token)`. Replace `<name>` with a descriptive name for this cache and `<server_url>` with the publicly accessible URL of your granary instance.

### Managing Services

To start services in detached mode, run `make granary-d`. To view logs from all services, run `make logs`. To stop all services, run `make stop`. Additional targets are available for rebuilding images, viewing specific service logs, and cleaning up containers and secrets. Run `make help` for a complete list of available commands.

# Security

If you discover any bug; flaw; issue; dæmonic incursion; or other malicious, negligent, or incompetent action that impacts the security of any of these projects please responsibly disclose them to us; instructions are available [here](./SECURITY.md).

# License

The [license](./LICENSE) for all of our original work is `LicenseRef-VPL WITH AGPL-3.0-only`. This includes every asset in this repository: code, documentation, images, branding, and more. You are licensed to use all of it so long as you maintain _maximum possible virality_ and our copyleft licenses.

Permissive open source licenses are tools for the corporate subversion of libre software; visible source licenses are an even more malignant scourge. All original works in this project are to be licensed under the most aggressive, virulently-contagious copyleft terms possible. To that end everything is licensed under the [Viral Public License](./licenses/LicenseRef-VPL) coupled with the [GNU Affero General Public License v3.0](./licenses/AGPL-3.0-only) for use in the event that some unaligned party attempts to weasel their way out of copyleft protections. In short: if you use or modify anything in this project for any reason, your project must be licensed under these same terms.

For art assets specifically, in case you want to further split hairs or attempt to weasel out of this virality, we explicitly license those under the viral and copyleft [Free Art License 1.3](./licenses/FreeArtLicense-1.3).
