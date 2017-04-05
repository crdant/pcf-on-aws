#!/usr/bin/env bash
# prepare to install PCF on AWS

BASEDIR=`dirname $0`
GCPDIR="${BASEDIR}/../pcf-on-gcp"

. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/personal.sh"
. "${BASEDIR}/personal.sh"
. "${BASEDIR}/lib/ops_manager.sh"
. "${BASEDIR}/lib/products.sh"
. "${GCPDIR}/lib/setup.sh"
. "${GCPDIR}/lib/login_ops_manager.sh"
. "${GCPDIR}/lib/random_phrase.sh"
. "${GCPDIR}/lib/generate_passphrase.sh"
. "${BASEDIR}/lib/ssl_keys.sh"
. "${GCPDIR}/lib/eula.sh"
. "${GCPDIR}/lib/guid.sh"
. "${GCPDIR}/lib/networks_azs.sh"

security () {
  aws ec2 delete-key-pair --key-name "${BOSH_KEY_PAIR}"
  aws acm delete-certificate --certificate-arn  "${CERTIFICATE_ARN}"
}

cloudformation () {
  echo "Deleting CloudFormation stack ${STACK_NAME}..."
  aws cloudformation delete-stack --stack-name "${STACK_NAME}"
}

ops_manager () {
  echo "Ops Manager not getting created yet"
}

START_TIMESTAMP=`date`
START_SECONDS=`date +%s`
echo "Started tearing down Cloud Foundry installation on Amazon Web Services at ${START_TIMESTAMP}..."

prepare_env
security
cloudformation
ops_manager

END_TIMESTAMP=`date`
END_SECONDS=`date +%s`
ELAPSED_TIME=`echo $((END_SECONDS-START_SECONDS)) | awk '{print int($1/60)":"int($1%60)}'`
echo "Finished tearing down Cloud Foundry installation on Amazon Web Services at ${END_TIMESTAMP} (elapsed time ${ELAPSED_TIME})."
