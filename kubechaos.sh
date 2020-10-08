#!/bin/bash

# === GLOBAL VARS === #
# ensure namespace defined in CHAOS_SPACE variable is created
# and the app has been deployed into the same namespace
CHAOS_SPACE="chaos"
LOGFILE=/var/log/kubechaos.log
DATETIME=$(date '+%d-%m-%Y %H:%M:%S')
# === === === === === #

kubectl get ns $CHAOS_SPACE 2>/dev/null
if [ $? -ne 0 ]; then
  echo "Failed. Namespace $CHAOS_SPACE not found"
  exit 7
fi

function deleteAll {
    # delete all objects in namespace

    kubectl delete all -n $CHAOS_SPACE
    echo "$DATETIME - DL_ALL - Deleted All Objects"
}

function stopDocker {
    # stop docker service

    systemctl stop docker
    echo "$DATETIME - DCKR - Stopped Service" >> $LOGFILE
}

function deleteRS {
    # delete all replica-sets in CHAOS_SPACE

    kubectl delete rs --all -n chaos_space
    echo "$DATETIME - DLRS - Deleted relica-sets" >> $LOGFILE
}

function deleteSVC {
    # delete all services in CHAOS_SPACE

    kubectl delete svc --all -n $CHAOS_SPACE
    echo "$DATETIME - DLSVC - Deleted services" >> $LOGFILE
}

function addNetpol {
    # add network policy to block traffic into pod/namespace

    TMPFILE=.tmp_netpol.yml
    sed "s/\^namespace\^/$CHAOS_SPACE/g" templates/template-netpol.yml > $TMPFILE

    if [ $? -eq 0 ]; then
      echo "$DATETIME - NETPOL - Config Applied" >> $LOGFILE
    fi

    rm $TMPFILE
}

function stopKubelet {
    # stop kubelet service

    systemctl stop kubelet
    echo "$DATETIME - KBLET - Stopped Service" >> $LOGFILE
}

# all functions in array style
declare -a FUNCTIONS=('stopKubelet' 'addNetpol' 'deleteSVC' 'deleteRS' 'stopDocker' 'deleteAll')

# select random number between 0 and total number of array entries
RNDFUNC=$[$RANDOM % ${#FUNCTIONS[@]}]

# call random function
${FUNCTIONS[$RNDFUNC]}
