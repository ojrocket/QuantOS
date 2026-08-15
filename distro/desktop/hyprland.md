# Hyprland Desktop Baseline

## Default desktop posture

- Wayland-first, no Xorg default session
- Hyprland configured as the primary desktop shell
- modular config layout for monitors, workspaces, keyboard bindings, and appearance
- keyboard-first workflow with documented shortcuts
- privacy-respecting defaults for screenshots, screen recording, and notifications

## Security-specific desktop rules

- no screen sharing without explicit user consent
- no background service with unrestricted clipboard access
- system prompts use polkit approval for privileged tasks
- default wallpaper and application access avoid storing secrets in plain text
- no untrusted shell commands from the desktop by default
