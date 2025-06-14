# Postgresql setup

Install with `apt`:

```sh
sudo apt install postgresql postgresql-client postgresql-contrib
```

Make a superuser

```sh
sudo su postgres
createuser -s -i -d -r -l -w petr
psql -c "SHOW hba_file;"
```

Edit `pg_hba.conf`` to allow password auth

```sh
sudo nvim /etc/postgresql/16/main/pg_hba.conf
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
