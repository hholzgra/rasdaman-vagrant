#! /bin/sh
rm -rf `pwd`/puppet/modules
mkdir -p `pwd`/puppet/modules
puppet module install puppetlabs-vcsrepo    --modulepath=`pwd`/puppet/modules
puppet module install puppetlabs-postgresql --modulepath=`pwd`/puppet/modules

