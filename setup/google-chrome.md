# Google chrome setup

Get rpm from https://www.google.com/chrome/

Add key

```sh
cd ~/Downloads
wget https://dl.google.com/linux/linux_signing_key.pub
sudo rpm --import linux_signing_key.pub
```

Install with `zypper`:

```sh
sudo zypper in ~/Downloads/google-chrome-*.rpm
```
