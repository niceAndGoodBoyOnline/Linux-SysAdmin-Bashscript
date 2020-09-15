#!/bin/bash
SCRIPT=$0

helpInfo(){
echo -e "\n${SCRIPT:2:16} usage:"
echo -e "       Usernames can contain all letters and digits 0 to 9\n"
echo -e "   [OPTIONS]"
echo -e "\n         -a: set the usernames of your administrative users. Accepts up to 3 arguments which correspond to the departments in this order: Engineering, Sales and IS."
echo -e "\n         -e: set the usernames of your regular Engineering employes. No Limit to amount of arguments (employees) you can have!"
echo -e "\n         -s: set the usernames of your regular Sales employes. No Limit to amount of arguments (employees) you can have!"
echo -e "\n         -i: set the usernames of your regular IS employes. No Limit to amount of arguments (employees) you can have!\n\n"
}

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
    helpInfo
fi

read -p "Press enter to run script..."

groupList=(Engineering Sales IS)
adminUsers=(engAdmin salesAdmin isAdmin)
engUsers=(engAdmin engUser1 engUser2)
salesUsers=(salesAdmin salesUser1 salesUser2)
isUsers=(isAdmin isUser1 isUser2)

insertAdmins(){
    engUsers[0]=${adminUsers[0]} && salesUsers[0]=${adminUsers[1]} && isUsers[0]=${adminUsers[2]}
}

while [ -n "$1" ]; do
    if [ "$1" = "-a" ]; then
        shift 1
        for i in ${!adminUsers[*]}; do 
            if [ -n "$1" ] && [ "${1::1}" != "-" ]
            then
                adminUsers[$i]="$1"
                                shift 1
            else 
                break
            fi
        done
        insertAdmins
    elif [ "$1" = "-e" ]; then
    shift 1
    unset engUsers && engUsers=(${adminUsers[0]})
    while [ -n "$1" ] && [ "${1::1}" != '-' ]; do
        engUsers+=("$1")
        shift 1
    done
    elif [ "$1" = "-s" ]; then
        shift 1
        unset salesUsers && salesUsers=(${adminUsers[1]})
        while [ -n "$1" ] && [ "${1::1}" != '-' ]; do
            salesUsers+=("$1")
            shift 1
        done

   elif [ "$1" = "-i" ]; then
        shift 1
        unset isUsers && isUsers=(${adminUsers[2]})
        while [ -n "$1" ] && [ "${1::1}" != '-' ]; do
            isUsers+=("$1")
            shift 1
        done
    else
        shift 1
    fi
done

cd /
echo "Sanitizing..."

cleanUpFolders(){
    for group in $groupList; do
        rm -rf ${groupList[$group]}
    done
}
cleanUpFolders

makeGroupList(){
    sudo cat /etc/passwd | awk -F':' '{ print $1}' | xargs -n1 groups > ~/tmpgrouplist.txt
}

makeGroupList

engClean(){
    uList=$(grep 'Engineering' ~/tmpgrouplist.txt | cut -d ':' -f1)
    for user in $uList; do
        deluser -q --remove-home $user
    done
    groupdel Engineering
    rm -rf /Engineering
}

salesClean() {

    uList=$(grep 'Sales' ~/tmpgrouplist.txt | cut -d ':' -f1)
    for user in $uList; do
        deluser -q --remove-home $user
    done
    groupdel Sales
    rm -rf /Sales
}

isClean() {
    uList=$(grep 'IS' ~/tmpgrouplist.txt | cut -d ':' -f1)
    for user in $uList; do
        deluser -q --remove-home $user
    done
    groupdel IS
    rm -rf /IS
}

g1=$(grep '^Engineering' /etc/group)
g2=$(grep '^Sales' /etc/group)
g3=$(grep '^IS' /etc/group)

if [ -n "$g1" ]
then
    echo -e "Engineering group found, deleting all users and group"
    engClean
fi


if [ -n "$g2" ]
then
    echo -e "Sales group found, deleting all users and group"
    salesClean
fi

if [ -n "$g3" ]
then
    echo -e "IS group found, deleting all users and group"
    isClean
fi

echo "... complete!"

echo -e "Adding groups & users"

makeGroupsAndUsers(){
    for group in ${!groupList[*]}; do groupadd ${groupList[$group]}; done
    for user in ${engUsers[*]}; do useradd -m -g Engineering -s /bin/bash $user; done
    for user in ${salesUsers[*]}; do useradd -m -g Sales -s /bin/bash $user; done
    for user in ${isUsers[*]}; do useradd -m -g IS -s /bin/bash $user; done
}

makeGroupsAndUsers

makeFileStructure(){
    echo "Creating /Engineering, /Sales and /IS directories"
    mkdir /Engineering /Sales /IS
    echo -e "Adding file.txt to group workspaces"
    wString="This file contains confidential information for the department."
    echo $wString > /Engineering/file.txt
    echo $wString > /Sales/file.txt
    echo $wString > /IS/file.txt
}

makeFileStructure

modifyPermissions(){
    echo -e "Adjusting permissions for workspaces and files"

    for user in ${engUsers[*]}; do mkdir /Engineering/$user && chown $user /Engineering/$user; done
    for user in ${salesUsers[*]}; do mkdir /Sales/$user && chown $user /Sales/$user; done
    for user in ${isUsers[*]}; do mkdir /IS/$user && chown $user /IS/$user; done
    for ((i=0; i<3; i++)); do chown ${adminUsers[$i]} ./${groupList[$i]}; chown ${adminUsers[$i]} ./${groupList[$i]}/file.txt; done
    for group in ${groupList[*]}; do chgrp -R $group /$group; chmod -R 750 /$group; done
}

modifyPermissions
makeGroupList

read -r -p "Display information that will help you mark? y/n:    " response
    if [ ${response::1} = 'y' ] || [ ${response::1} = 'Y' ]
    then

    echo -e "\nEngineering workspace:"
    ls -la /Engineering
    echo -e '\nSales workspace:'
    ls -la /Sales
    echo -e '\nIS workspace'
    ls -la /IS

    echo -e "\nDisplaying Engineering group members"
    grep 'Engineering' ~/tmpgrouplist.txt
    echo -e "\nDisplaying Sales group"
    grep 'Sales' ~/tmpgrouplist.txt
    echo -e "\nDisplaying IS group"
    grep 'IS' ~/tmpgrouplist.txt
    echo ""
fi

read -r -p "Remove groups, users, files and folders this script created? y/n:  " response
if [ ${response::1} = 'y' ] || [ ${response::1} = 'Y' ]
then
    echo "Deleting Engineering, Sales, IS files, folders and users"
    engClean
    salesClean
    isClean
fi

rm ~/tmpgrouplist.txt
echo -e "\n    ◕ ◡ ◕     Goodbye, $USER\n"
