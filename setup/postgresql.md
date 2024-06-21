# Postgresql setup

Get rpm from https://www.dropbox.com/install-linux.

Install with `zypper`:

```sh
sudo zypper install postgresql postgresql-contrib postgresql-server postgresql-devel
```

Enable and start service

```sh
systemctl enable postgresql
systemctl start postgresql
```

Make a superuser

```sh
sudo su postgres
createuser -s -i -d -r -l -w petr
```
