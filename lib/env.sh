
prepare_env () {
  set_versions
  product_slugs

  REGION=us-west-2

  DOMAIN_TOKEN=`echo ${DOMAIN} | tr . -`
  SUBDOMAIN="aws.${DOMAIN}"
  DNS_ZONE="${SUBDOMAIN}"
  DNS_TTL=60
  CIDR="10.0.0.0/20"

  SERVICES_CIDR_AZ_1="10.0.64.0/20"
  SERVICES_CIDR_AZ_2="10.0.128.0/20"
  PRIVATE_SUBNET_GATEWAY="10.0.16.1"
  PRIVATE_SUBNET_RESERVED_IP_RANGE="10.0.16.1-10.0.16.9"
  PRIVATE_SUBNET_2_GATEWAY="10.0.32.1"
  PRIVATE_SUBNET_2_RESERVED_IP_RANGE="10.0.32.1-10.0.32.9"
  SERVICES_SUBNET_GATEWAY="10.0.64.1"
  SERVICES_SUBNET_1_RESERVED_IP_RANGE="10.0.64.1-10.0.64.9"
  SERVICES_SUBNET_2_GATEWAY="10.0.128.1"
  SERVICES_SUBNET_2_RESERVED_IP_RANGE="10.0.128.1-10.0.128.9"

  GATEWAY="10.0.0.1"
  ALL_INTERNET="0.0.0.0/0"
  DNS_SERVERS="8.8.8.8,8.8.4.4"
  NETWORK="pcf-net"
  SUBNET="pcf"
  DEFAULT_SECURITY_GROUP="pcf-nsg"

  NAT_INSTANCE_TYPE="t2.medium"
  BOSH_KEY_PAIR="bosh-${DOMAIN_TOKEN}"
  BOSH_RDS_NAME=`echo "BoshDB${DOMAIN}" | tr -d .`
  BOSH_RDS_USER=`echo "bosh-${DOMAIN_TOKEN}" | tr -d -`
  STACK_NAME=`echo "PCFStack${DOMAIN}" | tr -d .`
  ELB_PREFIX=`echo "pcf-lb-${DOMAIN_TOKEN}" | tr -d .`

  DIRECTOR_NETWORK_NAME="pcf-${DOMAIN_TOKEN}-${REGION}"
  SERVICES_NETWORK_NAME="pcf-services-${DOMAIN_TOKEN}-${REGION}"

  CNI_CIDR="10.255.0.0/16"

  KEYDIR="${BASEDIR}/keys"
  WORKDIR="${BASEDIR}/work"
  PASSWORD_LIST="${KEYDIR}/password-list"
  AWS_ENV_OUTPUTS="${WORKDIR}/aws-env.sh"
  SSH_PEM_PATH=${KEYDIR}/${BOSH_KEY_PAIR}.pem

  OPS_MANAGER_INSTANCE_NAME="${OPS_MANAGER_SLUG}-${DOMAIN_TOKEN}"
  OPS_MANAGER_INSTANCE_TYPE="m3.large"
  OPS_MANAGER_CLIENT_TOKEN="${OPS_MANAGER_SLUG}-${DOMAIN_TOKEN}-${OPS_MANAGER_VERSION_TOKEN}"

  PCF_SYSTEM_DOMAIN="system.${SUBDOMAIN}"
  PCF_APPS_DOMAIN="apps.${SUBDOMAIN}"
  OPS_MANAGER_HOST="manager"
  OPS_MANAGER_FQDN="${OPS_MANAGER_HOST}.${SUBDOMAIN}"
  OPS_MANAGER_API_ENDPOINT="https://${OPS_MANAGER_FQDN}/api/v0"

  # set variables for passwords if they are available
  if [ -e ${PASSWORD_LIST} ] ; then
    . ${PASSWORD_LIST}
  fi

  # set variables for various created elements
  if [ -e "${AWS_ENV_OUTPUTS}" ] ; then
    . ${AWS_ENV_OUTPUTS}
  fi
}

set_versions () {
  OPS_MANAGER_VERSION="1.10.1"
  OPS_MANAGER_VERSION_TOKEN=`echo ${OPS_MANAGER_VERSION} | tr . -`
  PCF_VERSION="1.10.3"
  STEMCELL_VERSION="3263.20"
  MYSQL_VERSION="1.8.5"
  RABBIT_VERSION="1.8.0-Alpha-207"
  REDIS_VERSION="1.8.0.beta.102"
  PCC_VERSION="1.0.0"
  SCS_VERSION="1.3.4"
  CONCOURSE_VERSION="1.0.0-edge.11"
  IPSEC_VERSION="1.5.37"
  PUSH_VERSION="1.8.1"
  SSO_VERSION="1.3.1"
  ISOLATION_VERSION="1.10.1"
}

product_slugs () {
  PCF_SLUG="elastic-runtime"
  OPS_MANAGER_SLUG="ops-manager"
  SERVICE_BROKER_SLUG="pcf-service-broker-for-aws"
  PCC_SLUG="cloud-cache"
}

store_json_var () {
  json="${1}"
  variable="${2}"
  jspath="${3}"

  value=`echo "${json}" | jq --raw-output "${jspath}"`
  eval "$variable=${value}"
  echo "$variable=${value}" >> "${AWS_ENV_OUTPUTS}"
}
