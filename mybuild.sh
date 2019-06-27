#! /bin/bash

rm -f *.box
rm -rf packer_cache
rm -rf output-virtualbox-iso
packer build -force -only virtualbox-iso vbox-2016a.json
vagrant box add -f --name win-2016 windows2016min-virtualbox.box
