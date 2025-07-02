set -e

if ! command -v aws &>/dev/null; then
  echo -e "setup/ubuntu/app-awscli - Installing awscli"

  (
    cd /tmp

    wget -O awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

    # unzip
    unzip awscliv2.zip

    sudo ./aws/install

    rm -rf awscliv2.zip
    rm -rf aws
  )
fi

echo -e "setup/ubuntu/app-awscli - ✓"
