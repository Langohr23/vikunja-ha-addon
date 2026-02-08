# Vikunja Home Assistant Add-on

This project provides a [Home Assistant](https://www.home-assistant.io/) Add-on for [Vikunja](https://vikunja.io/), the open-source to-do app. It runs Vikunja (API + Frontend) with an SQLite database in a single container.

## Features

- **All-in-One**: Runs both the Vikunja API and Frontend.
- **SQLite Database**: Lightweight and easy to backup (no separate database container required).
- **Home Assistant Integration**: Installs directly as an Add-on.

## Installation / Deployment

### Prerequisites
- A running instance of Home Assistant OS or Supervised.

### Steps to Install

1.  **Add Repository**:
    - Go to your Home Assistant instance.
    - Navigate to **Settings** -> **Add-ons** -> **Add-on Store**.
    - Click the three dots in the top right corner and select **Repositories**.
    - Add the URL of this GitHub repository: `https://github.com/Langohr23/vikunja-ha-addon`
    - Click **Add**.

2.  **Install Add-on**:
    - Reload the Add-on Store (if necessary).
    - Find "Vikunja All-in-One" in the list.
    - Click on it and select **Install**.

3.  **Configuration**:
    - Once installed, go to the **Configuration** tab.
    - Review the default options. The `PublicURL` should match your Home Assistant URL (e.g., `http://homeassistant.local:8123` or your external URL).
    - Save any changes.

4.  **Start**:
    - Go to the **Info** tab and click **Start**.
    - Check the **Log** tab to ensure the service starts correctly.
    - Once running, click **Open Web UI** to access Vikunja.

## First Time Setup

When you access Vikunja for the first time, you'll need to create your admin account:

1. **No Default Credentials**: Vikunja doesn't come with pre-configured username/password.
2. **Register Your Admin Account**:
   - Click on **"Register"** or **"Sign up"** on the Vikunja web interface.
   - Choose your username, email, and password.
   - The first user to register automatically becomes an administrator.
3. **Optional - Disable Public Registration**:
   - After creating your admin account, you can disable public registration for security.
   - Go to the Add-on **Configuration** tab and set `EnableRegistration` to `false`.
   - Restart the add-on for the changes to take effect.

## Configuration Options

| Option | Description | Default |
| :--- | :--- | :--- |
| `PublicURL` | The public URL of your Vikunja instance. | `http://homeassistant.local:3456` |
| `EnableRegistration` | Allow new users to register accounts. Set to `false` after creating your admin account for security. | `true` |

## Support

If you encounter issues, please check the Add-on logs and report bugs in the [Issues](https://github.com/Langohr23/vikunja-ha-addon/issues) section of this repository.
