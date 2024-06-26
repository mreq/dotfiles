# Postgresql setup

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

Edit `pg_hba.conf`` to allow password auth

```sh
sudo nvim /var/lib/pgsql/data/pg_hba.conf
```

add the following above the ident method:

```
host    all             all             localhost               password
```

Example after:

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             localhost               password
host    all             all             127.0.0.1/32            ident
# IPv6 local connections:
host    all             all             ::1/128                 ident
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            ident
host    replication     all             ::1/128                 ident
```
