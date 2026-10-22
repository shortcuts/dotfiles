# Mac mini 2018 as a headless Ubuntu agent server

The 2018 Mac mini has a T2 chip. Stock Ubuntu cannot see its SSD.
Use the [t2linux](https://wiki.t2linux.org) ISO, which carries the T2 kernel.
The t2linux project ships desktop flavors only, with no Server ISO.
Install the "Ubuntu" flavor with a minimal install, then remove the desktop.

## What you need

- A USB stick of 8 GB or more.
- A screen and a keyboard for the install only. Borrow them.
- An ethernet cable. Wi-Fi needs extra firmware, and a server does not need it.
- A Mac with internet access to prepare the stick.

## 1. Prepare macOS

1. Restart the mini and hold `Cmd+R` to enter macOS Recovery.
2. Open Utilities → Startup Security Utility.
3. Set **Secure Boot** to **No Security**.
4. Set **Allow Boot Media** to **Allow booting from external or removable media**.
5. Boot macOS and open Disk Utility.
6. Select the internal volume, press Partition, and add a partition for Linux.
7. Give Linux most of the disk. You cannot resize it later from macOS.
8. Keep a small macOS partition. You need it to read the Wi-Fi firmware and to apply firmware updates.

## 2. Flash the ISO

1. Download the ISO from the [T2-Ubuntu releases](https://github.com/t2linux/T2-Ubuntu/releases/latest).
   The t2linux Installer app can also download it.
2. Flash it to the USB stick with balenaEtcher or `dd`.

## 3. Install

1. Plug in the stick and ethernet. Restart and hold `Option`.
2. Pick the "EFI Boot" entry for the stick.
3. Choose **Minimal installation** in the installer. Skip third-party software.
4. At the partition step, choose **Something else**. Never choose automatic partitioning: it erases macOS.
5. Delete only the partition you created in step 1.
6. In the freed space, create one root partition: mount point `/`, format ext4.
7. Leave the EFI partition alone.
8. Finish the installer and remove the stick when it asks.
9. Restart, hold `Option`, and pick "EFI Boot". Ubuntu's GRUB often fails from the Startup Manager.
   If it does, install [rEFInd](https://wiki.t2linux.org/guides/refind/) from macOS.

## 4. Turn it into a server

Run these on the mini, with the screen still attached:

```sh
sudo apt update && sudo apt install -y openssh-server
sudo systemctl set-default multi-user.target
sudo systemctl enable --now ssh
ip -4 addr show
```

- `set-default multi-user.target` boots to a text console and skips the desktop.
- Note the IP address. Give the mini a fixed lease in your router.
- Optional: `sudo apt purge ubuntu-desktop* gnome-shell && sudo apt autoremove` frees the desktop's disk space and RAM.

From your Mac, copy your key and test the connection:

```sh
ssh-copy-id <user>@<mini-ip>
ssh <user>@<mini-ip>
```

Then disable password login: set `PasswordAuthentication no` in `/etc/ssh/sshd_config.d/50-cloud-init.conf` and run `sudo systemctl restart ssh`.
You no longer need the screen.

## 5. Install the dotfiles

```sh
git clone git@github.com:shortcuts/dotfiles.git ~/.config
cd ~/.config
make install linux
```

`install.sh` also tries to restore power after a power cut with `setpci`.
Test it once: unplug the mini, plug it back in, and check that it boots.

## Troubleshooting

- **No SSD in the installer:** you booted a stock Ubuntu ISO. Use the T2-Ubuntu one.
- **No Wi-Fi:** run `get-apple-firmware get_from_macos`, or `get_from_online` over ethernet.
