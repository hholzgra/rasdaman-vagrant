rasdaman-vagrant
================

vagrant/puppet setup for compiling rasdaman from scratch

Requirements
------------

* git for checkout
* vagrant for starting up the build VM
* virtualbox as vagrant depends on it
* puppet as some puppet modules need to be installed "from the outside"
* some patience while the setup initializes itself

Startup
-------

* after first checkout run ./puppet-modules.sh
* change git settings at the top of ./puppet/manifests/base.pp
** git_username
** git_email
** git_repo URL
* "vagrant up" will initialize the VM, check out code, and compile
* use "vagrant ssh" to log into the machine once it's up
* code is in the vagrant users homedir in ./rasdaman



