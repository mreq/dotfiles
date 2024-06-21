# Slack setup

Get rpm from https://slack.com/downloads/instructions/linux?ddl=1&build=rpm.

Add key

```sh
cd ~/Downloads
wget https://slack.com/gpg/slack_pubkey_20230710.gpg
sudo rpm --import slack_pubkey_20230710.gpg
```

Install with `zypper`:

```sh
sudo zypper install ~/Downloads/slack-*.rpm
```
