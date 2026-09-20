resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  size                = var.vm_size

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.vm.id
    ]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash

    set -e

    export DEBIAN_FRONTEND=noninteractive

    apt-get update

    apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      unzip

    #
    # Install Docker
    #

    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc

    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list

    apt-get update

    apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ${var.admin_username}

    #
    # Install Azure CLI
    #

    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

    #
    # Basic verification
    #

    docker --version
    az --version

    echo "10Alytics VM bootstrap completed" > /var/log/10alytics-bootstrap.log

  EOF
  )

  tags = {
    Project = "10Alytics DevOps Assessment"
  }
}
