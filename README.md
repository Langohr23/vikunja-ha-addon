# Home Assistant Add-ons Repository

This repository contains multiple [Home Assistant](https://www.home-assistant.io/) Add-ons.

## Available Add-ons

### 1. Vikunja All-in-One
A self-hosted to-do app. Runs Vikunja (API + Frontend) with an SQLite database in a single container.
[Learn more about Vikunja installation](#vikunja-installation)

### 2. Joplin Server All-in-One
A self-hosted synchronization server for [Joplin](https://joplinapp.org/), the open-source note-taking app. Includes an integrated PostgreSQL database.

---

## Vikunja Installation

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

---

## Joplin Server Installation

### Steps to Install

1.  **Add Repository**:
    - If you haven't already, add `https://github.com/Langohr23/vikunja-ha-addon` to your Home Assistant Add-on Store repositories.
2.  **Install Add-on**:
    - Find "Joplin Server All-in-One" in the list.
    - Click on it and select **Install**.
### Joplin Server Setup
1.  **Installation**: Add this repository to Home Assistant and install "Joplin Server".
2.  **Configuration**: Set `APP_BASE_URL` to your external URL (e.g., `https://joplin.yourdomain.com`).
3.  **Email Configuration (Important)**: Joplin requires an email server to change passwords or reset them.
    *   Set `MailerEnabled` to `true`.
    *   Fill in your SMTP details (`MailerHost`, `MailerUser`, etc.).
    *   Set `AdminEmail` to your real email address. The addon will automatically update the admin account's email to this value on start.
4.  **Login**: Use `admin@localhost` (or your configured `AdminEmail`) and password `admin`.
5.  **Change Password**: After setting up the Mailer, you can change the password in the "User" section of the Joplin web UI.

> [!TIP]
> If you don't have an SMTP server, you can use a service like SendGrid, Mailgun, or even a Gmail account (with an App Password).
