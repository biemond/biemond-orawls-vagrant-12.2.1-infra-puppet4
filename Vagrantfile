# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "jrf2admin2" , primary: true do |jrf2admin2|

    jrf2admin2.vm.box = "centos-7-1511-x86_64"
    jrf2admin2.vm.box_url = "https://dl.dropboxusercontent.com/s/filvjntyct1wuxe/centos-7-1511-x86_64.box"

    jrf2admin2.vm.provider :vmware_fusion do |v, override|
      override.vm.box = "centos-7-1511-x86_64-vmware"
      override.vm.box_url = "https://dl.dropboxusercontent.com/s/h5g5kqjrzq5dn53/centos-7-1511-x86_64-vmware.box"
      #override.vm.box = "OEL7_2-x86_64-vmware"
      #override.vm.box_url = "https://dl.dropboxusercontent.com/s/ymr62ku2vjjdhup/OEL7_2-x86_64-vmware.box"
    end

    jrf2admin2.vm.hostname = "jrf2admin2.example.com"
    jrf2admin2.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    jrf2admin2.vm.synced_folder "/Users/edwinbiemond/software", "/software"

    jrf2admin2.vm.network :private_network, ip: "10.10.10.21"

    jrf2admin2.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2548"]
      vb.customize ["modifyvm", :id, "--name"  , "jrf2admin2"]
      vb.customize ["modifyvm", :id, "--cpus"  , 2]
    end

    jrf2admin2.vm.provider :vmware_fusion do |vb|
      vb.vmx["numvcpus"] = "2"
      vb.vmx["memsize"] = "2548"
    end

    jrf2admin2.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppetlabs/code/hiera.yaml;rm -rf /etc/puppetlabs/code/modules;ln -sf /vagrant/puppet/environments/development/modules /etc/puppetlabs/code/modules"

    jrf2admin2.vm.provision :puppet do |puppet|
      puppet.environment_path     = "puppet/environments"
      puppet.environment          = "development"

      puppet.manifests_path       = "puppet/environments/development/manifests"
      puppet.manifest_file        = "site.pp"

      puppet.options           = [
                                  '--verbose',
                                  '--report',
                                  '--trace',
                                  # '--debug',
#                                  '--parser future',
                                  '--strict_variables',
                                  '--hiera_config /vagrant/puppet/hiera.yaml'
                                 ]
      puppet.facter = {
        "environment"     => "development",
        "vm_type"         => "vagrant",
      }

    end

  end

  config.vm.define "wlsdb" , primary: true do |wlsdb|

    wlsdb.vm.box = "OEL7_2-x86_64"
    wlsdb.vm.box_url = "https://dl.dropboxusercontent.com/s/0yz6r876qkps68i/OEL7_2-x86_64.box"

    wlsdb.vm.provider :vmware_fusion do |v, override|
      override.vm.box = "OEL7_2-x86_64-vmware"
      override.vm.box_url = "https://dl.dropboxusercontent.com/s/ymr62ku2vjjdhup/OEL7_2-x86_64-vmware.box"
    end

    wlsdb.vm.hostname = "wlsdb.example.com"
    wlsdb.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    wlsdb.vm.synced_folder "/Users/edwinbiemond/software", "/software"

    wlsdb.vm.network :private_network, ip: "10.10.10.5"

    wlsdb.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm"     , :id, "--memory", "2548"]
      vb.customize ["modifyvm"     , :id, "--name"  , "wlsdb"]
      vb.customize ["modifyvm"     , :id, "--cpus"  , 2]
    end

    wlsdb.vm.provider :vmware_fusion do |vb|
      vb.vmx["numvcpus"] = "2"
      vb.vmx["memsize"] = "2548"
    end

    wlsdb.vm.provision :shell, :inline => "mkdir -p /etc/puppet;ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml;rm -rf /etc/puppet/modules;ln -sf /vagrant/puppet/modules /etc/puppet/modules"

    wlsdb.vm.provision :puppet do |puppet|

      puppet.environment_path     = "puppet/environments"
      puppet.environment          = "development"

      puppet.manifests_path       = "puppet/environments/development/manifests"
      puppet.manifest_file        = "db.pp"

      puppet.options           = [
                                  '--verbose',
                                  '--report',
                                  '--trace',
                                  # '--debug',
                                  '--detailed-exitcodes',
                                  '--strict_variables',
                                  '--hiera_config /vagrant/puppet/hiera.yaml'
                                 ]

      puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }

    end

  end

end
