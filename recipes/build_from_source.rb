#
# Cookbook Name:: mesos
# Recipe:: install
#
# Copyright 2013, Shingo Omura
#
# All rights reserved - Do Not Redistribute
#

version = node[:mesos][:version]
prefix = node[:mesos][:prefix]
installed = File.exist?(File.join(prefix, "sbin", "mesos-master"))

if installed then
  Chef::Log.info("Mesos is already installed!! Instllation will be skipped.")
end

include_recipe "mesos::download_source"
include_recipe "java"
include_recipe "python"
include_recipe "build-essential"

# The list is necessary and sufficient?
["libtool", "libltdl-dev", "autoconf", "automake", "libcurl3", "libcurl3-gnutls", "libcurl4-openssl-dev", "python-dev", "libsasl2-dev"].each do |p|
  package p do
    action :install
  end
end

bash "building mesos from source" do
  cwd   File.join("#{node[:mesos][:home]}", "mesos")
  code  <<-EOH
    ./bootstrap
    ./bootstrap
    mkdir -p build
    cd build
    ../configure --prefix=#{prefix}
    make
  EOH
  action :run
  not_if { installed==true }
end

bash "testing mesos" do
  cwd    File.join("#{node[:mesos][:home]}", "mesos", "build")
  code   "make check"
  action :run
  only_if { installed==false && node[:mesos][:build][:skip_test]==false }
end

bash "install mesos to #{prefix}" do
  cwd    File.join("#{node[:mesos][:home]}", "mesos", "build")
  code   <<-EOH
    make install
    ldconfig
  EOH
  action :run
  not_if { installed==true }
end

# configuration files for upstart scripts by build_from_source installation
template "/etc/init/mesos-master.conf" do
  source "upstart.conf.for.buld_from_source.erb"
  variables(:init_state => "stop", :role => "master")
  mode 0644
  owner "root"
  group "root"
end

template "/etc/init/mesos-slave.conf" do
  source "upstart.conf.for.buld_from_source.erb"
  variables(:init_state => "stop", :role => "slave")
  mode 0644
  owner "root"
  group "root"
end

bash "reload upstart configuration" do
  user 'root'
  code 'initctl reload-configuration'
end
