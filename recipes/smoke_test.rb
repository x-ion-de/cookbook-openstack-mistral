#
# Cookbook Name:: openstack-workflow
# Recipe:: smoke_test
#
# Copyright 2017, x-ion

require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

class Chef::Resource::RubyBlock
  include ::Openstack
end

#------------------------------------------------------------------------------
# Install mistral client
apt_update ''

package 'python-mistralclient'
#------------------------------------------------------------------------------
admin_user = node['openstack']['identity']['admin_user']
admin_project = node['openstack']['identity']['admin_project']

workflow_file = '/tmp/mistral-workflow.yaml'

cookbook_file workflow_file do
  source 'mistral-workflow.yaml'
  owner 'root'
  group 'root'
  mode 0444
end

# NOTE: This has to be done in a ruby_block so it gets executed at execution
#       time and not compile time (when nova does not yet exist).
ruby_block 'smoke test for mistral' do
  block do
    begin
      env = openstack_command_env(admin_user, admin_project, 'Default', 'Default')
      puts openstack_command('mistral', "workflow-create #{workflow_file}", env)

      workflow_id = openstack_command('mistral', 'workflow-get my_workflow -cID -fvalue', env).chomp

      puts "workflow_id:#{workflow_id}:"

      # Start the workflow.
      # FIXME openstack_command rips apart arguments containing space and
      #       passes the bits on as individual arguments -> FAIL
      puts openstack_command('mistral', ['execution-create', 'my_workflow', '{"names": ["John", "Mistral", "Ivan", "Crystal"]}'], env)

      execution_list = openstack_command('mistral', 'execution-list', env)

      puts "execution_list:#{execution_list}:"
      puts "execution_list grep:#{execution_list.lines.grep(/#{workflow_id}/)}:"
      puts "execution_list grep[0]:#{execution_list.lines.grep(/#{workflow_id}/)[0]}:"

      execution_id = execution_list.lines.grep(/#{workflow_id}/)[0].split[1].chomp
      puts "execution_id:#{execution_id}:"

      puts openstack_command('mistral', "execution-get #{execution_id}", env)
      puts openstack_command('mistral', "task-list #{execution_id}", env)

      task_list = openstack_command('mistral', 'task-list -cID -cName', env)
      task_id = task_list.lines.grep(/task1/)[0].split[1].chomp
      puts "task_id:#{task_id}:"

      puts openstack_command('mistral', "task-get-result #{task_id}", env)

      puts openstack_command('mistral', "action-execution-list #{task_id}", env)
    end
  end
  # FIXME: replace with better test
  not_if { ::File.exist?(workflow_file) }
end
