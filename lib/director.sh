set_director_config () {
  login_ops_manager
  SSH_PRIVATE_KEY=`cat ${SSH_PEM_PATH} | perl -pe 's#\n#\x5c\x5c\x6e#g'`

  CONFIG_JSON=`export PCF_ACCESS_KEY_ID PCF_SECRET_ACCESS_KEY VPC_ID PCF_SECURITY_GROUP_ID BOSH_KEY_PAIR REGION OPS_MANAGER_BUCKET SSH_PRIVATE_KEY PCF_RDS_HOST PCF_RDS_PORT PCF_RDS_USER PCF_RDS_DATABASE; envsubst < api-calls/director/config.json ; unset PCF_ACCESS_KEY_ID PCF_SECRET_ACCESS_KEY VPC_ID PCF_SECURITY_GROUP_ID BOSH_KEY_PAIR REGION OPS_MANAGER_BUCKET SSH_PRIVATE_KEY PCF_RDS_HOST PCF_RDS_PORT PCF_RDS_USER PCF_RDS_DATABASE`
  curl -qsLf --insecure -X PUT "${OPS_MANAGER_API_ENDPOINT}/staged/director/properties" -H "Authorization: Bearer ${UAA_ACCESS_TOKEN}" -H "Content-Type: application/json" -d "${CONFIG_JSON}"
}

get_director_config () {
  login_ops_manager
  curl -qsLf --insecure "${OPS_MANAGER_API_ENDPOINT}/staged/director/properties" -H "Authorization: Bearer ${UAA_ACCESS_TOKEN}" -H "Accepts: application/json"
}

set_availability_zones () {
  login_ops_manager
  AZS_JSON=`export PRIVATE_SUBNET_AVAIALBILITY_ZONE PRIVATE_SUBNET_2_AVAIALBILITY_ZONE; envsubst < api-calls/director/availability-zones.json; unset  PRIVATE_SUBNET_AVAIALBILITY_ZONE PRIVATE_SUBNET_2_AVAIALBILITY_ZONE`
  curl --insecure -X PUT "${OPS_MANAGER_API_ENDPOINT}/staged/director/networks" -H "Authorization: Bearer ${UAA_ACCESS_TOKEN}" -H "Content-Type: application/json" -d "${NETWORKS_JSON}"

}

create_director_networks () {
  login_ops_manager
  NETWORKS_JSON=`export DIRECTOR_NETWORK_NAME RESOURCE_GROUP NETWORK SUBNET CIDR RESERVED_IP_RANGE GATEWAY DNS_SERVERS; envsubst < api-calls/director/create-networks.json; unset DIRECTOR_NETWORK_NAME RESOURCE_GROUP NETWORK SUBNET CIDR RESERVED_IP_RANGE GATEWAY DNS_SERVERS`
  curl --insecure -X PUT "${OPS_MANAGER_API_ENDPOINT}/staged/director/networks" -H "Authorization: Bearer ${UAA_ACCESS_TOKEN}" -H "Content-Type: application/json" -d "${NETWORKS_JSON}"
}

assign_director_networks () {
  login_ops_manager
  NETWORKS_JSON=`export DIRECTOR_NETWORK_NAME ; envsubst < api-calls/director/assign-networks.json; unset DIRECTOR_NETWORK_NAME`
  curl --insecure -X PUT "${OPS_MANAGER_API_ENDPOINT}/staged/director/network_and_az" -H "Authorization: Bearer ${UAA_ACCESS_TOKEN}" -H "Content-Type: application/json" -d "${NETWORKS_JSON}"
}
