#!/bin/bash
CREDHUB_ADMIN_CLIENT_SECRET='HHrsSy2-zo7wGfh5h8waavpU8Bb4uJ64'
RESTRICTED_FIELDS='["defaultLabel","passphrase","baseDir","tryMasterBranch","forcePull","knownHostFile","preferredAuthentications","ignoreLocalSshSettings","cloneSubmodules","deleteUntrackedBranches","repos"]'
OUTPUT_FILE="./output.csv"
echo "ConfigServerSIGuid, AppSpaceGuid, AppSpaceName, BoundAppGuid, BoundAppName" > "$OUTPUT_FILE"



echo "RESTRICTED_FIELDS = $RESTRICTED_FIELDS"

credhub api --server credhub.service.cf.internal:8844 --ca-cert /var/tempest/workspaces/default/root_ca_certificate
credhub login --client-name=credhub_admin_client --client-secret=$CREDHUB_ADMIN_CLIENT_SECRET



bad_config_test() {
    local mirrorDetails="$1"
    local result
    result=$(echo "$mirrorDetails" | jq -r --argjson restricted_fields "$RESTRICTED_FIELDS" 'any(.value.git | keys[]; . as $key | $restricted_fields | contains([$key]))')
    echo $result 
}



# Test using credhub cli to find first config-service SI reference to it's underlying mirror service config
#credhub get -j -n $(credhub find -n p.spring-cloud-services-scs-mirror-service -j | jq -r .credentials[0].name)

#get list of scs-mirror-service instances in Credhub
mirrors=$(credhub find -n p.spring-cloud-services-scs-mirror-service -j | jq -r '.credentials[].name')

for mirror in $mirrors; do
    mirrorDetails=$(credhub get -j -n $mirror)
    echo -n "Mirror ID: "
    echo $mirrorDetails | jq '.id'

    if [[ $(bad_config_test "$mirrorDetails") ]]
    then
      echo  match
            #echo $mirrorDetails | jq .
            mirrorName=$(echo $mirrorDetails | jq -r '.name')
            echo "mirrorName = $mirrorName"
            mirrorSiGuid=$(echo $mirrorName | awk -F'/' '{ print $(NF-1) }')
            echo "mirrorSiGuid = $mirrorSiGuid"
            siSpaceGuid=$(cf curl "/v3/service_instances/$mirrorSiGuid" | jq -r '.relationships.space.data.guid')
            echo "siSpaceGuid = $siSpaceGuid" 
            # Space GUID matches Mirror SI GUID
            siSpaceName=$(cf curl "/v3/spaces/$siSpaceGuid" | jq -r '.name')
            echo "siSpaceName = $siSpaceName"
            # SI Space Name is the Service GUID for the config-server

            # get bound app's by guid tied to this SI
            boundAppGuid=$(cf curl "/v3/service_credential_bindings?service_instance_guids=$siSpaceName" | jq -r '.resources[0].relationships.app.data.guid')
            echo "boundAppGuid = $boundAppGuid"

            appName=$(cf curl /v3/apps/$boundAppGuid | jq -r .name)
            echo "appName = $appName"

            appSpaceGuid=$(cf curl /v3/apps/$boundAppGuid | jq -r .relationships.space.data.guid)
            echo "appSpaceGuid = $appSpaceGuid"

            appSpaceName=$(cf curl /v3/spaces/$appSpaceGuid | jq -r .name)
            echo "appSpaceName = $appSpaceName"

            echo -n "mirrorKeys = " 
            echo "$mirrorDetails" | jq '.value.git | keys'

            
            #echo "RESTRICTED_FIELDS = $RESTRICTED_FIELDS"
            echo "$mirrorDetails" | jq -r --argjson restricted_fields "$RESTRICTED_FIELDS" '[$restricted_fields]'
            #bad_config_found=$(echo "$mirrorDetails" | jq -r --argjson restricted_fields "$RESTRICTED_FIELDS" 'any(.value.git | keys[]; . as $key | $restricted_fields | contains([$key]))')
            bad_config_found=$(bad_config_test "$mirrorDetails")
            echo "bad_config_found=$bad_config_found" 

            if [[ $bad_config_found ]]
            then 
              echo "$siSpaceGuid, $appSpaceGuid, $appSpaceName, $boundAppGuid, $appName" >> "$OUTPUT_FILE"
            fi
    else
      echo no match
    fi
done
