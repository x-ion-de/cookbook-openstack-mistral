default['openstack']['common']['services']['workflow'] = 'mistral'

default['openstack']['workflow']['syslog']['use'] = false

# Versions for OpenStack release
# Ocata:
# https://releases.openstack.org/teams/mistral.html
# default['openstack-workflow']['mistral_server_version'] = '4.0.0'
# Pike:
default['openstack-workflow']['mistral_server_version'] = '5.0.0'

default['openstack']['workflow']['service_role'] = 'service'

# ************** OpenStack Key Manager Endpoints ************************

# The OpenStack Key Manager (Mistral) endpoints
%w(public internal admin).each do |ep_type|
  default['openstack']['endpoints'][ep_type]['workflow']['scheme'] = 'http'
  default['openstack']['endpoints'][ep_type]['workflow']['host'] = '127.0.0.1'
  default['openstack']['endpoints'][ep_type]['workflow']['path'] = '/v2'
  default['openstack']['endpoints'][ep_type]['workflow']['port'] = 8989
end

# Needed for haproxy
default['openstack']['bind_service']['all']['workflow']['host'] = '127.0.0.1'
default['openstack']['bind_service']['all']['workflow']['port'] = 8989

default['openstack']['workflow']['service_name'] = 'mistral'
default['openstack']['workflow']['service_type'] = 'workflowv2'
