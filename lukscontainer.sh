#!/bin/sh

# author: Sakalou Aliaksei <nullbsd@gmail.com>
# git: https://github.com/soko1/lukscontainer

echo ----------------
echo "1. Create container"
echo "2. Mount container"
echo "3. Umount container"
echo "4. Exit (or Ctrl+c)"
echo "----------------"

mapper="cryptfile"

read key
case "$key" in
    1 )
        echo "| Enter path and file name (example: /home/user/cryptfile)\n| NB! Enter the full path:"
        read path
        echo "| Enter file size in MB:"
        read size
        echo "| Creating empty file, please wait..."
        dd if=/dev/zero of=$path bs=1M count=$size
        echo "| Create crypto contaiter..."
        sudo cryptsetup luksFormat $path
        echo "\n| Open Crypto container..."
        sudo cryptsetup luksOpen $path $mapper
        echo "| Format FS in ext3..."
        sudo mkfs.ext3 /dev/mapper/$mapper
        echo "| It's OK. Mounting in your new container? (y/n)"
        read yesno
        if [ $yesno = "y" ]; then
              echo "| Enter mount point (example: /mnt/crypt)"
              read path_mount
              sudo mount /dev/mapper/$mapper $path_mount
              echo "| You cryptocontainer mount in $path_mount"
        fi
        ;;
    2 )
        echo "| Enter the path of your crypto container file:"
        read path
        echo "| Enter mount point (example: /mnt/crypto)"
        read path_mount
        sudo cryptsetup luksOpen $path $mapper
        sudo mount /dev/mapper/$mapper $path_mount
        ;;
    3 )
        sudo umount /dev/mapper/$mapper
        sudo cryptsetup luksClose /dev/mapper/$mapper

        ;;
    4 )
        echo "Exiting..."
        exit
        ;;

    * )
        echo "Error input"
        ;;
esac
