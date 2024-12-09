#!/bin/bash
# KPMG Confidential

#============ Cmn Resource Group ============

function getVnetResourceGroup () {
    env=$1
    echo "JP-RG-JPE-CoreNetworking"
}

function createVNetName () {
    region=$1
    env=$2
    dept=$3
    appName=$4

    # ITS の作業負荷が大きいので、DEVに関しては、vnet を作り直さず
    # 命名ルールが fix する前の名前になったので、分岐
    if [ "${env}" = "DEV" ]; then
        echo "JP-VNET-JPE-dev-di"
    elif [ "${env}" = "PRD" ]; then
        echo "JP-VNET-JPE-prd-di"
    else
        echo "JP-vnet-${region}-${env}-${dept}-${appName}"
    fi
}

function createSubnetName () {
    env=$1
    appName=$2
    desc=$3
    echo "JPSN${env}${appName}${desc}"
}

function getLocation() {
    region=$1
    if [ "${region}" = "JPE" ]; then
        echo "japaneast"
    elif [ "${region}" = "JPW" ]; then
        echo "japanwest"   
    elif [ "${region}" = "EUS" ]; then
        echo "eastus"               
    elif [ "${region}" = "EAS" ]; then
        echo "eastasia"                       
    elif [ "${region}" = "CAE" ]; then
        echo "canadaeast"       
    elif [ "${region}" = "WUS" ]; then
        echo "westus"                             
    fi   
}

function createResourceGroupName () {
    region=$1
    env=$2
    dept=$3
    appName=$4
    descPrefix=$5
    descSuffix=$6
    if [ -z "${descSuffix}" ]; then
        echo "JP-rg-${region}-${env}-${dept}-${appName}-${descPrefix}"
    else
        echo "JP-rg-${region}-${env}-${dept}-${appName}-${descPrefix}-${descSuffix}"
    fi
}


function getSide () {
    resourceGroupPrefix=$1
    resourceGroupNameList=$(az group list --query "[?starts_with(name, \`${resourceGroupPrefix}\`)].tags.Side" -otsv)
    resourceGroupCount=$(echo ${resourceGroupNameList} | tr "" "\n" | wc -l )
    if [ ${resourceGroupCount} -eq 0 ]; then
        side="A"
    elif [ ${resourceGroupCount} -eq 1 ]; then
        if [ ${resourceGroupNameList} = "A" ]; then
            side="B"
        else
            side="A"
        fi
    else
        side="ERROR"
    fi    
    echo $side
}


function getResourceGroupName () {
    resourceGroupName=$1
    resourceGroupName=$(getResourceGroupNameList ${resourceGroupName} | tr " " "\n" | sort | tail -1)
    echo ${resourceGroupName}
}

function getResourceGroupNameList () {
    resourceGroupName=$1
    resourceGroupNameList=$(az group list --query "[?starts_with(name, \`${resourceGroupName}\`)].name" -otsv)
    echo ${resourceGroupNameList}
}

function createStorageAccountName () {
    isPrivate=$1
    region=$2
    env=$3
    dept=$4
    appName=$5
    desc=$6
    seqNumber=$7

    lowerRegion=$(echo ${region,,}) 
    lowerEnv=$(echo ${env,,}) 
    lowerDept=$(echo ${dept,,}) 


    if [ -z seqNumber ]; then
        seqNumber="001"
    fi
    if [ ${isPrivate} = "True" ]; then
        echo "jpst${lowerRegion}${lowerEnv}${lowerDept}${appName}${desc}${seqNumber}"
    else      
        echo "kpmgjpst${lowerRegion}${lowerEnv}${lowerDept}${appName}${desc}${seqNumber}"
    fi
}

function createStorageAccountNameWithIncrementSeqNumber () {
    isPrivate=$1
    region=$2
    env=$3
    dept=$4
    appName=$5
    desc=$6
    initialSeqNumber=$7

    if [ ${isPrivate} = "True" ]; then
        storageAccountNamePrefix="jp${env}sa${appName}${desc}"
    else      
        storageAccountNamePrefix="kpmgjp${env}sa${appName}${desc}"
    fi
    nameList=$(az storage account list --query "[?starts_with(name, \`${storageAccountNamePrefix}\`)].name" -otsv)
    seqNumber=$(echo ${nameList}  | tr " " "\n" | sort | tail -1 | sed -e 's/[^0-9]//g')
    incr=$(expr ${seqNumber} + 1)
    paddingSeqNumber=$(printf "%03d" ${incr})
    createStorageAccountName ${isPrivate} ${env} ${appName} ${desc} ${paddingSeqNumber}
}

function createPrivateEndpointName() {
    region=$1
    env=$2
    dept=$3
    appName=$4
    desc=$5
    echo "JP-pep-${region}-${env}-${dept}-${appName}-${desc}"
}

function createKeyVaultName() {
    region=$1
    env=$2
    dept=$3
    appName=$4
    desc=$5
    if [ -z "${desc}" ]; then
        echo "JP-kv-${region}-${env}-${dept}-${appName}"
    else
        echo "JP-kv-${region}-${env}-${dept}-${appName}-${desc}"
    fi        
}

function createUserAssignedIdentityName() {
    region=$1
    env=$2
    dept=$3
    appName=$4
    desc=$5
    if [ -z "${desc}" ]; then
        echo "JP-id-${region}-${env}-${dept}-${appName}"
    else
        echo "JP-id-${region}-${env}-${dept}-${appName}-${desc}"
    fi    
}

function createContainerRegistryName (){
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5
    lowerRegion=$(echo ${region,,}) 
    lowerEnv=$(echo ${env,,}) 
    lowerDept=$(echo ${dept,,}) 
    echo "jpcr${lowerRegion}${lowerEnv}${lowerDept}${appName}${desc}"
}

#============ Backend Resource Group ============

function createStorageQueueName() {
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5

    if [ -z "${desc}" ]; then
        echo "JP-sq-${region}-${env}-${dept}-${appName}"
    else
        echo "JP-sq-${region}-${env}-${dept}-${appName}-${desc}"
    fi
}

function createFunctionsName () {
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5

    if [ -z ${desc} ]; then
        echo "JP-func-${region}-${env}-${dept}-${appName}"
    else 
        echo "JP-func-${region}-${env}-${dept}-${appName}-${desc}"        
    fi
}   


#============ Rest Resource Group ============


function defineFunctionsTarget () {
    isBackend=$1
    if [ ${isBackend} = "True" ]; then
        echo "back"
    else
        echo "rest"
    fi
}

#============ Rest Resource Group ============


function createAgwName () {
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5
    if [ -z ${desc} ]; then
        echo "JP-agw-${region}-${env}-${dept}-${appName}"
    else 
        echo "JP-agw-${region}-${env}-${dept}-${appName}-${desc}"        
    fi
}

function createPublicIpName () {
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5
    if [ -z ${desc} ]; then
        echo "JP-pip-${region}-${env}-${dept}-${appName}"
    else 
        echo "JP-pip-${region}-${env}-${dept}-${appName}-${desc}"        
    fi
}

#============ SWA Resource Group ============
function createSwaName () {
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5
    if [ -z ${desc} ]; then
        echo "JP-stapp-${region}-${env}-${dept}-${appName}"
    else 
        echo "JP-stapp-${region}-${env}-${dept}-${appName}-${desc}"        
    fi
}

#============ App Service Plan Resource ============
function createAppServicePlanName () {
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5
    if [ -z ${desc} ]; then
        echo "JP-asp-${region}-${env}-${dept}-${appName}"
    else 
        echo "JP-asp-${region}-${env}-${dept}-${appName}-${desc}"        
    fi
}


#============ WebApp Resource Group ============
function createWebAppName () {
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5
    if [ -z ${desc} ]; then
        echo "JP-app-${region}-${env}-${dept}-${appName}"
    else 
        echo "JP-app-${region}-${env}-${dept}-${appName}-${desc}"        
    fi
}

#============ Azure Open AI ============
function createOaiName () {
    region=$1
    env=$2
    dept=$3
    appName=$4    
    desc=$5
    if [ -z ${desc} ]; then
        echo "JP-oai-${region}-${env}-${dept}-${appName}"
    else 
        echo "JP-oai-${region}-${env}-${dept}-${appName}-${desc}"        
    fi
}

#============ Log Analytics Workspace ============
function createLogAnalyticsWorkspaceName() {
    region=$1
    env=$2
    dept=$3
    appName=$4
    desc=$5

    if [ -z "${desc}" ]; then
        echo "JP-log-${region}-${env}-${dept}-${appName}"
    else
        echo "JP-log-${region}-${env}-${dept}-${appName}-${desc}"
    fi
    
}

#============ Application Insights ============
function createApplicationInsightsName() {
    region=$1
    env=$2
    dept=$3
    appName=$4
    desc=$5

    if [ -z "${desc}" ]; then
        echo "JP-appi-${region}-${env}-${dept}-${appName}"
    else
        echo "JP-appi-${region}-${env}-${dept}-${appName}-${desc}"
    fi
}

#============ DDOS Protection Plan ============
function createDdosProtectionPlanName() {
    region=$1
    env=$2
    dept=$3
    appName=$4
    desc=$5
    if [ -z "${desc}" ]; then
        echo "JP-dpp-${region}-${env}-${dept}-${appName}"
    else
        echo "JP-dpp-${region}-${env}-${dept}-${appName}-${desc}"
    fi
}

#============ Action Group Name ============
function createActionGroupName() {
    region=$1
    env=$2
    dept=$3
    appName=$4
    desc=$5
    if [ -z "${desc}" ]; then
        echo "JP-ag-${region}-${env}-${dept}-${appName}"
    else
        echo "JP-ag-${region}-${env}-${dept}-${appName}-${desc}"
    fi
}

#============ Alert Rule Name ============
function createAlertRuleName() {
    region=$1
    env=$2
    dept=$3
    appName=$4
    desc=$5
    resourceName=$6
    if [ -z "${desc}" ]; then
        echo "JP-MNT-${region}-CH-${env}-${dept}-${appName}"
    else
        echo "JP-MNT-${region}-CH-${env}-${dept}-${appName}-${desc}-${resourceName}"
    fi
}

#============ UTIL ============

# application の client id を取得
function getApplicationClientId () {
    env=$1
    if [ "${env}" = "DEV" ]; then
        echo "8dae3f4b-1318-4d8b-929f-46db2ef8d6ad"
    elif [ "${env}" = "QA" ]; then
        echo "1898ebd0-36b5-49ab-81df-73162b5b23ed"
    elif [ "${env}" = "STG" ]; then
        echo "8e2a7abd-0b5d-4bae-8e2c-ac5fbb2b4ddd"
    elif [ "${env}" = "PRD" ]; then
        echo "d298a35d-4d60-40c4-a8f4-e1fed8a54b78"
    fi
}

# Azure AD で各グループで許可するグループを選択
function getGroupObjectId () {
    env=$1
    if [ "${env}" = "DEV" ]; then
        echo "44897fd1-6a17-4042-9389-da0b69f85194"
    elif [ "${env}" = "QA" ]; then
        echo "019151f0-b66c-415e-ad47-b1e45942f905" # JP-SG AAD APP - JP - DI - AIC - PRD - Default Access
    elif [ "${env}" = "STG" ]; then
        echo "019151f0-b66c-415e-ad47-b1e45942f905" # JP-SG AAD APP - JP - DI - AIC - PRD - Default Access
    elif [ "${env}" = "PRD" ]; then
        echo "019151f0-b66c-415e-ad47-b1e45942f905" # JP-SG AAD APP - JP - DI - AIC - PRD - Default Access
    fi
}

# IPアドレス表記 -> 32bit値 に変換
function ip2decimal(){
    local IFS=.
    local c=($1)
    printf "%s\n" $(( (${c[0]} << 24) | (${c[1]} << 16) | (${c[2]} << 8) | ${c[3]} ))
}

# 32bit値 -> IPアドレス表記 に変換
function decimal2ip(){
    local n=$1
    printf "%d.%d.%d.%d\n" $(($n >> 24)) $(( ($n >> 16) & 0xFF)) $(( ($n >> 8) & 0xFF)) $(($n & 0xFF))
}

# CIDR 表記のネットワークアドレスを 32bit値に変換
function cidr2decimal(){
    printf "%s\n" $(( 0xFFFFFFFF ^ ((2 ** (32-$1))-1) ))
}

function iplist(){
    local num=$(ip2decimal $1)
    local max=$(($num + $2 - 1))

    while :
    do
        decimal2ip $num
        [[ $num == $max ]] && break || num=$(($num+1))
    done
}

function culc_mask() {
	A=$1

	C=$(( 2**(32-$A)-1 ))
	D=$(( 0xFFFFFFFF^$C ))

	E1=$(( $D>>24 ))
	E2=$(( ($D>>16) & 0xFF ))
	E3=$(( ($D>>8) & 0xFF ))
	E4=$(( $D & 0xFF ))

	echo $E1.$E2.$E3.$E4
}

function get_next_private_ip(){
    vnetResourceGroupName=$1
    vnetName=$2
    agwSubnetName=$3
    skipNum=$4

    if [ -z "${skipNum}" ]; then
        skipNum=0
    fi
    skipNum=$(expr ${skipNum} + 5)

    subnetIp=$(az network vnet subnet show -g ${vnetResourceGroupName} --vnet-name ${vnetName} -n ${agwSubnetName} --query "addressPrefix" -otsv | cut -d / -f1)
    cidr=$(az network vnet subnet show -g ${vnetResourceGroupName} --vnet-name ${vnetName} -n ${agwSubnetName} --query "addressPrefix" -otsv | cut -d / -f2)
    mask=$(culc_mask cidr)
    count=$(az network application-gateway list --query "[] | length(@)")
    nextIp=$(decimal2ip $(( $(ip2decimal $subnetIp) & $(cidr2decimal $cidr) )))
    nextIp=$(iplist ${nextIp} ${skipNum} | tail -1)
    echo ${nextIp}
}


function createSqlServerName (){
    region=$1
    env=$2
    dept=$3
    desc=$4
    echo JP-sql-${region}-${env}-${dept}-${desc}
}

function createSqlDbName (){
    region=$1
    env=$2
    dept=$3
    desc=$4
    echo JP-sqldb-${region}-${env}-${dept}-${desc}
}
