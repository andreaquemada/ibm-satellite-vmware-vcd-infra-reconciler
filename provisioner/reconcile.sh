#!/usr/bin/env bash
# ASSUMES LOGGED INTO APPROPRIATE IBM CLOUD ACCOUNT: TO DO THAT AUTOMATICALLY
# ibmcloud login -a https://cloud.ibm.com --apikey XXXX -r us-south
set +x
source config.env
set -x
export LOCATION_ID=satellite-location-test
core_machinegroup_reconcile() {
	export INSTANCE_DATA=/tmp/instancedata.txt
	rm -f "$INSTANCE_DATA"
	touch "$INSTANCE_DATA"
	if ! pwsh -f get_infra.ps1; then
		return
	fi
	if ! grep "success" "$INSTANCE_DATA"; then
		return
	fi
	RP_FILTER_PREFIX=$(echo "$HOST_LABELS" | awk -F '=' '{print $2}')
	TOTAL_INSTANCES=$(grep "$RP_FILTER_PREFIX" "$INSTANCE_DATA" | wc -l)
	if ((COUNT > TOTAL_INSTANCES)); then
		NUMBER_TO_SCALE=$((COUNT - TOTAL_INSTANCES))
		if [[ -n "$HOST_LINK_AGENT_ENDPOINT" ]]; then
			SH_FILE_PATH=$(ibmcloud sat host attach --location "$LOCATION_ID" --operating-system "RHEL" --host-label "$HOST_LABELS" --host-link-agent-endpoint "$HOST_LINK_AGENT_ENDPOINT" | grep "register-host")
		else
			SH_FILE_PATH=$(ibmcloud sat host attach --location "$LOCATION_ID" --operating-system "RHEL" --host-label "$HOST_LABELS" | grep "register-host")
		fi
		if [[ "$SH_FILE_PATH" != *".sh" ]]; then
			return
		fi
		for i in $(seq 1 $NUMBER_TO_SCALE); do
			if ! pwsh -f create_machine.ps1; then
				continue
			fi
			if ! execute_attach_script; then
			  continue
			fi
		done
	fi
}

execute_attach_script() {
  # assumes ssh key
  rm -f "$VM_IP_ADDRESS_FILE"
  touch "$VM_IP_ADDRESS_FILE"
  VM_IP_ADDRESS=$(cat "$VM_IP_ADDRESS_FILE")
  ssh root@"${VM_IP_ADDRESS}" hostnamectl set-hostname "$RP_NAME"
  scp "$SH_FILE_PATH" root@"${VM_IP_ADDRESS}":/tmp/
  FILE_NAME=$(echo "$SH_FILE_PATH" | sed 's::.*/::')
  ssh root@"${VM_IP_ADDRESS}" chmod +x /tmp/"${FILE_NAME}"
  ssh root@"${VM_IP_ADDRESS}" /tmp/"${FILE_NAME}" &
}

remove_dead_machines() {
	for row in $(cat "${HOSTS_DATA_FILE}" | jq -r '.[] | @base64'); do
		_jq() {
			# shellcheck disable=SC2086
			echo "${row}" | base64 --decode | jq -r ${1}
		}
		HEALTH_STATE=$(_jq '.health.status')
		NAME=$(_jq '.name')
		if [[ "$HEALTH_STATE" == "reload-required" ]]; then
			export RP_NAME="$NAME"
			if ! pwsh -f delete_infra.ps1; then
				continue
			fi
			ibmcloud sat host rm --location "$LOCATION_ID" --host "$NAME" -f
		fi
	done
}

while true; do
	sleep 10
	echo "reconcile workload"
	export LOCATION_LIST_FILE=/tmp/location-lists.txt
	export HOSTS_DATA_FILE=/tmp/${LOCATION_ID}-hosts-data.txt
	export SERVICES_DATA_FILE=/tmp/${LOCATION_ID}-services-data.txt
	if ! ibmcloud sat locations >$LOCATION_LIST_FILE; then
		continue
	fi
	if ! grep "$LOCATION_ID" /tmp/location-lists.txt; then
		ibmcloud sat location create --name "$LOCATION_ID" --coreos-enabled --managed-from wdc
	fi
	if ! ibmcloud sat hosts --location $LOCATION_ID --output json >$HOSTS_DATA_FILE; then
		continue
	fi
	if ! ibmcloud sat services --location $LOCATION_ID >$SERVICES_DATA_FILE; then
		continue
	fi
	remove_dead_machines
	for FILE in worker-pool-metadata/*/*; do
		CLUSTERID=$(echo ${FILE} | awk -F '/' '{print $(NF-1)}')
		if [[ "$FILE" == *"control-plane"* ]]; then
			source ${FILE}
			core_machinegroup_reconcile
			# ensure machines assigned
			while true; do
				if ! ibmcloud sat host assign --location "$LOCATION_ID" --zone "$ZONE"; then
					break
				fi
				sleep 5
				continue
			done
		else
			CLUSTERID=$(echo ${FILE} | awk -F '/' '{print $(NF-1)}')
			WORKER_POOL_NAME=$(echo ${FILE} | awk -F '/' '{print $NF}' | awk -F '.' '{print $1}')
			source ${FILE}
			if ! grep $CLUSTERID $SERVICES_DATA_FILE; then
				if ! ibmcloud cs cluster create satellite --name $CLUSTERID --location "$LOCATION_ID" --version 4.11_openshift --operating-system REDHAT_8_64; then
					continue
				fi
			fi
			WORKER_POOL_FILE=/tmp/worker-pool-info.txt
			if ! ibmcloud cs worker-pools --cluster $CLUSTERID >$WORKER_POOL_FILE; then
				continue
			fi
			if ! grep "$WORKER_POOL_NAME" $WORKER_POOL_FILE; then
				ibmcloud cs worker-pool create satellite --name $WORKER_POOL_NAME --cluster $CLUSTERID --zone ${ZONE} --size-per-zone "$COUNT" --operating-system REDHAT_8_64
			fi
			if ! ibmcloud cs worker-pool resize --cluster $CLUSTERID --worker-pool $WORKER_POOL_NAME --size-per-zone "$COUNT"; then
				continue
			fi
			core_machinegroup_reconcile
			while true; do
				if ! ibmcloud sat host assign --location "$LOCATION_ID" --cluster "$CLUSTERID" --host-label os=REDHAT_8_64; then
					break
				fi
				sleep 5
				continue
			done
		fi
	done
done
