# Redis setup

Install with `zypper`:

```sh
sudo zypper install redis
```

Enable and start service

```sh
sudo su
cp -a /etc/redis/default.conf.example /etc/redis/default.conf
chown root:redis  /etc/redis/default.conf
chmod u=rw,g=r,o= /etc/redis/default.conf
install -d -o redis -g redis -m 0750 /var/lib/redis/default/
systemctl start redis@default
systemctl enable redis@default
```
