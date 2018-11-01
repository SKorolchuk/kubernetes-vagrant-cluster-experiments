# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-18.04"
    master.vm.provider "hyperv" do |hv|
      hv.vmname = "K8s-master"
      hv.memory = 2048
      hv.maxmemory = 4096
      hv.cpus = 2
      hv.linked_clone = true
    end
    master.vm.synced_folder ".", "/vagrant", type: "rsync",
      rsync__exclude: ".git/"

    master.vm.hostname = "master.localdomain"
    master.vm.provision "shell", path: "disable-swap.sh"
    master.vm.provision "shell", path: "install-docker.sh"
    master.vm.provision "shell", path: "install-k8s.sh"
    master.vm.provision "shell", path: "setup-master.sh"
  end

  config.vm.define "nodea" do |nodea|
    nodea.vm.box = "bento/ubuntu-18.04"
    nodea.vm.provider "hyperv" do |hv|
      hv.vmname = "K8s-nodea"
      hv.memory = 2048
      hv.maxmemory = 4096
      hv.cpus = 2
      hv.linked_clone = true
    end
    nodea.vm.synced_folder ".", "/vagrant", type: "rsync",
      rsync__exclude: ".git/"

    nodea.vm.hostname = "nodea.localdomain"

    nodea.vm.provision "shell", path: "disable-swap.sh"
    nodea.vm.provision "shell", path: "install-docker.sh"
    nodea.vm.provision "shell", path: "install-k8s.sh"
    nodea.vm.provision "shell", inline: "sh /vagrant/tmp/join.sh"
  end

  config.vm.define "nodeb" do |nodeb|
    nodeb.vm.box = "bento/ubuntu-18.04"
    nodeb.vm.provider "hyperv" do |hv|
      hv.vmname = "K8s-nodeb"
      hv.memory = 2048
      hv.maxmemory = 4096
      hv.cpus = 2
      hv.linked_clone = true
    end
    nodeb.vm.synced_folder ".", "/vagrant", type: "rsync",
      rsync__exclude: ".git/"

    nodeb.vm.hostname = "nodeb.localdomain"

    nodeb.vm.provision "shell", path: "disable-swap.sh"
    nodeb.vm.provision "shell", path: "install-docker.sh"
    nodeb.vm.provision "shell", path: "install-k8s.sh"
    nodeb.vm.provision "shell", inline: "sh /vagrant/tmp/join.sh"
  end

  config.vm.define "nodec" do |nodec|
    nodec.vm.box = "bento/ubuntu-18.04"
    nodec.vm.provider "hyperv" do |hv|
      hv.vmname = "K8s-nodec"
      hv.memory = 2048
      hv.maxmemory = 4096
      hv.cpus = 2
      hv.linked_clone = true
    end
    nodec.vm.synced_folder ".", "/vagrant", type: "rsync",
      rsync__exclude: ".git/"

    nodec.vm.hostname = "nodec.localdomain"

    nodec.vm.provision "shell", path: "disable-swap.sh"
    nodec.vm.provision "shell", path: "install-docker.sh"
    nodec.vm.provision "shell", path: "install-k8s.sh"
    nodec.vm.provision "shell", inline: "sh /vagrant/tmp/join.sh"
  end
end