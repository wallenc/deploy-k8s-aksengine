#!/bin/bash

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m' 


transform_deployment() {

	extensionBeginCount=15
	extensionEndCount=19
	bracketCount=16
	
	printf "%s\n" "${yel}Tranforming azuredeploy.json from path $1${end}"
	
	aksExtensionLN=$( awk '/Compute.AKS-Engine.Linux.Billing/{ print NR; exit}' $1/azuredeploy.json )

	if [[ ! -z "$aksExtensionLN" ]]; then

		extensionBegin="$(($aksExtensionLN-$extensionBeginCount))"
		extensionEnd="$(($extensionBegin + $extensionEndCount))"

		printf "%s\n" "extensionBegin=$extensionBegin"
		printf "%s\n" "extensionEnd=$extensionEnd"
	
		sed -i ''$extensionBegin,$extensionEnd'd' azuredeploy.json
	
		aksExtensionLN=$( awk '/Compute.AKS-Engine.Linux.Billing/{ print NR; exit}' $1/azuredeploy.json )

		printf "%s\n" "aksextension=$aksExtensionLN"
		bracketLN="$(( $aksExtensionLN - $bracketCount ))"	
		extensionBegin="$(( $aksExtensionLN - $extensionBeginCount ))"
		extensionEnd="$(( $extensionBegin + $extensionEndCount ))"

		printf "%s\n" "bracketLN=$bracketLN"
		printf "%s\n" "2ndextensionb=$extensionBegin"
		printf "%s\n" "2ndextensionEnd=$extensionEnd"
		
		sed -i ''$bracketLN'c\}' azuredeploy.json

        	sed -i ''$extensionBegin,$extensionEnd'd' azuredeploy.json
		sed -i 's;--non-masquerade-cidr=0.0.0.0/0;--non-masquerade-cidr=10.244.0.0/16;g' azuredeploy.json

		printf "%s\n" "${blu}Successfully transformed azuredeploy.json${end}"
	else
		printf "%s\n" "${red}azuredeploy.json already transformed. Nothing to do${end}"
	fi

}


transform_params() {

	printf "%s\n" "${yel}Tranforming azuredeploy.parameters.json from path $1${end}"	
	
	agentImageSKULN=$( awk '/agentpool1osImageSKU/{ print NR+1; exit}' $1/azuredeploy.parameters.json )
	agentImageOfferLN=$( awk '/agentpool1osImageOffer/{ print NR+1; exit}' $1/azuredeploy.parameters.json )
	agentImagePublisherLN=$( awk '/agentpool1osImagePublisher/{ print NR+1; exit}' $1/azuredeploy.parameters.json )
	agentImageVersionLN=$( awk '/agentpool1osImageVersion/{ print NR+1; exit}' $1/azuredeploy.parameters.json )
#	nonMasqCidrLN=$( awk '/kubernetesNonMasqueradeCidr/{ print NR+1; exit}' $1/azuredeploy.parameters.json )
	
	masterOsImageOfferLN=$( awk 'match($1, /"osImageOffer"/){ print NR+1; exit}' azuredeploy.parameters.json )

	masterOsImagePublisherLN=$( awk 'match($1, /"osImagePublisher"/){ print NR+1; exit}' azuredeploy.parameters.json )

	masterOsImageSKULN=$( awk 'match($1, /"osImageSKU"/){ print NR+1; exit}' azuredeploy.parameters.json )

	masterOsImageVersionLN=$( awk 'match($1, /"osImageVersion"/){ print NR+1; exit}' azuredeploy.parameters.json )



	agentImageOffer=$( awk 'FNR=='$agentImageOfferLN'' $1/azuredeploy.parameters.json )
	masterImageOffer=$( awk 'FNR=='$masterOsImageOfferLN'' $1/azuredeploy.parameters.json )

	agentIO="$(cut -d'"' -f4 <<< $agentImageOffer)"
	masterIO="$(cut -d'"' -f4 <<< $masterImageOffer)"


	if [[ ! "$agentIO" == "UbuntuServer" ]] && [[ ! "$masterIO" == "UbuntuServer" ]]; then

		sed -i 's/AzurePublicCloud/AzureUSGovernmentCloud/g' $1/azuredeploy.parameters.json
		sed -i 's/cloudapp.azure.com/cloudapp.usgovcloudapi.net/g' $1/azuredeploy.parameters.json

		sed -i ''$agentImageOfferLN'c\"value": "UbuntuServer"' $1/azuredeploy.parameters.json 
		sed -i ''$agentImagePublisherLN'c\"value": "Canonical"' $1/azuredeploy.parameters.json
		sed -i ''$agentImageSKULN'c\"value": "16.04-LTS"' $1/azuredeploy.parameters.json
		sed -i ''$agentImageVersionLN'c\"value": "latest"' $1/azuredeploy.parameters.json
		sed -i ''$masterOsImageOfferLN'c\"value": "UbuntuServer"' $1/azuredeploy.parameters.json 
		sed -i ''$masterOsImagePublisherLN'c\"value": "Canonical"' $1/azuredeploy.parameters.json
		sed -i ''$masterOsImageSKULN'c\"value": "16.04-LTS"' $1/azuredeploy.parameters.json
		sed -i ''$masterOsImageVersionLN'c\"value": "latest"' $1/azuredeploy.parameters.json
		
		printf "%s\n" "${blu}Successfully transformed azuredeploy.parameters.json${end}"

	else
		printf "%s\n" "${red}azuredeploy.parameters.json already tranformed. Nothing to do${end}"
	fi

}

if [ "$1" =  "--json-path" ]; then

	if [ -f "$2/azuredeploy.json" ] && [ -f "$2/azuredeploy.parameters.json" ]; then

	printf "%s\n" "${grn}Found azuredeploy.json${end}"
	printf "%s\n" "${grn}Found azuredeploy.parameters.json${end}"

	else
	printf "%s\n" "${red}Deployment jsons were not found. Please enter a valid path${end}"
	
	fi

	transform_deployment $2
	transform_params $2

else
	printf "%s\n" "${red}JSON path undefined. Please run the command again and use the --json-path parameter to pass the location of the deployment json files${end}"

return
	
fi

