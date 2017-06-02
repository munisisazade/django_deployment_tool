#!/bin/bash
# Author Munis Isazade Django developer
VERSION="0.1"

function usage {
    echo -e "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"
    echo -e "\t Django Deployment Tool v$VERSION"
    echo -e "\t Munis Isazade - munisisazade@gmail.com"
    echo -e "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"
    echo -e "Usage: bash $0 <COMMAND>"
    echo -e "\nCommands:"

    echo -e "\t flush \t\t\t\t - For completely flushing DB"
    echo -e "\t delete \t\t\t - Delete DB"
    echo -e "\t create \t\t\t - Create DB"
    echo -e "\t upgrade \t\t\t - Upgrade cluster version of PostgreSQL to $POSTGRESQL_UPGRADE_TO"
    echo -e "\t dump <DIR> \t\t\t - Dump DB to given folder"
    echo -e "\t restore <SRC> \t\t\t - Restore DB from given SQL file"

    exit 1
}


function create_user {
    echo -e "Ubuntu Update apt package ...."
    #apt-get update
    echo -e "Creating new User for $(uname -a)"
    echo "APP_SERVER=$(curl -4 https://icanhazip.com/)" >> "config.txt"
    echo -e "Please write New Linux User name and password"
    read -p "Please enter your linux username: " APP_USER
    while true ; do
    if [ $APP_USER ]; then
        break
    fi
    read -p "Please enter your linux username: " APP_USER
    done
    echo "APP_USER=$APP_USER" >> "config.txt"
    read -s "Please enter your linux user password: " APP_USER_PASSWORD
    while true ; do
    if [ $APP_USER_PASSWORD ]; then
        break
    fi
    read -s "Please enter your linux user password: " APP_USER_PASSWORD
    done
    echo "APP_USER_PASSWORD=$APP_USER_PASSWORD" >> "config.txt"
    echo -e "Creating new user"

}
################
#### START  ####
################

COMMAND=${@:$OPTIND:1}
ARG1=${@:$OPTIND+1:1}


#CHECKING PARAMS VALUES
case ${COMMAND} in

	flush)

		delete_database
		create_database

	;;

	delete)

		delete_database

	;;

	create)

		create_database

	;;

	upgrade)

		upgrade_cluster

	;;

	dump)

        # if path not provided show usage message
	    if [ "$#" -ne 2 ]; then
            usage
        fi

        FILE_DST=${ARG1}
		dump_to_destination ${FILE_DST}

	;;

	restore)

        # if source not provided show usage message
	    if [ "$#" -ne 2 ]; then
            usage
        fi

        FILE_SRC=${ARG1}
		restore_from_source ${FILE_SRC}

	;;
    case)
        create_user
    ;;
    *)

        if [[ $COMMAND != "" ]]; then
            echo "Error: Unknown command: $COMMAND"
            ERROR_STATUS=1
        fi
        usage

    ;;
esac

exit $ERROR_STATUS