#!/bin/sh

# Copyright (C) 2018 Julien Recurt <julien@recurt.fr>
# 
# This file is part of kube-backup
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>


## Usage / Parse A
usage(){
	echo -e 'Backup kubernetes cluster configuration as yaml'
	echo -e ''
	echo -e ${0}
	echo -e '\t-h | --help'
	echo -e '\t--commit-message="message" | -m="message"'
	echo -e '\t--directory="dump" | -d="dump"'
	echo -e '\t--kubectl-opts="" | -o=""'
	echo -e ''
}

# Parse args
COMMIT_MESSAGE="Backup `date`"
OUTPUT_DIR='dump'
EXTRA_KUBECTL_OPTS=''
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage ${0}
            exit
            ;;
        --directory | -d)
            OUTPUT_DIR=$VALUE
            ;;
        --commit-message | -m)
            COMMIT_MESSAGE=$VALUE
            ;;
        --kubectl-opts | -o)
            EXTRA_KUBECTL_OPTS=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

## Preflight checks.
GIT_BIN=`which git`
KUBECTL_BIN=`which kubectl`
JQ_BIN=`which jq`

if [ ! -x ${GIT_BIN} ]
then
	>&2 echo "Error: git binary not found"
	exit 1
fi
if [ ! -x ${KUBECTL_BIN} ]
then
	>&2 echo "Error: kubectl binary not found"
	exit 1
fi
if [ ! -x ${JQ_BIN} ]
then
	>&2 echo "Error: jq binary not found"
	exit 1
fi

# Append options to kubectl binary
KUBECTL_BIN="${KUBECTL_BIN} ${EXTRA_KUBECTL_OPTS}"

## Main script
get_ressources()
{
  ${KUBECTL_BIN} get $2 --export=true -o json -n $1 | jq --raw-output '.items[].metadata.name'
}

get_ressources_config()
{
  echo "Dumping ${1}/${2}/${3}.yaml"
  ${KUBECTL_BIN} get $2 --export=true -o yaml -n $1 > ${1}/${2}/${3}.yaml
}

get_namespaces()
{
  ${KUBECTL_BIN} get namespace -o json --all-namespaces | jq --raw-output '.items[].metadata.name'
}

mkdir -p ${OUTPUT_DIR} && cd ${OUTPUT_DIR} || (>&2 echo "Error: Failed to access '${OUTPUT_DIR}' directory" && exit 0)

# Is the output directory an git repository ?
git rev-parse --is-inside-work-tree > /dev/null 2>/dev/null
if [ $? -ne 0 ]
then
	# Initialize an new repository
	git init . > /dev/null 2>/dev/null
fi

# Please don't be mad about this.
echo " >>> Cleanup"
rm -fr *

echo " >>> Dumping global cluster definitions"
${KUBECTL_BIN} get namespaces --export=true -o yaml > namespaces.yaml
${KUBECTL_BIN} get nodes --export=true -o yaml > nodes.yaml

echo " >>> Fetching cluster namespaces"
NAMESPACES=`get_namespaces`

# Maybe this will extend in a future ?
RESSOURCES="roles rolebinding storageclasses cronjob daemonset deployment job pod replicaset replicationcontroller statefulset ingress service configmap persistentvolumeclaim secret"

for CUR_NAMESPACE in ${NAMESPACES}
do
	echo " >>> Working on namespace ${CUR_NAMESPACE}"
	mkdir -p ${CUR_NAMESPACE}
	for RESSOURCE in ${RESSOURCES}
	do
		mkdir -p ${CUR_NAMESPACE}/${RESSOURCE}
		RESSOURCES_NAMES=`get_ressources ${CUR_NAMESPACE} ${RESSOURCE}`
		for RESSOURCES_NAME in ${RESSOURCES_NAMES}
		do
			get_ressources_config ${CUR_NAMESPACE} ${RESSOURCE} ${RESSOURCES_NAME}
		done
	done
done
git add .
git commit -am "${COMMIT_MESSAGE}"

# KTHXBYE
