#!/usr/bin/env bash
# install PCF and related products

BASEDIR=`dirname $0`
GCPDIR="${BASEDIR}/../pcf-on-gcp"
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/personal.sh"
. "${GCPDIR}/lib/login_ops_manager.sh"
. "${BASEDIR}/lib/ops_manager.sh"
. "${BASEDIR}/lib/elastic_runtime.sh"
. "${GCPDIR}/lib/eula.sh"
. "${BASEDIR}/lib/products.sh"
. "${GCPDIR}/lib/guid.sh"
. "${GCPDIR}/lib/networks_azs.sh"
. "${GCPDIR}/lib/properties.sh"
. "${GCPDIR}/lib/resources.sh"
. "${GCPDIR}/lib/credentials.sh"


init () {
  INSTALL_PCF=0
  INSTALL_MYSQL=0
  INSTALL_RABBIT=0
  INSTALL_REDIS=0
  INSTALL_SCS=0
  INSTALL_AWS=0
  INSTALL_PCC=0
  INSTALL_CONCOURSE=0
  INSTALL_IPSEC=0
  INSTALL_PUSH=0
  INSTALL_ISOLATION=0
  INSTALL_WINDOWS=0
}

parse_args () {
  if [ $# -eq 0 ] ; then
    set_defaults
  else
    while [ $# -gt 0 ] ; do
      product=$1
      case $product in
          "pcf")
            INSTALL_PCF=1
            ;;
          "mysql")
            INSTALL_MYSQL=1
            ;;
          "rabbit")
            INSTALL_RABBIT=1
            ;;
          "redis")
            INSTALL_REDIS=1
            ;;
          "scs")
            INSTALL_SCS=1
            ;;
          "azure")
            INSTALL_AWS=1
            ;;
          "pcc")
            INSTALL_PCC=1
            ;;
          "concourse")
            INSTALL_CONCOURSE=1
            ;;
          "notifications")
            INSTALL_PUSH=1
            ;;
          "ipsec")
            INSTALL_IPSEC=1
            ;;
          "isolation")
            INSTALL_ISOLATION=1
            ;;
          "windows")
            INSTALL_WINDOWS=1
            ;;
          "default")
            set_defaults
            ;;
          "all")
            INSTALL_PCF=1
            INSTALL_MYSQL=1
            INSTALL_RABBIT=1
            INSTALL_REDIS=1
            INSTALL_SCS=1
            INSTALL_AWS=1
            INSTALL_PCC=1
            INSTALL_CONCOURSE=1
            INSTALL_IPSEC=1
            INSTALL_PUSH=1
            INSTALL_ISOLATION=1
            INSTALL_WINDOWS=1
            ;;
          "--help")
            usage
            exit 1
            ;;
          *)
            usage
            exit 1
            ;;
      esac
      shift
    done
  fi

}

set_defaults () {
  INSTALL_PCF=1
  INSTALL_MYSQL=1
  INSTALL_RABBIT=1
  INSTALL_REDIS=1
  INSTALL_SCS=1
  INSTALL_AWS=1
  INSTALL_PCC=1
}

usage () {
  cmd=`basename $0`
  echo "$cmd [ pcf ] [isolation] [windows] [ mysql ] [ rabbit ] [ redis ] [ scs ] [ azure ] [ pcc ] [ concourse ] [ notifications ]"
}

products () {
  if [ "$INSTALL_PCF" -eq 1 ] ; then
    cloud_foundry
  fi

  if [ "$INSTALL_MYSQL" -eq 1 ] ; then
    mysql
  fi

  if [ "$INSTALL_RABBIT" -eq 1 ] ; then
    rabbit
  fi

  if [ "$INSTALL_REDIS" -eq 1 ] ; then
    redis
  fi

  if [ "$INSTALL_PCC" -eq 1 ] ; then
    cloud_cache
  fi

  if [ "$INSTALL_SCS" -eq 1 ] ; then
    spring_cloud_services
  fi

  if [ "$INSTALL_AWS" -eq 1 ] ; then
    service_broker
  fi

  if [ "$INSTALL_CONCOURSE" -eq 1 ] ; then
    concourse
  fi

  if [ "$INSTALL_PUSH" -eq 1 ] ; then
    push_notifications
  fi

  if [ "$INSTALL_ISOLATION" -eq 1 ] ; then
    isolation_segments
  fi

  if [ "$INSTALL_WINDOWS" -eq 1 ] ; then
    windows
  fi

  if [ "$INSTALL_IPSEC" -eq 1 ] ; then
    echo "WARNING: Be sure to install the IPSec add-on before any other products"
    ipsec
  fi

}

stemcell () {
  login_ops_manager
  echo "Downloading latest product stemcell ${STEMCELL_VERSION}..."
  accept_eula "stemcells" "${STEMCELL_VERSION}" "yes"
  stemcell_file=`download_stemcell ${STEMCELL_VERSION}`
  echo "Uploading stemcell to Operations Manager..."
  upload_stemcell $stemcell_file
}

cloud_foundry () {
  add_to_install "Cloud Foundry Elastic Runtime" "${PCF_SLUG}" "${PCF_VERSION}" "${PCF_OPSMAN_SLUG}"
  store_var PCF_GUID "${guid}"
  stemcell

  # configure the elastic runtime
  set_networks_azs "${PCF_OPSMAN_SLUG}"
  set_pcf_domains
  set_pcf_networking
  set_pcf_containers
  set_pcf_security_acknowledgement
  set_pcf_rds_database
  set_pcf_advanced_features

  # set the load balancers resource configuration
  ROUTER_RESOURCES=`get_resources cf router`
  ROUTER_LBS="[ \"tcp:$WS_LOAD_BALANCER_NAME\", \"http:$HTTP_LOAD_BALANCER_NAME\" ]"
  ROUTER_RESOURCES=`echo $ROUTER_RESOURCES | jq ".elb_names = $ROUTER_LBS"`
  set_resources cf router "${ROUTER_RESOURCES}"

  TCP_ROUTER_RESOURCES=`get_resources cf tcp_router`
  TCP_ROUTER_LBS="[ \"tcp:$TCP_LOAD_BALANCER_NAME\" ]"
  TCP_ROUTER_RESOURCES=`echo $TCP_ROUTER_RESOURCES | jq ".elb_names = $TCP_ROUTER_LBS"`
  set_resources cf tcp_router "${TCP_ROUTER_RESOURCES}"

  BRAIN_RESOURCES=`get_resources cf diego_brain`
  BRAIN_LBS="[ \"tcp:$SSH_LOAD_BALANCER_NAME\" ]"
  BRAIN_RESOURCES=`echo $BRAIN_RESOURCES | jq ".elb_names = $BRAIN_LBS"`
  set_resources cf diego_brain "${BRAIN_RESOURCES}"
}

mysql () {
  add_to_install "Rabbit MQ Broker" "${MYSQL_SLUG}" "${MYSQL_VERSION}"
  store_var MYSQL_GUID "${GUID}"
  set_networks_azs "${MYSQL_SLUG}"
}

rabbit () {
  add_to_install "Rabbit MQ Broker" "${RABBIT_SLUG}" "${REDIS_VERSION}"
  store_var REDIS_GUID "${GUID}"
  set_networks_azs "${RABIT_SLUG}"
}

redis () {
  add_to_install "Redis Service Broker" "${REDIS_SLUG}" "${REDIS_VERSION}"
  store_var REDIS_GUID "${GUID}"
  set_networks_azs "${REDIS_SLUG}"
}

cloud_cache () {
  add_to_install "Spring Cloud Services" "${PCC_SLUG}" "${PCC_VERSION}"
  store_var PCC_GUID "${GUID}"
  set_networks_azs "${PCC_SLUG}"
}

spring_cloud_services () {
  add_to_install "Spring Cloud Services" "${SCS_SLUG}" "${SCS_VERSION}"
  store_var SCS_GUID "${GUID}"
  set_networks_azs "${SCS_SLUG}"
}

service_broker () {
  add_to_install "AWS Service Broker" "${SERVICE_BROKER_SLUG}" "${SERVICE_BROKER_VERSION}"
  store_var SERVICE_BROKER_GUID "${GUID}"
  set_networks_azs "${SEVICE_BROKER_SLUG}"
}

windows () {
  add_to_install "Runtime for Windows" "${WINDOWS_SLUG}" "${WINDOWS_VERSION}"
  store_var WINDOWS_GUID "${GUID}"
  windows_stemcell
}

windows_stemcell () {
  login_ops_manager
  echo "Downloading latest Windows stemcell ${WINDOWS_STEMCELL_VERSION}..."
  accept_eula "stemcells-windows-server" ${WINDOWS_STEMCELL_VERSION} "yes"
  stemcell_file=`download_stemcell ${WINDOWS_STEMCELL_VERSION}`
  echo "Uploading Windows stemcell to Operations Manager..."
  upload_stemcell $stemcell_file
}

concourse () {
  add_to_install "Concourse" "${CONCOURSE_SLUG}" "${CONCOURSE_VERSION}"
  store_var CONCOURSE_GUID "${GUID}"
  set_networks_azs "${CONCOURSE_SLUG}"
}

push_notifications () {
  add_to_install "Push Notifications" "${PUSH_SLUG}" "${PUSH_VERSION}"
  store_var PUSH_GUID "${GUID}"
  set_networks_azs "${PUSH_SLUG}"
}

isolation_segments () {
  add_to_install "Isolation Segments" "${ISOLATION_SLUG}" "${ISOLATION_VERSION}"
  store_var ISOLATION_GUID "${GUID}"
  set_networks_azs "${ISOLATION_SLUG}"
}

ipsec () {
  accept_eula "p-ipsec-addon" "${IPSEC_VERSION}" "yes"
  echo "Downloading IPSec Add-on..."
  addon_file=`download_addon "p-ipsec-addon" "${IPSEC_VERSION}"`
  echo "Uploading IPSec Add-on to the BOSH Director..."
  upload_addon $addon_file
}

add_to_install() {
  product_name=${1}
  pivnet_slug="${2}"
  version="${3}"
  opsman_slug="${4}"

  if [ -z "${opsman_slug}" ] ; then
    opsman_slug="${2}"
  fi

  if product_not_available "${pivnet_slug}" "${version}" ; then
    # download the broker and make it available
    accept_eula "${pivnet_slug}" "${version}" "yes"
    echo "Downloading ${product_name}..."
    tile_file=`download_tile "${pivnet_slug}" "${version}"`
    echo "Uploading ${product_name}..."
    upload_tile $tile_file
  fi
  echo "Staging ${product_name}..."
  stage_product "${opsman_slug}"
  GUID=`product_guid "${opsman_slug}"`
}

START_TIMESTAMP=`date`
START_SECONDS=`date +%s`
init
parse_args $@
prepare_env
set_versions
echo "Started installing Cloud Foundry components on Amazon Web Services for ${SUBDOMAIN} at ${START_TIMESTAMP}..."
login_ops_manager
products
END_TIMESTAMP=`date`
END_SECONDS=`date +%s`
ELAPSED_TIME=`echo $((END_SECONDS-START_SECONDS)) | awk '{print int($1/60)":"int($1%60)}'`
echo "Completed installing Cloud Foundry components in Amazon Web Services for ${SUBDOMAIN} at ${END_TIMESTAMP} (elapsed time ${ELAPSED_TIME})."
