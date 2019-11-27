#!/bin/bash
#Only on ubuntu 18.04
sudo apt-get update
sudo apt install python3
apt install python3-pip
python3 -m pip install pip --upgrade
pip3 install virtualenv
sudo apt-get install libsnappy-dev
virtualenv algo
source algo/bin/activate
pip install pystore
pip install 'fsspec>=0.3.3'
pip install dask[dataframe] --upgrade
