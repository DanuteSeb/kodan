#!/bin/bash
for i in $1
do
   echo "===== "$i" pradeda ====="
   ssh mokytoja@$i "sudo apt-get update -y"
   ssh mokytoja@$i "sudo apt-get upgrade -y"
   ssh mokytoja@$i "sudo apt-get dist-upgrade -y"
   ssh mokytoja@$i "sudo apt-get autoremove -y"
   echo "===== "$i" baige ====="
done
