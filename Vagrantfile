Vagrant::Config.run do |config|
  config.vm.box = "centos-60-x86_64"
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "default.pp"
  end
end
