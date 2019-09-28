#!/usr/bin/bash 
#This script will list information (cpu,RAM,Storage,Network) about all VM's configured through kvm.
#Output is printed in csv format with following columns hostanme,vm_name/domain_name,vm_storage_size,vm_vcpu_count,vm_mem_size,vm_state

declare -A ALL_VMS_WTHOT_DOT_CHAR_MAP=();
declare -A ALL_VMS_BLK_DEV=();
declare -A ALL_VMS_IF_ADDR=();
declare -A ALL_VMS_STORG_SPACE=();
declare -A ALL_VMS_CPU=();
declare -A ALL_VMS_MEM=();
declare -A ALL_VMS_STATE=();


HYPERVISOR_HOSTNAME="$(hostname)";
ALL_VMS=($(virsh list | awk '{ i++; if(i<=2)next; print $2}'));
ALL_VMS_WTHOT_DOT_CHAR=($(virsh list | awk '{ i++; if(i<=2)next; gsub(/\./,"_",$2); print $2}'));


#Constructing ALL_VMS_WTHOT_DOT_CHAR_MAP Assosiative array with key as "VM Name without . char" and value as VM Name
for((VM_INDEX=0;VM_INDEX<${#ALL_VMS[@]};VM_INDEX++))
do 
#	echo $VM_INDEX;
	ALL_VMS_WTHOT_DOT_CHAR_MAP["${ALL_VMS_WTHOT_DOT_CHAR[$VM_INDEX]}"]=${ALL_VMS[$VM_INDEX]};
done;

#echo $(declare -p ALL_VMS_WTHOT_DOT_CHAR_MAP);

: <<'BLK_CMT'
for VM_NAME in ${!ALL_VMS_WTHOT_DOT_CHAR_MAP[@]}
do 
	echo "key $VM_NAME has value ${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]}";
done;
BLK_CMT

#Finding BLK/Storage Devices attached to VM's
for VM_NAME in ${!ALL_VMS_WTHOT_DOT_CHAR_MAP[@]}
do 
#	ALL_VMS_BLK_DEV["$VM_NAME"]="$(virsh domblklist ${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]} | awk '{ i++; if(i<=2)next; print $2}')";
	ALL_VMS_BLK_DEV["$VM_NAME"]="$(	virsh domblklist ${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]} | awk '$2 !~ /.+qcoww2$|.+qcow2$|.+gcow2$/ { i++; if(i<=2) next;  print $2}')";

done;

#echo "$(declare -p ALL_VMS_BLK_DEV)";

#Finding Storage space of VM's using above calculated block devices. At present, we are assuming only one block device (virtual storage device) configured for each VM. Below Logic needs to be changed , if more than one block device (virtual storage device) configured for each VM.
for VM_NAME in ${!ALL_VMS_WTHOT_DOT_CHAR_MAP[@]}
do
       [[ -n "${ALL_VMS_BLK_DEV[$VM_NAME]}" ]] && { ALL_VMS_STORG_SPACE["$VM_NAME"]="$(virsh domblkinfo ${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]} ${ALL_VMS_BLK_DEV[$VM_NAME]} | awk -F ':' '$1 ~ /Capacity/ { gsub(/\ +/,"",$2); print $2 }')"; };

done;

#echo "$(declare -p ALL_VMS_STORG_SPACE)";

for VM_NAME in ${!ALL_VMS_WTHOT_DOT_CHAR_MAP[@]}
do 
	ALL_VMS_IF_ADDR["$VM_NAME"]="$(virsh domifaddr ${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]} interface | awk '{ i++; if(i<=2)next; print $2}')";
done;

#echo "$(declare -p ALL_VMS_IF_ADDR)";

#Finding virtual cpu's configured for VM's
for VM_NAME in ${!ALL_VMS_WTHOT_DOT_CHAR_MAP[@]}
do 
	ALL_VMS_CPU["$VM_NAME"]="$(virsh domstats --vcpu  ${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]} | awk -F '=' '$1 ~ /vcpu.maximum/ { print $2 }')";
done;

#echo "$(declare -p ALL_VMS_CPU)";

#Finding RAM configured for VM's
for VM_NAME in ${!ALL_VMS_WTHOT_DOT_CHAR_MAP[@]}
do 
	ALL_VMS_MEM["$VM_NAME"]="$(virsh domstats --balloon  ${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]} | awk -F '=' '$1 ~ /balloon.maximum/  { print $2 }')";

done;

#echo "$(declare -p ALL_VMS_MEM)";

#Finding VM's State
for VM_NAME in ${!ALL_VMS_WTHOT_DOT_CHAR_MAP[@]}
do 
	ALL_VMS_STATE["$VM_NAME"]="$(virsh domstate ${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]})"; 

done;

#echo "$(declare -p ALL_VMS_MEM)";

###### printing output #################

for VM_NAME in ${!ALL_VMS_WTHOT_DOT_CHAR_MAP[@]}
do
	printf "${HYPERVISOR_HOSTNAME},${ALL_VMS_WTHOT_DOT_CHAR_MAP[$VM_NAME]},${ALL_VMS_STORG_SPACE[$VM_NAME]},${ALL_VMS_CPU[$VM_NAME]},${ALL_VMS_MEM[$VM_NAME]},${ALL_VMS_STATE[$VM_NAME]}\n";
done;


exit;


