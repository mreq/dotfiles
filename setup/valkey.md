# valkey setup

Install with `zypper`:

```sh
sudo zypper install valkey-compat-redis
```

Enable and start service

```sh
sudo su
cp -a /etc/valkey/default.conf.example /etc/valkey/default.conf
chown root:valkey  /etc/valkey/default.conf
chmod u=rw,g=r,o= /etc/valkey/default.conf
install -d -o valkey -g valkey -m 0750 /var/lib/valkey/default/
systemctl start valkey@default
systemctl enable valkey@default
```
