default['openstack']['common']['services']['workflowv2'] = 'mistral'

default['openstack']['workflowv2']['syslog']['use'] = false

# Versions for OpenStack release
# Ocata:
# https://releases.openstack.org/teams/mistral.html
# default['openstack-workflow']['mistral_server_version'] = '4.0.0'
# Pike:
default['openstack-workflow']['mistral_server_version'] = '5.0.0'

default['openstack']['workflowv2']['service_role'] = 'service'

# ************** OpenStack Key Manager Endpoints ************************

# The OpenStack Key Manager (Mistral) endpoints
%w(public internal admin).each do |ep_type|
  default['openstack']['endpoints'][ep_type]['workflowv2']['scheme'] = 'http'
  default['openstack']['endpoints'][ep_type]['workflowv2']['host'] = '127.0.0.1'
  default['openstack']['endpoints'][ep_type]['workflowv2']['path'] = '/v2'
  default['openstack']['endpoints'][ep_type]['workflowv2']['port'] = 8989
end
