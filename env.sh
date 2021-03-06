# make the environment for these scripts available in your current shell
if [ -n "$ZSH_VERSION" ]; then
  BASEDIR=`dirname ${(%):-%N}`
elif [ -n "$BASH_VERSION" ]; then
  BASEDIR=`dirname ${BASH_SOURCE[0]}`
else
  # doesn't likely work but it's something to set it as
  BASEDIR=`dirname $0`
fi

GCPDIR=${HOME}/workspace/pcf-on-gcp

. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/personal.sh"
. "${GCPDIR}/lib/login_ops_manager.sh"
. "${BASEDIR}/lib/ops_manager.sh"
. "${BASEDIR}/lib/director.sh"
. "${BASEDIR}/lib/elastic_runtime.sh"
. "${BASEDIR}/lib/ssl_keys.sh"
. "${GCPDIR}/lib/eula.sh"
. "${BASEDIR}/lib/products.sh"
. "${GCPDIR}/lib/guid.sh"
. "${BASEDIR}/lib/networks_azs.sh"
. "${BASEDIR}/lib/properties.sh"
. "${GCPDIR}/lib/resources.sh"
. "${GCPDIR}/lib/credentials.sh"
. "${GCPDIR}/lib/generate_passphrase.sh"

prepare_env
set_versions

# Cloud
export SUBSCRIPTION_ID
export TENANT_ID
export RESOURCE_GROUP
export DOMAIN
export EMAIL

export LOCATION

# DNS
export SUBDOMAIN
export DNS_ZONE
export DNS_TTL

# Network
export CIDR
export SERVICES_CIDR
export ALL_INTERNET
export DNS_SERVERS
export DEFAULT_SECURITY_GROUP

export NETWORK
export SUBNET
export DIRECTOR_NETWORK_NAME
export SERVICES_NETWORK_NAME

export NAT_INSTANCE_TYPE
export BOSH_KEY_PAIR
export BOSH_RDS_NAME
export BOSH_RDS_USER
export STACK_NAME
export ELB_PREFIX

export CNI_CIDR

export KEYDIR
export WORKDIR
export PASSWORD_LIST
export ENV_OUTPUTS

export OPS_MANAGER_INSTANCE_NAME
export OPS_MANAGER_INSTANCE_TYPE
export OPS_MANAGER_CLIENT_TOKEN

export PCF_SYSTEM_DOMAIN
export PCF_APPS_DOMAIN
export OPS_MANAGER_HOST
export OPS_MANAGER_FQDN
export OPS_MANAGER_API_ENDPOINT

export ALLOW_SSH
export DEFAULT_SSH
export ALLOW_BUILDPACKS
export TCP_ROUTER_PORTS

# dynamic values (created by prepare)

export CERTIFICATE_ARN
export PCF_SECURITY_GROUP_ID
export OPS_MANAGER_SECURITY_GROUP_ID

export VPC_ID
export PRIVATE_SUBNET_1_RESERVED_IP_RANGE
export PRIVATE_SUBNET_2_AVAIALBILITY_ZONE
export PRIVATE_SUBNET_2_GATEWAY
export PRIVATE_SUBNET_2_ID
export PRIVATE_SUBNET_2_RESERVED_IP_RANGE
export PRIVATE_SUBNET_AVAIALBILITY_ZONE
export PRIVATE_SUBNET_GATEWAY
export PRIVATE_SUBNET_ID
export PUBLIC_SUBNET_2_AVAIALBILITY_ZONE
export PUBLIC_SUBNET_ID
export PUBLIC_SUBNET_ID_2
export SERVICES_CIDR_AZ_1
export SERVICES_CIDR_AZ_2
export SERVICES_SUBNET_1_RESERVED_IP_RANGE
export SERVICES_SUBNET_2_GATEWAY
export SERVICES_SUBNET_2_RESERVED_IP_RANGE
export SERVICES_SUBNET_GATEWAY
export SERVICES_SUBNET_ID_1
export SERVICES_SUBNET_ID_2

export OPS_MANAGER_BUCKET
export DROPLETS_BUCKET
export BUILDPACKS_BUCKET
export PACKAGES_BUCKET
export RESOURCES_BUCKET

export PCF_IAM_USER
export PCF_RDS_PORT
export PCF_RDS_HOST
export SSH_ELB_HOST
export ROUTER_ELB_HOST

export TCP_ROUTER_ELB_HOST
export PCF_SECURITY_GROUP_ID
export OPS_MANAGER_SECURITY_GROUP_ID

export OPS_MANAGER_INSTANCE_ID
export OPS_MANAGER_PRIVATE_IP
export OPS_MANAGER_PUBLIC_IP

# versions
export OPS_MANAGER_VERSION
export OPS_MANAGER_VERSION_TOKEN
export PCF_VERSION
export STEMCELL_VERSION
export MYSQL_VERSION
export RABBIT_VERSION
export REDIS_VERSION
export PCC_VERSION
export SCS_VERSION
export SERVICE_BROKER_VERSION
export WINDOWS_VERSION
export ISOLATION_VERSION
export IPSEC_VERSION
export PUSH_VERSION
export SSO_VERSION

# slugs
export PCF_SLUG
export PCF_OPSMAN_SLUG
export OPS_MANAGER_SLUG
export MYSQL_SLUG
export REDIS_SLUG
export RABBIT_SLUG
export SERVICE_BROKER_SLUG
export SCS_SLUG
export PCC_SLUG
export PUSH_SLUG
export SSO_SLUG
export IPSEC_SLUG
export ISOLATION_SLUG
export SCHEDULER_SLUG
export WINDOWS_SLUG
export STACKDRIVER_SLUG

# secrets
export ADMIN_PASSWORD
export DECRYPTION_PASSPHRASE
export PCF_SECRET_ACCESS_KEY
export PCF_ACCESS_KEY_ID
