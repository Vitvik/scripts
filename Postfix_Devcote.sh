#!/bin/bash

# Update and install packages
sudo yum update -y
sudo yum install -y postfix dovecot

# Configure Postfix
sudo postconf -e 'home_mailbox = Maildir/'
sudo postconf -e 'mail_spool_directory = /var/mail/'
sudo postconf -e 'virtual_alias_maps = hash:/etc/postfix/virtual'
sudo postconf -e 'virtual_mailbox_domains = hash:/etc/postfix/vmailbox_domains'
sudo postconf -e 'virtual_mailbox_maps = hash:/etc/postfix/vmailbox'
sudo postconf -e 'virtual_mailbox_base = /var/mail/vhosts'
sudo postconf -e 'virtual_uid_maps = static:5000'
sudo postconf -e 'virtual_gid_maps = static:5000'
sudo postconf -e 'smtpd_banner = $myhostname ESMTP $mail_name'
sudo postconf -e 'myhostname = stratos.xfusioncorp.com'
sudo postconf -e 'mydestination = localhost'
sudo postconf -e 'relay_domains ='
sudo postconf -e 'mynetworks = 127.0.0.0/8'
sudo postconf -e 'inet_interfaces = all'

# Create user and set up Maildir
sudo useradd jim
echo 'jim:Rc5C9EyvbU' | sudo chpasswd
sudo mkdir -p /home/jim/Maildir
sudo chown -R jim:jim /home/jim/Maildir
sudo chmod -R 700 /home/jim/Maildir

# Set up virtual domain and mailbox
echo "stratos.xfusioncorp.com OK" | sudo tee /etc/postfix/vmailbox_domains
echo "jim@stratos.xfusioncorp.com jim/Maildir/" | sudo tee /etc/postfix/vmailbox
sudo postmap /etc/postfix/vmailbox_domains
sudo postmap /etc/postfix/vmailbox

# Configure Dovecot
sudo sed -i 's/^#mail_location =.*/mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i 's/^#listen =.*/listen = */' /etc/dovecot/dovecot.conf
sudo sed -i 's/^#disable_plaintext_auth = yes/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^auth_mechanisms = plain/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#ssl = required/ssl = no/' /etc/dovecot/conf.d/10-ssl.conf

# Start and enable services
sudo systemctl enable postfix dovecot
sudo systemctl restart postfix dovecot

echo "Postfix and Dovecot installation and configuration completed."
