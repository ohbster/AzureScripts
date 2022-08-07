#!/bin/bash
#mkazvm.sh by Obijah <ohbster@protonmail.com>

function genkeypairs(){
    if [ $# -eq 1 ]; then
        local keyname="$1-KeyPair.pem"
        if [ -f "$keyname" ]; then
            >&2 echo "$keyname already exists. Use it instead? (y/n)"
            read user_sel
            case $user_sel in
            y|Y|yes)
                echo "$keyname"
                ;;
            n|N|no)
                >&2 echo "Quitting"
                return 1
                ;;
            esac
        else
            ssh-keygen -m PEM -t rsa -b 4096 -f "$HOME/.ssh/$keyname"
            chmod 400 $keyname
            echo -e "$keyname"
        fi
        
    else
        echo "genkeypairs requires a name as argument"
        exit 1
    fi

}
function mkazvm(){
#parameterize this function to incase key is local(ssh-key-value) or from azure (ssh-key-name)
    #this will create the VM
    az vm create \
    --name $name_sel \
    --resource-group $rg_sel \
    --image $vmi_sel \
    --size $vm_size \
    --authentication-type "ssh" \
    --ssh-key-values "./$keypair_path" \
    --admin-username $adminuser \
    --no-wait
}

#Arrays for resource groups and images
declare -a resource_groups=()
declare -a vm_images=()

#default selections. should use a config file to load these values
name_sel="myAzureVM"
vmi_sel="ubuntuLTS"
auth_sel=1
adminuser="azureuser" #can set this via flag, no need to prompt for this one
vm_size="standard_b2s" #can prompt for this later, no need now tho.

for x in $(az group list --query '[].name' | tr -d ,[]\" ); do 
        resource_groups+=( $x );
done

for i in ${!resource_groups[@]}; do
    echo -e "$i)\t${resource_groups[$i]}"
done
echo -e "\nSelect a resource group"
read rg_sel
rg_sel=${resource_groups[$user_sel]}

#get available images
for x in $(az vm image list --query '[].urnAlias' | tr -d ,[]\" ); do
    vm_images+=( $x );
done

for i in ${!vm_images[@]}; do
    echo -e "$i)\t${vm_images[$i]}"
done
echo -e "\nSelect a machine image (Default: $vmi_sel)"
read user_sel
if [ -z $user_sel ] 
then 
    echo $vmi_sel
else vmi_sel=${vm_images[$user_sel]}
    
fi

#create name for the vm
echo -e "\nWhat will you name the vm? (Default: $name_sel)"
read user_sel
if [ -z $user_sel ] 
then 
    echo $name_sel
else name_sel=$user_sel
fi

echo -e "\nHow will you authenticate? (Default: $auth_sel)"
echo -e "1)\tGenerate a new key pair"
echo -e "2)\tUse existing key pair stored on Azure"
echo -e "3)\tUse existing local key pair"
read user_sel
if [ -z $user_sel ] 
then 
    echo $auth_sel
else auth_sel=$user_sel
fi
echo $auth_sel
case $auth_sel in
1)
    #echo "we got $(genkeypairs $name_sel)"
    keypair_path=$(genkeypairs $name_sel)
    mkazvm
    ;;
2)
    #echo "Retrieve keypairs from azure"
    declare -a keypairs=()
    for key in $(az sshkey list | tr -d \"[]); do
        keypairs+=( $key );
    done

    for i in ${!keypairs[@]}; do
        echo "$i)\t${$keypairs[$i]}"
    done
    echo "Select a key pair"
    read user_sel
    keyname=${$keypairs[$user_sel]}
    ;;
3)
    echo "Prompt for a filepath to key"
    ;;
*)
    echo "Invalid selection"
    ;;
esac
