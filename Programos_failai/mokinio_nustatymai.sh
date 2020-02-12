#!/bin/sh
umount -l /home/mokinys/Mano_failai_OK
umount -l /home/mokinys/Seni_failai_OK
rm -rf /home/mokinys
cp -r /home/mokytoja/Backups_mokinio/mokinys /home/
chown -R mokytoja:mokinys /home/mokinys/
chmod -R o-rwx /home/mokinys/
chmod -R g+rwx /home/mokinys/
chmod +t /home/mokinys/
chmod -R g-w /home/mokinys/Atsiskaitymai
chmod -R g-w /home/mokinys/Nuo_mokytojos
