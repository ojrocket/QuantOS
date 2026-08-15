# QuantOS Fedora Kickstart
# Intended for Fedora 40+ live ISO creation and installation automation.

lang en_US.UTF-8
keyboard us
timezone UTC --utc
selinux --enforcing
firewall --enabled --ssh
services --enabled=NetworkManager,sshd
rootpw --lock
user --name=quantos --groups=wheel --plaintext --password=QuantOS123!
network --bootproto=dhcp --device=link --activate
zerombr
clearpart --all --initlabel
autopart --type=lvm
bootloader --location=mbr --append="quiet rhgb mitigations=auto audit=1"

# Base system
%packages
@core
@base-x
@fonts
@networkmanager-submodules
@multimedia
@hardware-support
@development-tools
audit
firewalld
gdb
git
jq
kitty
dolphin
firefox
hyprland
pipewire
pipewire-pulsaudio
wireplumber
NetworkManager
NetworkManager-wifi
selinux-policy-targeted
polkit
sudo
util-linux
curl
wget
gnome-keyring
nss-tools
flatpak
podman
qemu-kvm
%end

%post --log=/root/quantos-post.log
set -eux

# Harden the system by default.
cat > /etc/dnf/dnf.conf <<'EOF'
[main]
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
gpgcheck=1
repo_gpgcheck=1
metadata_expire=7d
EOF

# Ensure passwordless admin delegation is not enabled.
if [ -f /etc/sudoers.d/99-quantos ]; then
    rm -f /etc/sudoers.d/99-quantos
fi

# Use a secure default policy for privilege escalation.
cat > /etc/sudoers.d/99-quantos-policy <<'EOF'
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
%wheel ALL=(ALL) ALL
EOF
chmod 0440 /etc/sudoers.d/99-quantos-policy

# Prevent root login and enforce trusted package signing.
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config || true
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config || true
systemctl enable sshd
systemctl enable firewalld
systemctl enable NetworkManager

# Enable secure defaults for the desktop and package manager.
mkdir -p /etc/quantos
cat > /etc/quantos/defaults.conf <<'EOF'
DESKTOP=hyprland
SECURITY_MODE=selinux-enforcing
FIREWALL=enabled
ROLLBACK=atomic
EOF

# Set a secure default umask for user sessions.
cat > /etc/profile.d/quantos-secure.sh <<'EOF'
export UMASK=027
umask 027
EOF
chmod 0644 /etc/profile.d/quantos-secure.sh

# Initialize policy for user environment.
mkdir -p /var/lib/quantos
printf '%s\n' 'QuantOS secure baseline initialized' > /var/lib/quantos/build-marker

# Ensure the default user has a valid shell and can use sudo.
usermod -aG wheel quantos
usermod -s /bin/bash quantos
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
