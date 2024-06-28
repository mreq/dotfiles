# Rbenv setup

Make sure `rbenv` is not installed via `apt`

```sh
sudo apt remove rbenv
```

Clone

```
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
```

Clone ruby-build if needed

```
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
```
