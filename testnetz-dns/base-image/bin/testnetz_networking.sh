#!/bin/bash

set -e

function set_health
{
    path=/etc/testnetz_healthcheck.d/
    mkdir -p ${path}

    file="${path}/${1}"

    cat << EOF > ${file}
#!/bin/bash
exit ${2}
EOF

    chmod +x ${file}
}


function set_bad_health
{
    set_health ${1} 1
}

function set_good_health
{
    set_health ${1} 0
}




echo -n "Test whether TESTNETZ_WAIT_INTERFACE is set: "
if [ ! -z ${TESTNETZ_WAIT_INTERFACE} ]; then
    echo "yes => wait for interface ${TESTNETZ_WAIT_INTERFACE}..."

    hc=wait_for_interfaces
    set_bad_health ${hc}

    /usr/local/bin/pipework --wait -i ${TESTNETZ_WAIT_INTERFACE}

    set_good_health ${hc}
else
    echo "no => don't wait for any interface to appear (might result in startup errors)..."
fi


echo -n "Test whether TESTNETZ_GATEWAY is set: "

if [ ! -z ${TESTNETZ_GATEWAY} ]; then
    echo "yes => change default route..."
    
    hc=set_default_gateway
    set_bad_health ${hc}
    
    ip route del default
    ip route add default via ${TESTNETZ_GATEWAY}
    
    set_good_health ${hc}
else
    echo "no => keep existing default route..."
fi

echo -n "default route is now: "
ip route | grep default
