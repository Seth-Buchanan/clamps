#!/usr/bin/env bash
# Set-up script written by Seth Buchanan

if [ $(id -u) != 0 ]; then
    echo "This script must be ran as root"
    exit 1
fi

set -e 				# exit if any command fails

apt update

apt install -y python3-virtualenv python3-dev \
     python3-pip libfreetype6-dev libjpeg-dev build-essential i2c-tools \
     python3-smbus libatlas-base-dev libgstreamer1.0-0 \
     libqt5gui5 libhdf5-dev  libatlas-base-dev \
      libqt5test5 util-linux procps hostapd iproute2 iw \
     haveged dnsmasq 

sudo -u ${SUDO_USER} virtualenv ./server
source ./server/bin/activate
pip install -r requirements.txt

if ! test -d ./create_ap; then
    sudo -u ${SUDO_USER} git clone https://github.com/oblique/create_ap ./create_ap
fi

make install -C ./create_ap

raspi-config nonint do_i2c 0	# enable the i2c interface
sed -i "s/#dtparam=i2c_arm=on/dtparam=i2c_arm=on\nstart_x=1\n/" /boot/firmware/config.txt

cp clamps.service /etc/systemd/system/
sed -i "s:ExecStart=<PLACEHOLDER>:ExecStart=`pwd`/server/bin/python3 `pwd`/server/webServer.py:" /etc/systemd/system/clamps.service

systemctl daemon-reload
systemctl start clamps.service
systemctl enable clamps.service

cat <<EOF

Done!

The program has been installed to your Raspberry Pi. It can now
be restarted to enable the i2c drivers for connecting to the HAT.
When turning on again, the Rasberry Pi will set the connected
servos to the middle of their ranges of motion. After that, the
arm will be controlable via a webserver on port 5000 or the joystick
modules.
EOF

