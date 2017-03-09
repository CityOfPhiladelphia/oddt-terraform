#!/bin/bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

apt-get update
apt-get -y upgrade
apt-get install -y python3 python3-pip git

pip3 install --upgrade pip3

pip3 install git+https://github.com/CityOfPhiladelphia/keytothecity.git

keytothecity sync airflow -c ${keytothecity_config}
keytothecity install_cron airflow -c ${keytothecity_config}
