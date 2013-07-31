#
# setup variables
#

$sourcedir    = '/home/vagrant/rasdaman'

$git_username = 'Hartmut Holzgraefe'
$git_email    = 'harmtut@php.net'
#$git_repo     = 'git://kahlua.eecs.jacobs-university.de/rasdaman.git'
$git_repo     = 'https://github.com/hholzgra/rasdaman.git'

#
# defaults
#

Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
}

exec { 'apt-update':
    command => '/usr/bin/apt-get update'
}

Exec['apt-update'] -> Package <| |>

# group { 'puppet': ensure => 'present', }

# File { owner => 0, group => 0, mode => 0644 }


file { '/etc/motd':
    content => 'Welcome to your Rasdaman test instance.\nManaged by Vagrant and Puppet.\n'
}

#
# packages
#

# required to checkout source
package { ['git']: ensure => 'installed' }

# required to create 'configure'
package { ['autoconf']: ensure => 'installed' }
package { ['automake']: ensure => 'installed' }
package { ['libtool']: ensure => 'installed' }

# required build tools
package { ['build-essential']: ensure => 'installed' }
package { ['flex']: ensure => 'installed' }
package { ['bison']: ensure => 'installed' }

# required C libraries
package { ['libjpeg-dev']: ensure => 'installed' }
package { ['libncurses5-dev']: ensure => 'installed' }
package { ['libpng12-dev']: ensure => 'installed' }
package { ['libnetpbm10-dev']: ensure => 'installed' }
package { ['libtiff4-dev']: ensure => 'installed' }
package { ['libgdal1-dev']: ensure => 'installed' }
package { ['libecpg-dev']: ensure => 'installed' }
package { ['libhdf4-alt-dev']: ensure => 'installed' }
package { ['libnetcdf-dev']: ensure => 'installed' }

# required to build java
package { ['openjdk-6-jdk']: ensure => 'installed' }

# required to build documentation
package { ['doxygen']: ensure => 'installed' }

#
# source checkout and basic git config
#

vcsrepo { "rasdaman_git":
  ensure   => 'present',
  path     => "$srcdir",
  require  => [Package['git']],
  provider => 'git',
  source   => $git_repo,
  user     => 'vagrant',
  group    => 'users',
}

exec { "git config user.email '${git_email}'":
    user        => 'vagrant',
    cwd         => "$srcdir",
    environment => [ 'HOME=/home/vagrant' ],
    require     => Vcsrepo["rasdaman_git"],
}

exec { "git config user.name '${git_username}'":
    user        => 'vagrant',
    cwd         => "$srcdir",
    environment => [ 'HOME=/home/vagrant' ],
    require     => Vcsrepo["rasdaman_git"],
}

#
# create 'configure' 
#

exec { 'autoreconf':
    command => 'autoreconf -vfi',
    creates => "$srcdir/configure",
    user    => 'vagrant',
    cwd     => "$srcdir",
    require => [Vcsrepo["rasdaman_git"],Package['autoconf', 'automake', 'libtool']],
}

#
# run 'configure'
#

exec { 'configure':
    command => 'true ; ./configure --prefix=/usr/local/rasdaman --with-x --with-hdf4 --with-netcdf --with-wps --with-docs',
    creates => "$srcdir/Makefile",
    user    => 'vagrant',
    cwd     => "$srcdir",
    require => [Exec['autoreconf'],Package['build-essential', 'doxygen', 'flex', 'bison', 'openjdk-6-jdk', 'libjpeg-dev', 'libncurses5-dev', 'libpng12-dev', 'libnetpbm10-dev', 'libtiff4-dev', 'libgdal1-dev', 'libecpg-dev', 'libhdf4-alt-dev', 'libnetcdf-dev']],
}

#
# compile rasdaman
#

exec { 'make':
    command => 'make',
    creates => "$srcdir/rasmgr/rasmgr",
    user    => 'vagrant',
    cwd     => "$srcdir",
    require => Exec['configure'],
}

#
# install built rasdaman binaries and libs
#

exec { 'install':
    command => 'sudo make install',
    creates => '/usr/local/rasdaman/bin/rasmgr',
    user    => 'vagrant',
    cwd     => "$srcdir",
    require => Exec['make'],
}
    
#
# postgresql setup
#

class { 'postgresql::server':
  config_hash => {
    'ip_mask_deny_postgres_user' => '0.0.0.0/32',
    'ip_mask_allow_all_users'    => '0.0.0.0/0',
    'listen_addresses'           => '*',
    'postgres_password'          => 'secret',
  },
}

postgresql::role { 'petauser':
    superuser     => true,
    login         => true,
    createdb      => true,
    password_hash => postgresql_password('petauser','petapasswd'),    
    require       => Class['Postgresql::Server'],
}

postgresql::pg_hba_rule { 'petauser_hba':
  order       => '001',
  type        => 'local',
  database    => 'all',
  user        => 'petauser',
  auth_method => 'trust',
}

#
# initialise database
#

exec { 'dbinit':
    command     => '/usr/local/rasdaman/bin/update_petascopedb.sh',
    user        => 'vagrant',
    environment => 'RMANHOME=/usr/local/rasdaman', 
    require     => [Exec['install'],Postgresql::Role['petauser']],
}
