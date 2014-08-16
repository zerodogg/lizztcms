# vi: set ft=ruby :

# --- LizztCMS INSTRUCTIONS ---
# vagrant up
#   Brings up a LizztCMS vagrant VM
# vagrant ssh -c bin/lizztcms_server
#   Starts the LizztCMS server
# vagrant ssh -c bin/lizztctl ...
#   Runs lizztctl commands
# ---                    ---

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "cargomedia/debian-7-amd64-plain"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  config.ssh.forward_agent = true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  config.vm.provider :virtualbox do |v|
      v.name = "lizztcms-vagrant"
  end

  # Name the machine as vagrant sees it
  config.vm.define :lizztcms do |v|
  end

  # Provisioning of the VM
  config.vm.provision "shell", path: "script/vagrantup.sh", keep_color: true
  config.vm.provision "shell", path: "script/vagrantup.sh", keep_color: true, privileged: false

  # Don't bother checking for box updates
  config.vm.box_check_update = false

  # Message to be displayed after every "vagrant up"
  config.vm.post_up_message = "To start LizztCMS run:\n\tvagrant ssh -c bin/lizztcms_server\nTo run lizztctl run:\n\tvagrant ssh -c bin/vlizztctl ...\nTo get a shell run:\n\tvagrant ssh\n"
end
