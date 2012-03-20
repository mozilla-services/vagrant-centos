====================
Vagrant CentOS Setup
====================

This vagrant build is to create a CentOS VM that has the mozilla-services repo's enabled for
a build environment aiming to be quite similar to production Mozilla Service machines (though
not exactly as it doesn't use the same service-ops puppet scripts).

Installing
==========

**Note**: VirtualBox 4.1.x currently `seems to have a nasty kernel panic issue with Lion <https://www.virtualbox.org/ticket/9359>`_
, use the second link provided in 2.1 to install the previous version which is stable in OSX Lion.

1. Install Vagrant: http://downloads.vagrantup.com/tags/v1.0.1

2. Install Virtualbox (**do not install this in OSX Lion**): http://www.virtualbox.org/wiki/Downloads

2. Install Virtualbox (**use this in Lion**): https://www.virtualbox.org/wiki/Download_Old_Builds_4_0

3. Install the box VM used::

       $ vagrant box add centos-60-x86_64 http://dl.dropbox.com/u/1627760/centos-6.0-x86_64.box

4. Clone the repo, edit Vagrantfile as needed, and run!::

       $ mkdir myproj
       $ curl --silent https://nodeload.github.com/mozilla-services/vagrant-centos/tarball/master | tar zxv --directory=myproj --strip-components=1
       $ cd myproj
       $ vim myproj/manifests/default.pp  # Edit as needed
       $ vagrant up

