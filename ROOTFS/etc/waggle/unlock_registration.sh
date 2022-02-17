#!/bin/bash
# Unlock the registration key(s)

BEEHIVE_KEY=/etc/waggle/id_rsa_waggle_registration
BEEHIVE_KEY_ENC=${BEEHIVE_KEY}.enc
BEEHIVE_CHECKSUM=5fd9b3233c94e6b17f67120222c1e765530cb149
BEEKEEPER_KEY=$(waggle-get-config -s registration -k key)
BEEKEEPER_KEY_ENC=${BEEKEEPER_KEY}.enc
BEEKEEPER_CHECKSUM=$(waggle-get-config -s registration -k keychecksum)
AGENT_KEY=/root/.ssh/ecdsa-agents
AGENT_KEY_ENC=${AGENT_KEY}.enc
AGENT_CHECKSUM=fe3897e567992d4882feedd6e17546f0b1c5419f

function verify_key() {
    local key=${1}
    local checksum=${2}

    if [[ ! -f ${key} ]]; then
        echo "(Warning) key file [${key}] not found."
        return 1
    fi

    local key_checksum=$(shasum ${key} | cut -d' ' -f1)
    if [[ ${key_checksum} != ${checksum} ]]; then
        echo "(Warning) key file [${key}] checksum failure [${key_checksum} != ${checksum}]"
        return 2
    fi

    return 0
}

function unlock_key() {
    local name=${1}
    local key=${2}
    local keyenc=${3}
    local checksum=${4}

    if verify_key ${key} ${checksum}; then
        echo "${name} registration key correct, nothing to do."
    else
        echo "Please unlock the ${name} registration key [${keyenc}]..."
        if openssl aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in ${keyenc} -out ${key}; then
            chmod 600 ${key}
        fi
        if verify_key ${key} ${checksum}; then
            echo "${name} key [${key}] successfully unlocked!"
        else
            echo "(ERROR) unable to verify unlocked ${name} registration key [${key}]"
        fi
    fi
}

# Beehive key
echo "<< Beehive Key Unlock >>"
unlock_key "Beehive" ${BEEHIVE_KEY} ${BEEHIVE_KEY_ENC} ${BEEHIVE_CHECKSUM}

# Beekeeper key
echo
echo "<< Beekeeper Key Unlock >>"
unlock_key "Beekeeper" ${BEEKEEPER_KEY} ${BEEKEEPER_KEY_ENC} ${BEEKEEPER_CHECKSUM}

# Agent key
echo
echo "<< Node Agent Key Unlock >>"
unlock_key "Node Agent" ${AGENT_KEY} ${AGENT_KEY_ENC} ${AGENT_CHECKSUM}
