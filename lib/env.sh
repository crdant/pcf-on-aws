
prepare_env () {
  set_versions
  product_slugs

  REGION=us-west-2

  DOMAIN_TOKEN=`echo ${DOMAIN} | tr . -`
  SUBDOMAIN="aws.${DOMAIN}"
  DNS_ZONE="${SUBDOMAIN}"
  DNS_TTL=60
  CIDR="10.0.0.0/20"

  SERVICES_CIDR_AZ_1="10.0.64.0/22"
  SERVICES_CIDR_AZ_2="10.0.128.0/22"
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
  ENV_OUTPUTS="${WORKDIR}/installed-env.sh"
  SSH_PEM_PATH=${KEYDIR}/${BOSH_KEY_PAIR}.pem

  OPS_MANAGER_INSTANCE_NAME="${OPS_MANAGER_SLUG}-${DOMAIN_TOKEN}"
  OPS_MANAGER_INSTANCE_TYPE="m3.large"
  OPS_MANAGER_CLIENT_TOKEN="${OPS_MANAGER_SLUG}-${DOMAIN_TOKEN}-${OPS_MANAGER_VERSION_TOKEN}"

  PCF_SYSTEM_DOMAIN="system.${SUBDOMAIN}"
  PCF_APPS_DOMAIN="apps.${SUBDOMAIN}"
  OPS_MANAGER_HOST="manager"
  OPS_MANAGER_FQDN="${OPS_MANAGER_HOST}.${SUBDOMAIN}"
  OPS_MANAGER_API_ENDPOINT="https://${OPS_MANAGER_FQDN}/api/v0"

  ALLOW_SSH=true
  DEFAULT_SSH=true
  ALLOW_BUILDPACKS=true
  TCP_ROUTER_PORTS="1024-4442,4444-8080,8081-65535"

  # set variables for passwords if they are available
  if [ -e ${PASSWORD_LIST} ] ; then
    . ${PASSWORD_LIST}
  fi

  # set variables for various created elements
  if [ -e "${ENV_OUTPUTS}" ] ; then
    . ${ENV_OUTPUTS}
  fi
}

set_versions () {
  OPS_MANAGER_VERSION="1.11.0"
  OPS_MANAGER_VERSION_TOKEN=`echo ${OPS_MANAGER_VERSION} | tr . -`
  PCF_VERSION="1.10.14"
  STEMCELL_VERSION="3421.3"
  MYSQL_VERSION="1.9.4"
  RABBIT_VERSION="1.8.8"
  REDIS_VERSION="1.8.2"
  PCC_VERSION="1.0.4"
  SCS_VERSION="1.4.0"
  SERVICE_BROKER_VERSION="1.3.0"
  WINDOWS_VERSION="1.11.0"
  ISOLATION_VERSION="1.11.0"
  IPSEC_VERSION="1.6.3"
  PUSH_VERSION="1.9.0"
  SSO_VERSION="1.4.1"
}

product_slugs () {
  PCF_SLUG="elastic-runtime"
  PCF_OPSMAN_SLUG="cf"
  OPS_MANAGER_SLUG="ops-manager"
  MYSQL_SLUG="p-mysql"
  REDIS_SLUG="p-redis"
  RABBIT_SLUG="p-rabbitmq"
  SERVICE_BROKER_SLUG="pcf-service-broker-for-aws"
  SCS_SLUG="p-spring-cloud-services"
  PCC_SLUG="cloud-cache"
  PUSH_SLUG="push-notification-service"
  SSO_SLUG="p-identity"
  IPSEC_SLUG="p-ipsec-addon"
  ISOLATION_SLUG="isolation-segment"
  SCHEDULER_SLUG="p-scheduler-for-pcf"
  WINDOWS_SLUG="runtime-for-windows"
  STACKDRIVER_SLUG="gcp-stackdriver-nozzle"
}


store_var () {
  set -x
  variable="${1}"
  value="${2}"

  if [ -z "${value}" ] ; then
    code="echo \$${variable}"
    value=`eval $code`
  fi

  eval "$variable=${value}"
  echo "$variable=${value}" >> "${ENV_OUTPUTS}"
  set +x
}

store_json_var () {
  json="${1}"
  variable="${2}"
  jspath="${3}"

  value=`echo "${json}" | jq --raw-output "${jspath}"`
  store_var ${variable} ${value}
}
