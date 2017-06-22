Commands
========

The Django Deployment Tools avilable Command Here.

``usage``
---------

This command help to user find how to use it tools

Here's an example::

    $ ./deploy.sh usage
    $ -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    $
    $       Django Deployment Tool v0.1
    $       Munis Isazade - munisisazade@gmail.com
    $ -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    $
    $ Usage: bash ./deploy.sh <COMMAND>
    $
    $ Commands:
    $       usage                   - For helping available commands to use
    $

``deploy``
----------

This is the base Command of Deployment tools. Firstly on Ubuntu 16.04 installed required this packages:
python-pip python-dev libpq-dev python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx python3-venv
For Pillow required packages : libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk
All installation takes time about 2-3 minutes. After this installation Tool ask Linux new user name
and password

Here's an example

``status``
----------

This command check deployment Status

