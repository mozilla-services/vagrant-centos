Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin/' }

# Mozilla packages to install
$moz_packages = ['createrepo','nginx','gunicorn','logstash','python26','python26-setuptools','python-devel','rubygem-petef-statsd','rpm-devel','rpm-python','rpmdevtools','zeromq',]

yumrepo {
    'mozilla-services':
        descr       => "Mozilla Services Repo",
        baseurl     => 'http://mrepo.mozilla.org/mrepo/$releasever-$basearch/RPMS.mozilla-services',
        enabled     => 1,
        gpgcheck    => 0;
    'packages-mozilla':
        descr       => "Mozilla Packages Repo",
        baseurl     => 'http://mrepo.mozilla.org/mrepo/$releasever-$basearch/RPMS.mozilla',
        enabled     => 1,
        gpgcheck    => 0;
}

package { $moz_packages:
    ensure  => present,
    require => [Host["mrepo"], Yumrepo['mozilla-services'], Yumrepo['packages-mozilla']]
}

# From remote, one of the mrepo's doesn't work, so we hardcode in the one that
# does work reliably over the VPN
host { 'mrepo':
    ensure  => present,
    name    => "mrepo.mozilla.org",
    ip      => "63.245.209.182",
}

## Local RPM Repo

yumrepo {
    'local-rpms':
        descr       => "Local RPMs",
        baseurl     => 'file:///local_repo/',
        enabled     => 1,
        gpgcheck    => 0,
}

file {
    'local_repo':
        ensure  => directory,
        recurse => true,
        path    => "/local_repo",
        source  => "/vagrant/local_repo",
}

exec {
    'update_repo':
        command     => "createrepo /local_repo",
        subscribe   =>  File["local_repo"];
    'clear_metadata':
        command     => "yum clean metadata",
        subscribe   => File["local_repo"];
}


# Make sure not to install the yum repo until its completely ready
Package["createrepo"] -> File["local_repo"] -> Exec["update_repo"] -> Yumrepo['local-rpms']

## Nginx Setup

file {
    'nginx.conf':
        ensure  => present,
        path    => "/etc/nginx/nginx.conf",
        source  => "/vagrant/files/nginx.conf",
        require => Package["nginx"];
    'default.conf':
        ensure  => absent,
        path    => "/etc/nginx/conf.d/default.conf",
        require => Package["nginx"];
}

service {'nginx':
    ensure      => running,
    enable     => true,
    subscribe   => File["nginx.conf"],
}

## Logstash Setup

file {
    'logstash.conf':
        ensure  => present,
        path    => "/etc/logstash.conf",
        source  => "/vagrant/files/logstash.conf";
    'logstash_plugins':
        ensure  => directory,
        path    => "/opt/logstash/plugins",
        source  => "/vagrant/files/plugins",
        recurse => true,
        force   => true;
    'logstash_init':
        ensure  => present,
        path    => "/etc/init/logstash.conf",
        source  => "/vagrant/files/logstash.init.conf",
        owner   => 'root',
        group   => 'root',
        mode    => 644;
    "/usr/lib64/libzmq.so":
        ensure  => link,
        target  => "/usr/lib64/libzmq.so.1",
        require => Package["zeromq"];
}

exec {
    'update_init':
        command => "/sbin/initctl reload-configuration",
        subscribe   => File["logstash_init"],
        require => File["logstash_plugins"];
    'start_logstash':
        command => "/sbin/initctl start logstash",
        unless  => "/sbin/initctl status logstash | grep -w running";
    'reload_logstash':
        command     => "/sbin/initctl restart logstash",
        subscribe   => File["logstash.conf"],
        refreshonly => true;
}

Host["mrepo"] -> Package["zeromq"] -> Package["logstash"] -> File["logstash.conf"] -> File["logstash_init"] -> File["logstash_plugins"] -> Exec["start_logstash"]
