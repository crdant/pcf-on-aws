#!/usr/bin/env bash
# install PCF and related products

BASEDIR=`dirname $0`
GCPDIR="${BASEDIR}/../pcf-on-gcp"
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/personal.sh"
. "${GCPDIR}/lib/login_ops_manager.sh"
. "${BASEDIR}/lib/ops_manager.sh"
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
  echo "$cmd [ pcf ] [isolation] [ mysql ] [ rabbit ] [ redis ] [ scs ] [ azure ] [ pcc ] [ concourse ] [ notifications ]"
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
  if product_not_available "cf" "${PCF_VERSION}"] ; then
    accept_eula "${PCF_SLUG}" "${PCF_VERSION}" "yes"
    echo "Downloading Cloud Foundry Elastic Runtime..."
    tile_file=`download_tile "elastic-runtime" "${PCF_VERSION}"`
    echo "Uploading Cloud Foundry Elastic Runtime to ${tile_file}..."
    upload_tile $tile_file
  else
    echo "Cloud Foundry version ${PCF_VERSION} is already available in Operations Manager at ${OPS_MANAGER_FQDN}"
  fi
  echo "Staging Cloud Foundry Elastic Runtime..."
  stage_product "cf"
  stemcell

  # # configure BLOB storage locations, system domain, etc. doesn't set everything yet (SSL certificate info doesn't
  # # come back with a GET so it's hard to figure out how to set it)
  # PRIVATE_KEY=`cat ${KEYDIR}/pcf-router-${DOMAIN_TOKEN}.key`
  # SSL_CERT=`cat ${KEYDIR}/pcf-router-${DOMAIN_TOKEN}.crt`
  #
  # # looks funny, but it keeps us from polluting the environment
  # CF_NETWORK_SETTINGS=`export DIRECTOR_NETWORK_NAME ; envsubst < api-calls/products/networks-and-azs.json ; unset  DIRECTOR_NETWORK_NAME `
  # set_networks_azs "cf" "${CF_NETWORK_SETTINGS}"
  #
  # # looks funny, but it keeps us from polluting the environment
  # PROPERTIES_JSON=`export ACCOUNT PRIVATE_KEY SSL_CERT BUILDPACKS_STORAGE_BUCKET DROPLETS_STORAGE_BUCKET RESOURCES_STORAGE_BUCKET PACKAGES_STORAGE_BUCKET GCP_ACCESS_KEY_ID GCP_SECRET_ACCESS_KEY PCF_APPS_DOMAIN PCF_SYSTEM_DOMAIN; envsubst < api-calls/elastic-runtime-properties.json ; unset ACCOUNT PRIVATE_KEY SSL_CERT BUILDPACKS_STORAGE_BUCKET DROPLETS_STORAGE_BUCKET RESOURCES_STORAGE_BUCKET PACKAGES_STORAGE_BUCKET GCP_ACCESS_KEY_ID GCP_SECRET_ACCESS_KEY PCF_APPS_DOMAIN PCF_SYSTEM_DOMAINt`
  # set_properties "cf" "${PROPERTIES_JSON}"

  # set the load balancers resource configuration
#   ROUTER_RESOURCES=`get_resources cf router`
#   ROUTER_LBS="[ \"tcp:$WS_LOAD_BALANCER_NAME\", \"http:$HTTP_LOAD_BALANCER_NAME\" ]"
#   ROUTER_RESOURCES=`echo $ROUTER_RESOURCES | jq ".elb_names = $ROUTER_LBS"`
#   set_resources cf router "${ROUTER_RESOURCES}"
#
#   TCP_ROUTER_RESOURCES=`get_resources cf tcp_router`
#   TCP_ROUTER_LBS="[ \"tcp:$TCP_LOAD_BALANCER_NAME\" ]"
#   TCP_ROUTER_RESOURCES=`echo $TCP_ROUTER_RESOURCES | jq ".elb_names = $TCP_ROUTER_LBS"`
#   set_resources cf tcp_router "${TCP_ROUTER_RESOURCES}"
#
#   BRAIN_RESOURCES=`get_resources cf diego_brain`
#   BRAIN_LBS="[ \"tcp:$SSH_LOAD_BALANCER_NAME\" ]"
#   BRAIN_RESOURCES=`echo $BRAIN_RESOURCES | jq ".elb_names = $BRAIN_LBS"`
#   set_resources cf diego_brain "${BRAIN_RESOURCES}"
}

mysql () {
  if product_not_available "p-mysql" "${MYSQL_VERSION}" ; then
    accept_eula "p-mysql" "${MYSQL_VERSION}" "yes"
    echo "Downloading MySQL Service..."
    tile_file=`download_tile "p-mysql" "${MYSQL_VERSION}"`
    echo "Uploading MySQL Service..."
    upload_tile $tile_file
  fi
  echo "Staging MySQL Service..."
  stage_product "p-mysql"

  MYSQL_NETWORK_SETTINGS=`export DIRECTOR_NETWORK_NAME ; envsubst < api-calls/products/networks-and-azs.json ; unset  DIRECTOR_NETWORK_NAME `
  set_networks_azs "p-mysql" "${MYSQL_NETWORK_SETTINGS}"
}

rabbit () {
  if product_not_available "pivotal-rabbitmq-service" "${RABBIT_VERSION}" ; then
    accept_eula "pivotal-rabbitmq-service" "${RABBIT_VERSION}" "yes"
    echo "Downloading Rabbit MQ Service..."
    tile_file=`download_tile "pivotal-rabbitmq-service" "${RABBIT_VERSION}"`
    echo "Uploading Rabbit MQ Service..."
    upload_tile $tile_file
  fi
  echo "Staging Rabbit MQ Service..."
  stage_product "p-rabbitmq"

  RABBIT_NETWORK_SETTINGS=`export DIRECTOR_NETWORK_NAME ; envsubst < api-calls/products/networks-and-azs.json ; unset  DIRECTOR_NETWORK_NAME `
  set_networks_azs "p-rabbitmq" "${RABBIT_NETWORK_SETTINGS}"
}

redis () {
  if product_not_available "p-redis" "${REDIS_VERSION_NUM}" ; then
    accept_eula "p-redis" "${REDIS_VERSION}" "yes"
    echo "Downloading REDIS Service..."
    tile_file=`download_tile "p-redis" "${REDIS_VERSION}"`
    echo "Uploading REDIS Service..."
    upload_tile $tile_file
  fi
  echo "Staging REDIS Service..."
  stage_product "p-redis"

  REDIS_NETWORK_SETTINGS=`export DIRECTOR_NETWORK_NAME ; envsubst < api-calls/products/networks-and-azs.json ; unset  DIRECTOR_NETWORK_NAME `
  set_networks_azs "p-redis" "${REDIS_NETWORK_SETTINGS}"
}

cloud_cache () {
  if product_not_available "${PCC_SLUG}" "${PCC_VERSION}" ; then
    accept_eula "${PCC_SLUG}" "${PCC_VERSION}" "yes"
    echo "Downloading Pivotal Cloud Cache..."
    tile_file=`download_tile "${PCC_SLUG}" "${PCC_VERSION}"`
    echo "Uploading Pivotal Cloud Cache..."
    upload_tile $tile_file
  fi
  echo "Staging Pivotal Cloud Cache..."
  stage_product "${PCC_SLUG}"

  PCC_NETWORK_SETTINGS=`export DIRECTOR_NETWORK_NAME ; envsubst < api-calls/products/networks-and-azs.json ; unset  DIRECTOR_NETWORK_NAME `
  set_networks_azs "${PCC_SLUG}" "${PCC_NETWORK_SETTINGS}"
}

spring_cloud_services () {
  if product_not_available "p-spring-cloud-services" "${SCS_VERSION}" ; then
    accept_eula "p-spring-cloud-services" "${SCS_VERSION}" "yes"
    echo "Downloading Spring Cloud Services..."
    tile_file=`download_tile "p-spring-cloud-services" "${SCS_VERSION}"`
    echo "Uploading Spring Cloud Services..."
    upload_tile $tile_file
  fi
  echo "Staging Spring Cloud Services..."
  stage_product "p-spring-cloud-services"

  SCS_NETWORK_SETTINGS=`export DIRECTOR_NETWORK_NAME ; envsubst < api-calls/products/networks-and-azs.json ; unset  DIRECTOR_NETWORK_NAME `
  set_networks_azs "p-spring-cloud-services" "${SCS_NETWORK_SETTINGS}"
}

service_broker () {
  if product_not_available ${SEVICE_BROKER_SLUG} "${AWS_VERSION_NUM}" ; then
    # download the broker and make it available
    accept_eula "${SEVICE_BROKER_SLUG}" "${AWS_VERSION}" "yes"
    echo "Downloading AWS Service Broker..."
    tile_file=`download_tile "${SEVICE_BROKER_SLUG}" "${AWS_VERSION}"`
    echo "Uploading AWS Service Broker..."
    upload_tile $tile_file
  fi
  echo "Staging AWS Service Broker..."
  stage_product "${SEVICE_BROKER_SLUG}"

  GCP_NETWORK_SETTINGS=`export DIRECTOR_NETWORK_NAME; envsubst < api-calls/products/networks-and-azs.json ; unset DIRECTOR_NETWORK_NAME`
  set_networks_azs "${SEVICE_BROKER_SLUG}" "${GCP_NETWORK_SETTINGS}"

  # PROPERTIES_JSON=`export SERVICE_ACCOUNT_CREDENTIALS BROKER_DB_HOST BROKER_DB_USER BROKER_DB_USER_PASSWORD CLIENT_KEY CLIENT_CERT SERVER_CERT ; envsubst < api-calls/gcp-service-broker-properties.json ; unset SERVICE_ACCOUNT_CREDENTIALS BROKER_DB_HOST BROKER_DB_USER BROKER_DB_USER_PASSWORD CLIENT_KEY CLIENT_CERT SERVER_CERT`
  # set_properties "gcp-service-broker" "${PROPERTIES_JSON}"

}

concourse () {
  if product_not_available "p-concourse" "${CONCOURSE_VERSION}" ; then
    accept_eula "p-concourse" "${CONCOURSE_VERSION}" "yes"
    echo "Downloading Concourse..."
    tile_file=`download_tile "p-concourse" "${CONCOURSE_VERSION}"`
    echo "Uploading Concourse..."
    upload_tile $tile_file
  fi
  echo "Staging Concourse..."
  stage_product "p-concourse"
  CONCOURSE_GUID=`product_guid "p-concourse"`
}

ipsec () {
  accept_eula "p-ipsec-addon" "${IPSEC_VERSION}" "yes"
  echo "Downloading IPSec Add-on..."
  addon_file=`download_addon "p-ipsec-addon" "${IPSEC_VERSION}"`
  echo "Uploading IPSec Add-on to the BOSH Director..."
  upload_addon $addon_file
}

push_notifications () {
  if product_not_available "push-notification-service" "${PUSH_VERSION}" ; then
    # download the broker and make it available
    accept_eula "push-notification-service" "${PUSH_VERSION}" "yes"
    echo "Downloading Push Notifications Service..."
    tile_file=`download_tile "push-notification-service" "${PUSH_VERSION}"`
    echo "Uploading Push Notifications Service..."
    upload_tile $tile_file
  fi
  echo "Staging Push Notifications Service..."
  stage_product "push-notification-service"
}

isolation_segments () {
  if product_not_available "isolation-segment" "${ISOLATION_VERSION}" ; then
    # download the broker and make it available
    accept_eula "isolation-segment" "${ISOLATION_VERSION}" "yes"
    echo "Downloading Isolation Segments..."
    tile_file=`download_tile "isolation-segment" "${ISOLATION_VERSION}"`
    echo "Uploading Isolation Segments..."
    upload_tile $tile_file
  fi
  echo "Staging Isolation Segments..."
  stage_product "isolation-segment"
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
