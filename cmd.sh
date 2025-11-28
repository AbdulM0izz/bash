#Print processes with pipe
ps -ef | grep bash

#Grep print entire output if need any specfic info use awk
ps -ef | grep bash | awk '{print $2}   #print only colums 2


set -x #debug mode
set -e #exit the script when theres error in script
if therers pipie it will not exit on error for this we aslo need to use 
set -o pipefail 

curl url #reterive info from internet
