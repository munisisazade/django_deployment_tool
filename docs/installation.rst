Installation
============

Getting the code
----------------

The recommended way to install the Python 3 is via Ubuntu 16.04 apt package
If you are using Python 2, type::

    $ apt apt-get update
    $ apt-get install python-pip python-dev git

If you are using Django with Python 3, type::

    $ apt-get update
    $ apt-get install python3-pip python3-dev git

If you want to use this Tools plase make sure u have root user
check u are a root user bellow command::

    $ whoami

if not try this::

    $ sudo su - root

You can install this tool via git command::

    $ git clone https://github.com/munisisazade/django_deployment_tool.git

Make Command Executable
-----------------------
After installation you can executable command using ``chmod`` bash command::

    $ cd django_deployment_tool/
    $ chmod +x deploy.sh

Already ready use this tool just typing::

    $ ./deploy.sh usage