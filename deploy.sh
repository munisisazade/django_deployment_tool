#!/bin/bash
# Author Munis Isazade Django developer
VERSION="0.1"
ERROR_STATUS=0
CONF_ROOT=/root/django_deployment_tool
POSTGRESQL_USER=postgres
POSTGRESQL_CLUSTER_VERSION="$(sudo pg_lsclusters | egrep -o '[0-9]{1,}\.[0-9]{1,}' | (read a; echo $a;))" # $(pg_config --version | egrep -o '[0-9]{1,}\.[0-9]{1,}')
POSTGRESQL_UPGRADE_TO=9.5



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
    . $CONF_ROOT/config.txt
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
    echo -e "Installing python2 pip and depencies ..."
    apt-get -y update
    apt-get -y install python-pip python-dev libpq-dev postgresql postgresql-contrib nginx
    apt-get -y update
    echo -e "Installing python3 pip and depencies ..."
    apt-get -y install python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx
    apt-get -y install python3-venv
    echo -e "Installing Pillow for $(uname -a)"
    apt-get -y install libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk
    apt-get -y install libtiff4-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.5-dev tk8.5-dev python-tk
    echo -e "Creating new User for $(uname -a)"
    echo "APP_SERVER=$(curl -4 https://icanhazip.com/)" >> "$CONF_ROOT/config.txt"
    echo -e "Please write New Linux User name and password"
    read -p "Please enter your linux username: " APP_USER
    while true ; do
    if [ $APP_USER ]; then
        break
    fi
    read -p "Please enter your linux username: " APP_USER
    done
    echo "APP_USER=$APP_USER" >> "$CONF_ROOT/config.txt"
    echo -e "Please enter your linux user password: "
    echo -n "Password :"
    read -s APP_USER_PASSWORD
    while true ; do
    if [ $APP_USER_PASSWORD ]; then
        break
    fi
    echo -n "Password :"
    read -s APP_USER_PASSWORD
    done
    echo "APP_USER_PASSWORD=$APP_USER_PASSWORD" >> "$CONF_ROOT/config.txt"

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
    . $CONF_ROOT/config.txt
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
    . $CONF_ROOT/config.txt
    echo -e "Please Write your projects detailed...."
    apt-get -y update
    echo -e "Please write your git repository url here"
    read -p "Git Repo : " GIT_REPO_URL
    while true ; do
    if [ $GIT_REPO_URL ]; then
        break
    fi
    read -p "Please enter Repo Url : " GIT_REPO_URL
    done
    echo "GIT_REPO_URL=$GIT_REPO_URL" >> "$CONF_ROOT/config.txt"
    GIT_ROOT=$(echo $GIT_REPO_URL | cut -d'.' -f 2 | cut -d'/' -f 3)
    echo "GIT_ROOT=$GIT_ROOT" >> "$CONF_ROOT/config.txt"
    if [[ $GIT_REPO_URL == *git@github* ]]; then
      echo -e "Using the SSH protocol, you can connect and authenticate to remote servers and services. With SSH keys, you can connect to GitHub without supplying your username or password at each visit."
      echo -e "Generating a new SSH key and adding it to the ssh-agent"
      ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
      cp -r $CONF_ROOT/commands/gcat /bin/
      chmod +x /bin/gcat
      echo -e "Plase write this ssh-keygen register your Github or Bitbucket account "
      gcat ~/.ssh/id_rsa.pub
      read -p "If you did please confirm to continued(yes/no)?" confirm
      while true ; do
          if [ "$confirm"==yes ]; then
            break
          fi
          echo -e "Ssh key is bellow:"
          gcat ~/.ssh/id_rsa.pub
          read -p "Please confirm to continued(yes/no)?" confirm
      done
    fi

    echo -e "Please Last time write to project name (Django base app name) :"
    read -p "Project name : " APP_NAME
    while true ; do
    if [ $APP_NAME ]; then
        break
    fi
    read -p "Project name : " APP_NAME
    done
    echo "APP_NAME=$APP_NAME" >> "$CONF_ROOT/config.txt"
    echo -e "Make commands executable"
    cp -r  $CONF_ROOT/config.txt /var/local/
    chown -R $APP_USER:$APP_USER /var/local/config.txt
    chmod -R 777 /var/local/config.txt
    cp -r  $CONF_ROOT/commands /var/local/
    chown -R $APP_USER:$APP_USER /var/local/commands
    chown -R $APP_USER:$APP_USER /var/local/commands/*
    chmod -R 777 /var/local/commands/*
    cp -r  $CONF_ROOT/tlp /var/local/
    chown -R $APP_USER:$APP_USER /var/local/tlp
    chown -R $APP_USER:$APP_USER /var/local/tlp/*
    chmod -R 777 /var/local/tlp/*
    echo -e "Base command sed "
    sed -i -e 's|#{APP_USER_LINUX}|'$APP_USER'|g' $CONF_ROOT/commands/base
    cp -r  $CONF_ROOT/commands/base /bin/
    chmod +x /bin/base
    base
}

function configuration_server() {
    . $CONF_ROOT/config.txt
    echo -e "Configuration Nginx credentials.."
    sed -i -e 's|#{APP_SERVER}|'$APP_SERVER'|g' -e 's|#{APP_ROOT_DIRECTORY}|'$APP_ROOT_DIRECTORY'|g' -e 's|#{APP_NAME}|'$APP_NAME'|g' $CONF_ROOT/tlp/default
    echo -e "Create nginx default server.."
    cp -r tlp/default /etc/nginx/sites-available/default
    echo -e "Gunicorn file created.."
    sed -i -e 's|#{APP_USER}|'$APP_USER'|g' -e 's|#{APP_ROOT_DIRECTORY}|'$APP_ROOT_DIRECTORY'|g' -e 's|#{APP_NAME}|'$APP_NAME'|g' $CONF_ROOT/tlp/gunicorn.service
    cp -r tlp/gunicorn.service /etc/systemd/system/
    echo -e "Everything works cool :)"
}


function create_database {
    # Database creation
    . $CONF_ROOT/config.txt
    read -p "Postgres Database name : " APP_DB_NAME
    while true ; do
    if [ $APP_DB_NAME ]; then
        break
    fi
    read -p "Please enter Postgres Database name : " APP_DB_NAME
    done
    echo "APP_DB_NAME=$APP_DB_NAME" >> "$CONF_ROOT/config.txt"
    read -p "Postgres Database password : " APP_DB_PASSWORD
    while true ; do
    if [ $APP_DB_PASSWORD ]; then
        break
    fi
    read -p "Please enter Postgres Database password : " APP_DB_PASSWORD
    done
    echo "APP_DB_PASSWORD=$APP_DB_PASSWORD" >> "$CONF_ROOT/config.txt"
    echo "----- PostgreSQL v$POSTGRESQL_CLUSTER_VERSION: Creating database and user..."
sudo su - ${POSTGRESQL_USER} << EOF
# -------[script begins]-------
# psql --help
psql -c "
CREATE USER $APP_USER WITH PASSWORD '$APP_DB_PASSWORD';
"
createdb --owner $APP_DB_USER $APP_DB_NAME
# -------[script ends]-------
EOF
}

function delete_database {
	# Delete database
	. $CONF_ROOT/config.txt
    clear
    echo "************************************************************************"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! DANGER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "************************************************************************"
    echo ""
    read -p "Are you sure you want flush entirely DATABASE? (y/n): " confirm_delete
    if [ "$confirm_delete" == y ] ; then
        echo "----- PostgreSQL v$POSTGRESQL_CLUSTER_VERSION: Delete DB and user"

        # restart cluster
        sudo pg_ctlcluster ${POSTGRESQL_CLUSTER_VERSION} main restart --force
        # sudo /etc/init.d/postgresql restart

        # delete user
sudo su - ${POSTGRESQL_USER} << EOF
# -------[script begins]-------
dropdb ${APP_DB_NAME}
psql -c "DROP USER ${APP_USER};"
# -------[script ends]-------
EOF
    fi
}

function upgrade_cluster {
    . $CONF_ROOT/config.txt
    # Upgrade PostgreSQL 9.3 to 9.5 on Ubuntu 14.04 and Ubuntu 16.04
    # ref: https://medium.com/@tk512/upgrading-postgresql-from-9-3-to-9-4-on-ubuntu-14-04-lts-2b4ddcd26535#.4i136rihe
    if [ "$POSTGRESQL_CLUSTER_VERSION" != "$POSTGRESQL_UPGRADE_TO" ]; then
        echo "----- PostgreSQL v$POSTGRESQL_CLUSTER_VERSION: Dump"
        # http://www.postgresql.org/docs/9.4/static/backup-dump.html

        sudo su - ${POSTGRESQL_USER} << EOF
# -------[script begins]-------
psql -U ${POSTGRESQL_USER} -l
mkdir -p ./backups
pg_dumpall > ./backups/old_.db
# -------[script ends]-------
EOF

        echo "----- PostgreSQL: stop the current database..."
        sudo /etc/init.d/postgresql stop

        echo "----- PostgreSQL: Create a new list..."
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

        echo "----- PostgreSQL: download $POSTGRESQL_UPGRADE_TO"
        sudo apt-get update
        sudo apt-get install -y postgresql-${POSTGRESQL_UPGRADE_TO}

        sudo pg_lsclusters

        sudo pg_dropcluster --stop ${POSTGRESQL_UPGRADE_TO} main
        sudo /etc/init.d/postgresql start

        echo "----- PostgreSQL: Upgrade to $POSTGRESQL_UPGRADE_TO"
        sudo pg_upgradecluster ${POSTGRESQL_CLUSTER_VERSION} main
        sudo pg_dropcluster ${POSTGRESQL_CLUSTER_VERSION} main
        sudo pg_lsclusters
    else
        echo -e "\n ==> Cluster up to date! \n"
    fi
}

# ------------------------
# Dump the DB that given in config file to the passed destination
function restore_from_source {
    # -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    # *  Restoring Django database
    # - http://stackoverflow.com/a/2732521/968751
    #
    #   1) Include project variables
    #   2) Drop existing database if you want overwrite
    #   3) Drop the User, database associated with
    #   4) Create User
    #   5) Create Database but don't `migrate` yet
    #   6) Restore the database from dump file
    #   7) Create proper rules for the restored tables
    #
    # -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    # 1) . /vagrant/vagrant_setup/config.txt
    # 2) dropdb $APP_DB_NAME
    # 3) psql -c " DROP USER $APP_DB_USER;"
    # 4) psql -c " CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASSWORD'; "
    # 5) createdb --owner $APP_DB_USER $APP_DB_NAME
    # 6) psql $APP_DB_NAME -f ./backups/dump_24aug.sql
    # 7) for tbl in `psql -qAt -c "select tablename from pg_tables where schemaname = 'public';" $APP_DB_NAME` ; do  psql -c "alter table \"$tbl\" owner to $APP_DB_USER" $APP_DB_NAME ; done
    #    for tbl in `psql -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = 'public';" $APP_DB_NAME` ; do  psql -c "alter table \"$tbl\" owner to $APP_DB_USER" $APP_DB_NAME ; done
    #    for tbl in `psql -qAt -c "select table_name from information_schema.views where table_schema = 'public';" $APP_DB_NAME` ; do  psql -c "alter table \"$tbl\" owner to $APP_DB_USER" $APP_DB_NAME ; done
    # -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    # pg_restore -U $APP_DB_USER -d $APP_DB_NAME -1 <filename>
    # -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    . $CONF_ROOT/config.txt
    local SRC=$(normalize_path "$1")
    local FILENAME="${SRC##*/}"

    if [ ! -f ${SRC} ]; then
        echo -e "\n==> File not found: '$SRC'\n"
        exit 1
    fi

    echo "----- PostgreSQL v$POSTGRESQL_CLUSTER_VERSION: Importing DB from file '$SRC'"
    cp --no-preserve=mode,ownership ${SRC} /tmp/
    sudo su - ${POSTGRESQL_USER} << EOF
# -------[script begins]-------
pg_restore -U ${POSTGRESQL_USER} -d ${APP_DB_NAME} -1 /tmp/${FILENAME}
# -------[script ends]-------
EOF
    sudo rm -rf /tmp/${FILENAME}
}

# ------------------------
# Dump the DB that given in config file to the passed destination
function dump_to_destination {
    # Dump DB to given destination
    . $CONF_ROOT/config.txt
    local DST=$(normalize_path "$1")
    local BACKUP_DATE=$(date '+%d-%b-%Y')

    echo "----- PostgreSQL v$POSTGRESQL_CLUSTER_VERSION: Exporting DB to '$DST'"
    sudo su - ${POSTGRESQL_USER} << EOF
# -------[script begins]-------
mkdir -p ./backups
pg_dump -E UTF-8 -Fc ${APP_DB_NAME} > ./backups/${APP_DB_NAME}\_${BACKUP_DATE}.sql
\cp -i ./backups/${APP_DB_NAME}\_${BACKUP_DATE}.sql /tmp
# -------[script ends]-------
EOF
    cp --no-preserve=mode,ownership /tmp/${APP_DB_NAME}\_${BACKUP_DATE}.sql ${DST}
    sudo rm /tmp/${APP_DB_NAME}\_${BACKUP_DATE}.sql
}




function done_script() {
    . $CONF_ROOT/config.txt
    echo "Everything is OK :)"
    echo "---"
    echo "---"
    echo "Deployment ready! Now log into linux user, intialize the virtual environment, \
    start the server and you'll be able to see the django-app!"
    echo "---"
    echo "---"
    sudo su - $APP_USER

}

function normalize_path
{
    #The printf is necessary to correctly decode unicode sequences
    path=$($PRINTF "${1//\/\///}")
    if [[ $HAVE_READLINK == 1 ]]; then
        new_path=$(readlink -m "$path")

        #Adding back the final slash, if present in the source
        if [[ ${path: -1} == "/" && ${#path} > 1 ]]; then
            new_path="$new_path/"
        fi

        echo "$new_path"
    else
        echo "$path"
    fi
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
        done_script
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
    *)

        if [[ $COMMAND != "" ]]; then
            echo "Error: Unknown command: $COMMAND"
            ERROR_STATUS=1
        fi
        usage

    ;;
esac

exit $ERROR_STATUS