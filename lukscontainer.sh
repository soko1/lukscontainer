#!/bin/bash

# author: Sakalou Aliaksei <nullbsd@gmail.com>
# git: https://github.com/soko1/lukscontainer

mapper="lukscontainer"

VER=0.2

function check_prog {
    $1 2>/dev/null
    if [ $? -gt 1 ]; then
         echo "Package '$1' not found. Please install this package in your system." 
         echo "Exiting..."
         exit 1
    fi
}

function check_mount {
        if [ -b /dev/mapper/$mapper ]; then                                                                                
            echo "Container '/dev/mapper/$mapper' is mounted. Please umount this container."                               
            echo "Umount? (y/n)"                                                                                           
            read yesno
            if [ $yesno = "y" ]; then                                                                                      
                give_pass
                echo $pass | sudo -S umount /dev/mapper/$mapper                                                                            
                if [ $? -ne 0 ]; then                                                                                      
                    echo "Umount is error. Please kill all the processes that are using this device."                      
                    exit 1                                                                                                 
                fi                                                                                                         
                echo $pass | sudo -S cryptsetup luksClose /dev/mapper/$mapper
            else                                                                                                           
                echo "Exiting..."                                                                                          
                exit 1                                                                                                     
            fi                                                                                                             
        fi  
}

function check_root { 
    if [ `whoami` != 'root' ]                                                                                              
     then   
         checkpass=0
         root=0
     else
         root=1
    fi 
}

function give_pass {
    if [ $root -ne 1 ]; then
        if [ $checkpass -ne 1 ]; then
            echo "[sudo] password for `whoami`:"
            read -s pass
            checkpass=1
        fi
    fi
}


check_prog cryptsetup
check_prog sudo

check_root 

echo ----------------
echo "1. Create container"
echo "2. Mount container"
echo "3. Umount container"
echo "4. Exit (or Ctrl+c)"
echo "----------------"


read key
case "$key" in
    1 )
        check_mount
        echo "Enter path and file name (example: /home/user/cryptfile)"
        echo "NB! Enter the full path:"
        read path
        echo "Enter file size in MB:"
        read size
        echo "Creating empty file, please wait..."
        dd if=/dev/zero of=$path bs=1M count=$size
        echo "Create crypto contaiter..."
        give_pass
        echo $pass | sudo -S cryptsetup luksFormat $path
        echo "Open Crypto container..."
        echo $pass | sudo -S cryptsetup luksOpen $path $mapper
        echo "Format FS in ext3..."
        echo $pass | sudo -S mkfs.ext3 /dev/mapper/$mapper
        echo "It's OK. Mounting in your new container? (y/n)"
        read yesno
        if [ $yesno = "y" ]; then
              echo "Enter mount point (example: /mnt/crypt)"
              read path_mount
              echo $pass | sudo -S mount /dev/mapper/$mapper $path_mount
              echo "You cryptocontainer mount in $path_mount"
        fi
        ;;
    2 )
        check_mount
        echo "Enter the path of your crypto container file:"
        read path
        echo "Enter mount point (example: /mnt/crypto)"
        read path_mount
        give_pass                                                                                                      
        echo $pass | sudo -S cryptsetup luksOpen $path $mapper
        echo $pass | sudo -S mount /dev/mapper/$mapper $path_mount
        ;;
    3 )
        give_pass
        echo $pass | sudo -S umount /dev/mapper/$mapper
        echo $pass | sudo -S cryptsetup luksClose /dev/mapper/$mapper

        ;;
    4 )
        echo "Exiting..."
        exit
        ;;

    * )
        echo "Error input"
        ;;
esac
