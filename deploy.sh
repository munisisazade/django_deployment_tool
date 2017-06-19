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

    echo -e "\t usage \t\t\t\t - For helping available commands to use"
    echo -e "\t deploy \t\t\t\t - Base command to deployment"
    echo -e "\t status \t\t\t\t - Show status of deployment"
    echo -e "\t delete \t\t\t - Delete DB"
    echo -e "\t create \t\t\t - Create DB"
    echo -e "\t upgrade \t\t\t - Upgrade cluster version of PostgreSQL to $POSTGRESQL_UPGRADE_TO"
    echo -e "\t dump <DIR> \t\t\t - Dump DB to given folder"
    echo -e "\t restore <SRC> \t\t\t - Restore DB from given SQL file"

    exit 1
}

function deployment_status() {
    . config.txt
    if [[ $APP_USER && $APP_USER_PASSWORD ]]; then
        echo -e "Current deploy status:"
        echo -e "\n"
        echo -e "\nDjango\t\t\t\t\tAlready Deploy"
        echo -e "\n"
        echo -e "The Application is ready to use please use"
        echo -e "Change the user by command sudo su - $APP_USER"
    else
        echo -e "Current deploy status:"
        echo -e "\n"
        echo -e "Django\t\t\t\t\tnot deploy"
        echo -e "\n"
        echo -e "The Application is not Deploy please use ./deploy.sh deploy"
    fi


}


function get_user_credential {
    echo -e "Ubuntu Update apt package ...."
    chmod +x config.txt
    apt-get -y update
    apt-get -y install python-pip python-dev libpq-dev postgresql postgresql-contrib nginx
    apt-get -y update
    apt-get -y install python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx
    apt-get -y python3-venv
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
    echo -e "Please enter your linux user password: "
    read -s APP_USER_PASSWORD
    while true ; do
    if [ $APP_USER_PASSWORD ]; then
        break
    fi
    read -s APP_USER_PASSWORD
    done
    echo "APP_USER_PASSWORD=$APP_USER_PASSWORD" >> "config.txt"

}


function fix_perl_locale_error() {
    echo -e "Fixing perl  warning: Setting locale error..."
    uname -a
    perl -e exit
    export LANGUAGE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_TYPE=en_US.UTF-8
}

function  create_new_linux_user {
    . config.txt
    if ! getent $APP_USER_PASSWORD $APP_USER  > /dev/null ; then
        echo -e "Creating New Linux User please wait .."
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $APP_USER_PASSWORD)
        useradd -m -p $pass $APP_USER
        echo -e "Users created and add to sudoers"
        echo "$APP_USER  ALL=(ALL:ALL) ALL" >> /etc/sudoers
        echo -e "Successfuly Created user with Bellow credential"
        echo -e "\t Username : \t - $APP_USER"
        echo -e "\t Password : \t - $APP_USER_PASSWORD"
        echo -e "\t Created time \t - $(date)"
    else
        echo -e "Already You was created New user with Bellow credential"
        echo -e "\t Username : \t - $APP_USER"
        echo -e "\t Password : \t - $APP_USER_PASSWORD"
        echo -e "\t Created time \t - $(date)"
    fi

}

function  get_project_details {
    . config.txt
    echo -e "Please Write your projects detailed...."
    apt-get -y update
    echo -e "Creating new User for $(uname -a)"
    echo "APP_SERVER=$(curl -4 https://icanhazip.com/)" >> "config.txt"
    echo -e "Please write your git repository url here"
    read -p "Git Repo(https): " GIT_REPO_URL
    while true ; do
    if [ $GIT_REPO_URL ]; then
        break
    fi
    read -p "Please enter Repo Url(https): " GIT_REPO_URL
    done
    echo "GIT_REPO_URL=$GIT_REPO_URL" >> "config.txt"
    read -p "git root file name : " GIT_ROOT
    while true ; do
    if [ $GIT_ROOT ]; then
        break
    fi
    read -p "Please enter git root file name : " GIT_ROOT
    done
    echo "GIT_ROOT=$GIT_ROOT" >> "config.txt"
    echo -e "Clonig git repository from this url:  $GIT_REPO_URL"
    cd /home/$APP_USER
    git clone $GIT_REPO_URL
    cd $GIT_ROOT
    echo "APP_ROOT_DIRECTOR=$(pwd)" >> "config.txt"
    echo -e "Please Last time write to project name (Django base app name) :"
    read -p "Project name : " APP_NAME
    while true ; do
    if [ $APP_NAME ]; then
        break
    fi
    read -p "Project name : " APP_NAME
    done
    echo "APP_NAME=$APP_NAME" >> "config.txt"






}

function configuration_server() {
    . config.txt
    echo -e "Configuration Nginx credentials.."
    sed -i -e 's|#{APP_SERVER}|'$APP_SERVER'|g' -e 's|#{APP_ROOT_DIRECTORY}|'$APP_ROOT_DIRECTORY'|g' -e 's|#{APP_NAME}|'$APP_NAME'|g' tlp/default
    echo -e "Create nginx default server.."
    cp -r tlp/default /etc/nginx/sites-available/default
    echo -e "Gunicorn file created.."
    sed -i -e 's|#{APP_USER}|'$APP_USER'|g' -e 's|#{APP_ROOT_DIRECTORY}|'$APP_ROOT_DIRECTORY'|g' -e 's|#{APP_NAME}|'$APP_NAME'|g' tlp/gunicorn.service
    cp -r tlp/gunicorn.service /etc/systemd/system/
    echo -e "Everything works cool :)"
}

function create_virtualenv() {
    . config.txt
    cd $APP_ROOT_DIRECTORY
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    pip install -U pip
    python manage.py migrate
    systemctl start nginx
    systemctl start gunicorn
    systemctl restart nginx
    echo "Restarting nginx:                                                    [OK]"
    systemctl restart gunicorn
    echo "Restarting Gunicorn:                                                 [OK]"
    echo "Everything is OK :)"
    echo "---"
    echo "---"
    echo "Deployment ready! Now log into linux user, intialize the virtual environment, \
    start the server and you'll be able to see the django-app!"
    echo "---"
    echo "---"

}


################
#### START  ####
################

COMMAND=${@:$OPTIND:1}
ARG1=${@:$OPTIND+1:1}


#CHECKING PARAMS VALUES
case ${COMMAND} in

    usage)

        usage

    ;;

    status)

        deployment_status

    ;;

    deploy)

        get_user_credential
        fix_perl_locale_error
        create_new_linux_user
        get_project_details
        configuration_server
        create_virtualenv
    ;;

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

    test)
        testing
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
        get_user_credential
        create_new_linux_user
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