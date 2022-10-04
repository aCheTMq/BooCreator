# Boo Creator v. 1.0
Copyright © 2022 Baruzdin Alexey

Youtube: https://youtube.com/channel/UChyAYOcXxvjdDU3Blg_mDmg

Dzen: https://zen.yandex.ru/aCheTMq

Github: https://github.com/aCheTMq/BooCreator

Mail: just.so@mail.ru

# Description
This script will help you create a boot disk for installing Windows. The boot disk will work with UEFI and BIOS. Everything is done by built-in Windows tools. No third-party apps.

Also, this script can download the latest available versions of Windows from the Microsoft website.

Be careful, the script displays all connected disks, and allows you to create a boot disk from any disk. When creating a boot disk, all data on the disk is deleted.

# License
GNU General Public License version 3.0 (https://www.gnu.org/licenses/gpl-3.0) or later.

# How to use
1. Run "unlock_ps.cmd" as administrator to specify the PowerShell security policy as "Bypass".
2. Run "BooTreator.ps1". If the script is not run as an administrator, the script will try to run itself as an administrator. If the script failed to run itself as an administrator, do it manually.
Use the script.
3. Run "lock_ps.cmd" as administrator to return the PowerShell security policy to "AllSigned".

# From the author
Don't worry, I have no reason to hurt you. Use my script without fear.
However, again, be careful when choosing a disk to create a boot disk!
Alexey.
