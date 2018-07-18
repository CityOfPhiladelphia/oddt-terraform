#!/bin/bash
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config

sudo yum -y install python36 python36-virtualenv python36-pip git

sudo pip-3.6 install git+https://github.com/CityOfPhiladelphia/keytothecity.git

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

keytothecity sync ${keytothecity_config_name} -c ${keytothecity_config}
keytothecity install_cron ${keytothecity_config_name} -c ${keytothecity_config}
