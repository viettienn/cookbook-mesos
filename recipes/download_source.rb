#
# Cookbook Name:: mesos
# Recipe:: download_source
#
# Copyright 2013, Shingo Omura
#
# All rights reserved - Do Not Redistribute
#
version = node[:mesos][:version]
home = node[:mesos][:home]

downloaded = File.exist?(File.join(home, "mesos"))
if downloaded then
  Chef::Log.info("Mesos is already downloaded!! Download will be skipped.")
end

package "unzip" do
  action :install
end

download_url = "https://github.com/apache/mesos/archive/#{version}.zip"
remote_file "#{Chef::Config[:file_cache_path]}/mesos-#{version}.zip" do
  source "#{download_url}"
  mode   "0644"
  not_if { downloaded }
end

bash "extracting mesos to #{home}" do
  cwd    "#{home}"
  code   <<-EOH
    unzip -o #{Chef::Config[:file_cache_path]}/mesos-#{version}.zip -d ./
    mv mesos-#{version} mesos
  EOH
  action :run
  not_if { downloaded }
end