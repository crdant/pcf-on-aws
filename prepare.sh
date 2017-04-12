#!/usr/bin/env bash
# prepare to install PCF on AWS

BASEDIR=`dirname $0`
GCPDIR="${BASEDIR}/../pcf-on-gcp"

. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/personal.sh"
. "${BASEDIR}/lib/ops_manager.sh"
. "${BASEDIR}/lib/director.sh"
. "${BASEDIR}/lib/products.sh"
. "${GCPDIR}/lib/setup.sh"
. "${GCPDIR}/lib/login_ops_manager.sh"
. "${GCPDIR}/lib/random_phrase.sh"
. "${GCPDIR}/lib/generate_passphrase.sh"
. "${BASEDIR}/lib/ssl_keys.sh"
. "${GCPDIR}/lib/eula.sh"
. "${GCPDIR}/lib/guid.sh"
. "${GCPDIR}/lib/networks_azs.sh"

new_env_file () {
  rm "${AWS_ENV_OUTPUTS}"
  touch "${AWS_ENV_OUTPUTS}"
}

passwords () {
  ADMIN_PASSWORD=`generate_passphrase 4`
  DECRYPTION_PASSPHRASE=`generate_passphrase 5`
  BOSH_RDS_PASSWORD=`generate_passphrase 3`
  RABBIT_ADMIN_PASSWORD=`generate_passphrase 4`

  cat <<PASSWORD_LIST > "${PASSWORD_LIST}"
ADMIN_PASSWORD=${ADMIN_PASSWORD}
DECRYPTION_PASSPHRASE=${DECRYPTION_PASSPHRASE}
BOSH_RDS_PASSWORD=${BOSH_RDS_PASSWORD}
RABBIT_ADMIN_PASSWORD=${RABBIT_ADMIN_PASSWORD}
PASSWORD_LIST
  chmod 700 "${PASSWORD_LIST}"
}

security () {
  aws ec2 create-key-pair --key-name "${BOSH_KEY_PAIR}" --output text > "${SSH_PEM_PATH}"
  chmod 600 "${SSH_PEM_PATH}"
  CERTIFICATE_ARN=`aws_request_certificate "${SUBDOMAIN}" "${DOMAIN}"`
  echo "CERTIFICATE_ARN=${CERTIFICATE_ARN}" >> "${AWS_ENV_OUTPUTS}"
}

cloudformation () {
  accept_eula "${PCF_SLUG}" "${PCF_VERSION}" "yes"
  template_file=`download_template "${PCF_SLUG}" "${PCF_VERSION}"`
  parameters=`export DOMAIN BOSH_KEY_PAIR NAT_INSTANCE_TYPE ALL_INTERNET BOSH_RDS_NAME BOSH_RDS_NAME BOSH_RDS_PASSWORD CERTIFICATE_ARN; envsubst < templates/parameters.json ; unset DOMAIN BOSH_KEY_PAIR NAT_INSTANCE_TYPE ALL_INTERNET BOSH_RDS_NAME BOSH_RDS_NAME BOSH_RDS_PASSWORD CERTIFICATE_ARN`
  template_body=`cat "${template_file}"`

  echo "Creating CloudFormaton stack ${STACK_NAME}..."
  stack_id=`aws cloudformation create-stack --template-body "${template_body}" --parameters "${parameters}" --stack-name "${STACK_NAME}" --capabilities CAPABILITY_IAM | jq --raw-output '.StackId'`
  echo "Waiting for stack ${STACK_NAME} to be created..."
  aws cloudformation wait stack-create-complete --no-paginate --stack-name "${STACK_NAME}"

  echo "Getting outputs from stack creation..."
  STACK_OUTPUTS=`aws cloudformation describe-stacks --stack-name "${STACK_NAME}" | jq ".Stacks[].Outputs"`
  if [ -z "${STACK_OUTPUTS}" ] ; then
    sleep 30
    STACK_OUTPUTS=`aws cloudformation describe-stacks --stack-name "${STACK_NAME}" | jq ".Stacks[].Outputs"`
    if [ -z "${STACK_OUTPUTS}" ] ; then
      echo "Unable to read the outputs from creating a the Cloud Formation stack ${STACK_NAME}"
      exit
    fi
  fi

  store_stack_environment "${STACK_OUTPUTS}"
  aws ec2 create-tags --resources "${PRIVATE_SUBNET_ID}" "${PRIVATE_SUBNET_2_ID}" --tags "Key=Network,Value=${DIRECTOR_NETWORK_NAME}"
}

store_stack_environment () {
  outputs=$1

  store_output_var "${outputs}" "PCF_SECURITY_GROUP_ID" "PcfVmsSecurityGroupId"
  store_output_var "${outputs}" "OPS_MANAGER_SECURITY_GROUP_ID" "PcfOpsManagerSecurityGroupId"

  store_output_var "${outputs}" "VPC_ID" "PcfVpc"
  store_output_var "${outputs}" "PRIVATE_SUBNET_ID" "PcfPrivateSubnetId"
  store_output_var "${outputs}" "PRIVATE_SUBNET_AVAIALBILITY_ZONE" "PcfPrivateSubnetAvailabilityZone"
  store_output_var "${outputs}" "PRIVATE_SUBNET_2_ID" "PcfPrivateSubnet2Id"
  store_output_var "${outputs}" "PRIVATE_SUBNET_2_AVAIALBILITY_ZONE" "PcfPrivateSubnet2AvailabilityZone"
  store_output_var "${outputs}" "PUBLIC_SUBNET_ID" "PcfPublicSubnetId"
  store_output_var "${outputs}" "PUBLIC_SUBNET_AVAIALBILITY_ZONE" "PcfPublicSubnetAvailabilityZone2"
  store_output_var "${outputs}" "PUBLIC_SUBNET_2_AVAIALBILITY_ZONE" "PcfPublicSubnetAvailabilityZone"
  store_output_var "${outputs}" "PUBLIC_SUBNET_ID_2" "PcfPublicSubnetId2"

  store_output_var "${outputs}" "OPS_MANAGER_BUCKET" "PcfOpsManagerS3Bucket"
  store_output_var "${outputs}" "DROPLETS_BUCKET" "PcfElasticRuntimeS3DropletsBucket"
  store_output_var "${outputs}" "BUILDPACKS_BUCKET" "PcfElasticRuntimeS3BuildpacksBucket"
  store_output_var "${outputs}" "PACKAGES_BUCKET" "PcfElasticRuntimeS3PackagesBucket"
  store_output_var "${outputs}" "RESOURCES_BUCKET" "PcfElasticRuntimeS3ResourcesBucket"

  store_output_var "${outputs}" "PCF_IAM_USER" "PcfIamUserName"
  store_output_secret "${outputs}" "PCF_SECRET_ACCESS_KEY" "PcfIamUserSecretAccessKey"
  store_output_secret "${outputs}" "PCF_ACCESS_KEY_ID" "PcfIamUserAccessKey"

  store_output_var "${outputs}" "PCF_RDS_USER" "PcfRdsUser"
  store_output_var "${outputs}" "PCF_RDS_PORT" "PcfRdsPort"
  store_output_var "${outputs}" "PCF_RDS_HOST" "PcfRdsAddress"
  store_output_var "${outputs}" "PCF_RDS_DATABASE" "PcfRdsDBName"

  store_output_var "${outputs}" "SSH_ELB_HOST" "PcfElbSshDnsName"
  store_output_var "${outputs}" "ROUTER_ELB_HOST" "PcfElbDnsName"
  store_output_var "${outputs}" "TCP_ROUTER_ELB_HOST" "PcfElbTcpDnsName"

  private_subnet=`aws ec2 describe-subnets --subnet-ids $PRIVATE_SUBNET_ID`
  store_json_var "${private_subnet}" PRIVATE_SUBNET_CIDR '.Subnets[0].CidrBlock'

  private_subnet=`aws ec2 describe-subnets --subnet-ids $PRIVATE_SUBNET_2_ID`
  store_json_var "${private_subnet}" PRIVATE_SUBNET_2_CIDR '.Subnets[0].CidrBlock'
}

store_output_var () {
  outputs="${1}"
  variable="${2}"
  key="${3}"

  value=`echo $outputs | jq --raw-output ". [] | select ( .OutputKey == \"$key\" ) .OutputValue"`
  eval "$variable=${value}"
  echo "$variable=${value}" >> "${AWS_ENV_OUTPUTS}"
}

store_output_secret () {
  outputs="${1}"
  variable="${2}"
  key="${3}"

  value=`echo $outputs | jq --raw-output ". [] | select ( .OutputKey == \"$key\" ) .OutputValue"`
  eval "$variable=${value}"
  echo "$variable=${value}" >> "${PASSWORD_LIST}"
}

ops_manager_dns () {
  local dns_comment="Configuration DNS for running Cloud Foundry at ${SUBDOMAIN}"
  local change_batch=`mktemp -t prepare.dns.zonefile`

  cat > ${change_batch} <<CHANGES
    {
      "Comment":"$dns_comment",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value": "${OPS_MANAGER_PUBLIC_IP}"
              }
            ],
            "Name":"${OPS_MANAGER_FQDN}",
            "Type": "A",
            "TTL":$DNS_TTL
          }
        }
      ]
    }
CHANGES

  aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file://"${change_batch}"
}

ops_manager () {
  echo "Installing Operations Manager..."
  OPS_MANAGER_RELEASES_URL="https://network.pivotal.io/api/v2/products/${OPS_MANAGER_SLUG}/releases"
  OPS_MANAGER_YML="${WORKDIR}/ops-manager-on-aws.yml"

  # download the Ops Manager YAML file to find the image we're using
  accept_eula "${OPS_MANAGER_SLUG}" "${OPS_MANAGER_VERSION}" "yes"
  echo "Finding the image location for the Pivotal release image for operations manager."
  FILES_URL=`curl -qsLf -H "Authorization: Token $PIVNET_TOKEN" $OPS_MANAGER_RELEASES_URL | jq --raw-output ".releases[] | select( .version == \"$OPS_MANAGER_VERSION\" ) ._links .product_files .href"`
  DOWNLOAD_POST_URL=`curl -qsLf -H "Authorization: Token $PIVNET_TOKEN" $FILES_URL | jq --raw-output '.product_files[] | select( .aws_object_key | test (".*AWS.*yml") ) ._links .download .href'`
  DOWNLOAD_URL=`curl -qsLf -X POST -d "" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token $PIVNET_TOKEN" $DOWNLOAD_POST_URL -w "%{url_effective}\n"`
  IMAGE_ID=`curl -qsLf "${DOWNLOAD_URL}" | grep "${REGION}" | sed "s/${REGION}: //"`
  echo "Located image at ${IMAGE_ID}"

  # Ops Manager instance
  echo "Creating disk image for Operations Manager from the Pivotal provided image..."
  instance_info=`aws ec2 run-instances --image-id "${IMAGE_ID}" --instance-type "${OPS_MANAGER_INSTANCE_TYPE}" --key-name "${BOSH_KEY_PAIR}" --subnet-id "${PUBLIC_SUBNET_ID}" --security-group-ids "${OPS_MANAGER_SECURITY_GROUP_ID}" --associate-public-ip-address`
  OPS_MANAGER_INSTANCE_ID=`echo "${instance_info}" | jq --raw-output '.Instances[0].InstanceId'`
  echo "OPS_MANAGER_INSTANCE_ID=${OPS_MANAGER_INSTANCE_ID}" >> ${AWS_ENV_OUTPUTS}
  aws ec2 wait instance-running --instance-ids ${OPS_MANAGER_INSTANCE_ID}
  aws ec2 create-tags --resources "${OPS_MANAGER_INSTANCE_ID}" --tags "Name=Name,Value=ops-manager-${OPS_MANAGER_VERSION_TOKEN}-${DOMAIN}"

  running_instance_info=`aws ec2 describe-instances --instance-ids ${OPS_MANAGER_INSTANCE_ID}`
  OPS_MANAGER_PRIVATE_IP=`echo "${running_instance_info}" | jq --raw-output '.Reservations[0].Instances[0].PrivateIpAddress'`
  echo "OPS_MANAGER_PRIVATE_IP=${OPS_MANAGER_PRIVATE_IP}" >> ${AWS_ENV_OUTPUTS}
  OPS_MANAGER_PUBLIC_IP=`echo "${running_instance_info}" | jq --raw-output '.Reservations[0].Instances[0].PublicIpAddress'`
  echo "OPS_MANAGER_PUBLIC_IP=${OPS_MANAGER_PUBLIC_IP}" >> ${AWS_ENV_OUTPUTS}

  # make sure we can get to it
  echo "Configuring DNS for Operations Manager..."
  ops_manager_dns

  echo "Waiting for DNS to update..."
  sleep $DNS_TTL

  # this line looks a little funny, but it's to make sure we keep the passwords out of the environment
  echo "Configuring authentication for ops manager..."
  setup_ops_manager_auth
  sleep 60
  curl --insecure "https://${OPS_MANAGER_FQDN}/login/ensure_availability" > /dev/null
  echo "Operation manager authenticate configured. Your username is admin and password is ${ADMIN_PASSWORD}."

  # log in to the ops_manager so the script can manipulate it later
  login_ops_manager

  echo "Setting up BOSH director..."
  set_director_config
  set_availability_zones
  create_director_networks
  assign_director_networks

  echo "Setting up subnets for services network..."
  services_network
}

services_network () {
  subnet_description=`aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block "${SERVICES_CIDR_AZ_1}" --availability-zone "${PRIVATE_SUBNET_AVAIALBILITY_ZONE}"`
  store_json_var "${subnet_description}" "SERVICES_SUBNET_ID_1" ".Subnet.SubnetId"
  aws ec2 create-tags --resources "${SERVICES_SUBNET_ID_1}" --tags "Key=Name,Value=pcf-services-${DOMAIN}-${PRIVATE_SUBNET_AVAIALBILITY_ZONE}"
  subnet_description=`aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block "${SERVICES_CIDR_AZ_2}" --availability-zone "${PRIVATE_SUBNET_2_AVAIALBILITY_ZONE}"`
  store_json_var "${subnet_description}" "SERVICES_SUBNET_ID_2" ".Subnet.SubnetId"
  aws ec2 create-tags --resources "${SERVICES_SUBNET_ID_2}" --tags "Key=Name,Value=pcf-services-${DOMAIN}-${PRIVATE_SUBNET_2_AVAIALBILITY_ZONE}"
  aws ec2 create-tags --resources "${SERVICES_SUBNET_ID_1}" "${SERVICES_SUBNET_ID_2}" --tags "Key=Network,Value=${SERVICES_NETWORK_NAME}"
}

elastic_runtime_dns () {
  local dns_comment="Configuration DNS for running Cloud Foundry at ${SUBDOMAIN}"
  local change_batch=`mktemp -t prepare.dns.zonefile`

  cat > ${change_batch} <<CHANGES
    {
      "Comment":"$dns_comment",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value": "${ROUTER_ELB_HOST}"
              }
            ],
            "Name":"*.${PCF_SYSTEM_DOMAIN}",
            "Type": "CNAME",
            "TTL":$DNS_TTL
          }
        },
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value": "${ROUTER_ELB_HOST}"
              }
            ],
            "Name":"*.${PCF_APPS_DOMAIN}",
            "Type": "CNAME",
            "TTL":$DNS_TTL
          }
        },
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value": "${TCP_ROUTER_ELB_HOST}"
              }
            ],
            "Name":"tcp.${PCF_APPS_DOMAIN}",
            "Type": "CNAME",
            "TTL":$DNS_TTL
          }
        },
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value": "${SSH_ELB_HOST}"
              }
            ],
            "Name":"ssh.${PCF_SYSTEM_DOMAIN}",
            "Type": "CNAME",
            "TTL":$DNS_TTL
          }
        }
      ]
    }
CHANGES

  aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file://"${change_batch}"
}

elastic_runtime () {
  elastic_runtime_dns
}

START_TIMESTAMP=`date`
START_SECONDS=`date +%s`
echo "Started preparing Cloud Foundry installation on Amazon Web Services at ${START_TIMESTAMP}..."

prepare_env
# new_env_file
# passwords
# security
#
# while true; do
#     read -p "Have you validated domain ownership for the certificate (y/n)? " yn
#     case $yn in
#         [Yy]* ) break;;
#         [Nn]* ) exit;;
#         * ) echo "Please answer yes or no.";;
#     esac
# done
#
# cloudformation
# ops_manager
# elastic_runtime
services_network

END_TIMESTAMP=`date`
END_SECONDS=`date +%s`
ELAPSED_TIME=`echo $((END_SECONDS-START_SECONDS)) | awk '{print int($1/60)":"int($1%60)}'`
echo "Finished preparing Cloud Foundry installation on Amazon Web Services at ${END_TIMESTAMP} (elapsed time ${ELAPSED_TIME})."
