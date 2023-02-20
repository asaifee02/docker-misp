#!/bin/bash

[ -z "$GNUPGHOME" ] && GNUPGHOME="/gnupg"
[ -z "$GNUPG_PASSPHRASE" ] && GNUPG_PASSPHRASE="yA15^x#*xJXHW4I3oC2F3FzmD92bMpG%"
[ -z "$GNUPG_EMAIL" ] && GNUPG_EMAIL=$EMAIL
[ -z "$OIDC_ENABLED" ] && OIDC_ENABLED="false"

if [[ ! -d "${GNUPGHOME}" ]]; then
  echo -e "\nCreating Home Directory for GNUPG: ${GNUPGHOME}"
  runuser -u www-data -- mkdir -p ${GNUPGHOME}
  runuser -u www-data -- gpg --batch --gen-key <<EOF
%echo Generating GNUPG key...
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Passphrase: ${GNUPG_PASSPHRASE}
Name-Real: MISP Admin
Name-Email: ${GNUPG_EMAIL}
Expire-Date: 0
%commit
%echo Generated GNUPG Key!
EOF
fi

# Enable OIDC Auth
if [[ "${OIDC_ENABLED}" == "true" ]]; then
  echo -e "\nEnabling OIDC Authentication..."
  sed -i -e "/'salt'/a\    'auth' => 'array('OidcAuth.Oidc')'," $MISP_APP_CONFIG_PATH/config.php
  sed -i -e "$ i\   'OidcAuth' = [\n\
    'offline_access' => true,\n\
    'check_user_validity' => 300,\n\
    'provider_url' => \'${OIDC_PROVIDER_URL}\',\n\
    'client_id' => '${OIDC_CLIENT_ID}',\n\
    'client_secret' => '${OIDC_CLIENT_SECRET}',\n\
    'role_mapper' => [ // if user has multiple roles, first role that match will be assigned to user\n\
        'misp-user' => 3, // User\n\
        'misp-admin' => 1, // Admin\n\
    ],\n\
    'default_org' => '${ORGNAME:-"MY_ORG"}',\n\
  ]," $MISP_APP_CONFIG_PATH/config.php
  cat $MISP_APP_CONFIG_PATH/config.php | grep -i OidcAuth -A 12
  echo -e "\nEnabled OIDC Authentication!"
fi
