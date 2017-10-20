#
# Cookbook:: openstack-workflow
# Recipe:: mistral-server
#
# Copyright 2017, x-ion GmbH

class ::Chef::Recipe
  include ::Openstack # address_for, get_password
end

db_user = node['openstack']['db']['workflowv2']['username']
db_pass = get_password('db', 'mistral')
#------------------------------------------------------------------------------
# Install mistral
apt_update ''

package 'mistral-common'

execute 'register_mistral_endpoint' do
  # FIXME: is this block necessary?
  command 'echo mistral-api mistral/register-endpoint boolean false | sudo debconf-set-selections'
end

package 'mistral-api'
package 'mistral-engine'
package 'mistral-executor'
#------------------------------------------------------------------------------
node.default['openstack']['workflowv2']['conf_secrets']
.[]('database')['connection'] =
  db_uri('workflowv2', db_user, db_pass)

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['workflowv2']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'workflowv2'
end

node.default['openstack']['workflowv2']['conf_secrets']
.[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-workflowv2'

identity_endpoint = public_endpoint 'identity'

auth_url = auth_uri_transform identity_endpoint.to_s, node['openstack']['api']['auth']['version']

node.default['openstack']['workflowv2']['conf'].tap do |conf|
  conf['keystone_authtoken']['auth_url'] = auth_url
end
#------------------------------------------------------------------------------
# Config file

mistral_conf = merge_config_options 'workflowv2'

mistral_conf_file = '/etc/mistral/mistral.conf'

template mistral_conf_file do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  mode 00644
  variables(
    service_config: mistral_conf
  )
end

# FIXME: Looks like a race; without sleeping, mistral-db-manage fails
execute 'sleep' do
  command 'sleep 5'
end

# Use of the auth_admin_prefix, auth_host, auth_port, auth_protocol,
# identity_uri, admin_token, admin_user, admin_password, and admin_tenant_name
# configuration options was deprecated in the Mitaka release in favor of an
# auth_plugin and its related options.
execute 'disable_deprecated_options' do
  command "sed -i 's/^a/#/' #{mistral_conf_file}"
  only_if "grep '^admin_token' #{mistral_conf_file}"
end

execute 'mistral-db-manage_populate' do
  command "mistral-db-manage --config-file #{mistral_conf_file} populate"
end

service 'mistral-engine' do
  # supports status: true, restart: true
  action [:enable, :restart]
end

service 'mistral-executor' do
  # supports status: true, restart: true
  action [:enable, :restart]
end

service 'mistral-api' do
  # supports status: true, restart: true
  action [:enable, :restart]
end
#------------------------------------------------------------------------------
