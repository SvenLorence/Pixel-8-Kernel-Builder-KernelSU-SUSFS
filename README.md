<img src="https://raw.githubusercontent.com/lipis/flag-icons/refs/heads/main/flags/4x3/us.svg" height="14" /> `English` | [<img src="https://raw.githubusercontent.com/lipis/flag-icons/refs/heads/main/flags/4x3/ru.svg" height="14" /> Русский](README_ru.md)

# Pixel 8/Pro Kernel Builder: KernelSU & SUSFS

### ⚠️ Warning
As stated in the MIT License (see `LICENSE` file) - the software is provided "AS IS". No warranties. If your phone bricks or goes into a bootloop, the authors are not responsible. No complaints accepted, you do everything entirely at your own risk.

### ⚙️ Features
Custom kernel build with the following integrations:
- **Root**: KernelSU
- **SUSFS**: patched to hide root
- **Baseband-guard**: LSM module blocking unauthorized writes to critical partitions (modem/baseband protection)
- **Custom manager signature**: a manager with package and app name spoofing; get it here: [SvenLorence/KernelSU](https://github.com/SvenLorence/KernelSU)

Supports building for Stable and Beta firmware.

### 🛠️ Building Locally
Before building, it is highly recommended to read the help output and configure `Variables.conf`.
```sh
./build_ksu.sh --help
```

To build the kernel locally, use the \`build_ksu.sh\` script:
```sh
./build_ksu.sh --stable|--beta --ksu
```

### ⚡ How to flash (Installation)
1. Download the appropriate `boot.img` from the releases.
2. Open a terminal in the folder containing the downloaded file.
3. Reboot your phone into bootloader mode and connect it to your PC.
4. Perform a test boot to verify the kernel works:
```sh
fastboot boot boot.img
```
5. If the system boots successfully, reboot back into bootloader and flash permanently:
```sh
fastboot flash boot boot.img
fastboot reboot
```