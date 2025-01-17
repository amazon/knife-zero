require 'chef/knife'
require 'chef/knife/zero_base'
require 'knife-zero/bootstrap_ssh'

class Chef
  class Knife
    class ZeroChefClient < Chef::Knife::BootstrapSsh
      include Chef::Knife::ZeroBase
      deps do
        require 'chef/run_list/run_list_item'
        Chef::Knife::BootstrapSsh.load_deps
        require "knife-zero/helper"
      end

      banner "knife zero chef_client QUERY (options) | It's same as converge"

      self.options = Ssh.options.merge(self.options)
      self.options[:use_sudo_password] = Bootstrap.options[:use_sudo_password]


      option :use_sudo,
        :long => "--[no-]sudo",
        :description => "Execute the chef-client via sudo (true by default)",
        :boolean => true,
        :default => true,
        :proc => lambda { |v| Chef::Config[:knife][:use_sudo] = v }


      option :override_runlist,
        :short        => "-o RunlistItem,RunlistItem...",
        :long         => "--override-runlist RunlistItem,RunlistItem...",
        :description  => "Replace current run list with specified items for a single run. It skips save node.json on local",
        :default => nil,
        :proc => lambda { |o| o.to_s }


      def initialize(argv=[])
        super
        self.configure_chef
        @name_args = [@name_args[0], start_chef_client]
      end

      def start_chef_client
        client_path = @config[:use_sudo] || Chef::Config[:knife][:use_sudo] ? 'sudo ' : ''
        client_path = @config[:chef_client_path] ? "#{client_path}#{@config[:chef_client_path]}" : "#{client_path}chef-client"
        s = "#{client_path}"
        s << ' -l debug' if @config[:verbosity] and @config[:verbosity] >= 2
        s << " -S http://127.0.0.1:#{::Knife::Zero::Helper.zero_remote_port}"
        s << " -o #{@config[:override_runlist]}" if @config[:override_runlist]
        s << " -W" if @config[:why_run]
        Chef::Log.info "Remote command: " + s
        s
      end
    end
  end
end
