self_signed_certificate () {
  prefix="${1}"
  certificate_request "${prefix}"
  sign_certificate "${prefix}"
}

certificate_request () {
  prefix="${1}"
  if [ -n "${prefix}" ] ; then
    keyfile="${prefix}-${DOMAIN_TOKEN}"
  else
    keyfile="${DOMAIN_TOKEN}"
  fi

  openssl req -new -sha256 -nodes -out "${KEYDIR}/${keyfile}.csr" -newkey rsa:2048 -keyout "${KEYDIR}/${keyfile}.key" -config <(
  cat <<-EOF
  [req]
  default_bits = 2048
  prompt = no
  default_md = sha256
  req_extensions = req_ext
  distinguished_name = dn

  [ dn ]
  C=US
  ST=Massachusetts
  L=Cambridge
  O=Cloud Foundry
  OU=Azure Deployment
  emailAddress=${EMAIL}
  CN = *.${SUBDOMAIN}

  [ req_ext ]
  subjectAltName = @alt_names

  [ alt_names ]
  DNS.1 = *.${PCF_APPS_DOMAIN}
  DNS.2 = *.${PCF_SYSTEM_DOMAIN}
  DNS.3 = *.login.${PCF_SYSTEM_DOMAIN}
  DNS.4 = *.uaa.${PCF_SYSTEM_DOMAIN}
EOF
  )
}

sign_certificate () {
  prefix="${1}"
  if [ -n "${prefix}" ] ; then
    keyfile="${prefix}-${DOMAIN_TOKEN}"
  else
    keyfile="${DOMAIN_TOKEN}"
  fi
  openssl x509 -req -sha256 -days 3650 -in "${KEYDIR}/${keyfile}.csr" -signkey "${KEYDIR}/${keyfile}.key" -out "${KEYDIR}/${keyfile}.crt"
}

aws_request_certificate () {
  BASE_DOMAIN=$1
  VALIDATION_DOMAIN=$2

  if [ -z "${VALIDATION_DOMAIN}" ] ; then
    VALIDATION_DOMAIN=${BASE_DOMAIN}
  fi

  arn=`aws acm request-certificate \
     --domain-name \*.${BASE_DOMAIN} --subject-alternative-names \*.apps.${BASE_DOMAIN} \*.system.${BASE_DOMAIN} \
           \*.login.system.${BASE_DOMAIN} \*.uaa.system.${BASE_DOMAIN} \
     --domain-validation-options DomainName=\*.${BASE_DOMAIN},ValidationDomain=${VALIDATION_DOMAIN} DomainName=\*.apps.${BASE_DOMAIN},ValidationDomain=${VALIDATION_DOMAIN} \
           DomainName=\*.system.${BASE_DOMAIN},ValidationDomain=${VALIDATION_DOMAIN} DomainName=\*.login.system.${BASE_DOMAIN},ValidationDomain=${VALIDATION_DOMAIN} \
           DomainName=\*.uaa.system.${BASE_DOMAIN},ValidationDomain=${VALIDATION_DOMAIN} \
     --idempotency-token AwsPcf | jq --raw-output '.CertificateArn'`
  echo $arn
}
