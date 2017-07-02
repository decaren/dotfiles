#
#
# Script to update with pacman
#
clear
echo "Hello $USER"
echo -e "Today is \c ";date
echo -e "Number of user login : \c" ; who | wc -l
echo "Calendar"
cal

# Hostname & Repositories
echo "Enter your host name"
read hostname
echo "You entered: $hostname"
# echo $hostname > /etc/hostname
# echo -e "127.0.0.1 \t $hostname.localdomain \t $hostname" >> /etc/hosts
if false
then

# Users Section
passwd
echo "Enter a username:"
read username
useradd -m -g users -G wheel,storage,power -s /bin/bash $username
passwd $username
visudo

# EFI & Micro Code Section 
mount -t efivarfs efivarfs /sys/firmware/efi/efivarfs
bootctl install
pacman -S intel-ucode
output=$(blkid -s PARTUUID -o value /dev/sda5)
echo "title Arch Linux" > arch.conf
echo "linux /vmlinuz-linux" >> arch.conf
echo "initrd /intel-ucode.img" >>arch.conf
echo "initrd /initramfs-linux.img" >> arch.conf
echo "options root=PARTUUID=$output rw" >> arch.conf

fi

exit 0