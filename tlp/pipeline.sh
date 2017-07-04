#!/usr/bin/env bash

echo -e "Connect To Server user #{APP_USER}"
sudo su - #{APP_USER} << EOF
    cd #{APP_ROOT_DIRECTOR}
    echo -e "Activate virtualenviroment"
    source .venv/bin/activate
    echo -e "Check system issues"
    python manage.py check
    echo -e "Stage deploy to Server"
    restart
    echo -e "Installing some packages .."
    pip install -r requirements.txt
    echo -e "Makemigrations "
    makemigrations
    echo -e "Check error issues"
    check
    echo -e "Everything works fine :)"
EOF

systemctl restart nginx
echo "Restarting nginx:                                                    [OK]"
systemctl restart gunicorn
echo "Restarting Gunicorn:                                                 [OK]"
echo "Everything is OK :)"

