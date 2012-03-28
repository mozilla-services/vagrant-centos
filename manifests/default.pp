Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin/' }

# Mozilla packages to install
$moz_packages = ['nginx', 'gunicorn', 'logstash', 'python26', 'python26-setuptools', 'rubygem-petef-statsd', 'zeromq']

yumrepo { 'mozilla-services':
    baseurl => "http://mrepo.mozilla.org/mrepo/$releasever-$basearch/RPMS.mozilla-services",
    enabled => 1,
    gpgcheck    => 0,
}

yumrepo { 'packages-mozilla':
    baseurl => "http://mrepo.mozilla.org/mrepo/$releasever-$basearch/RPMS.mozilla",
    enabled => 1,
    gpgcheck    => 0,
}

package { $moz_packages:
    ensure  => present,
    require => [Yumrepo['mozilla-services'], Yumrepo['packages-mozilla']]
}

file { 'logstash.conf':
    ensure  => present,
    path    => "/etc/logstash.conf",
    source  => "/vagrant/files/logstash.conf",
}

file { 'logstash_plugins':
    ensure  => directory,
    path    => "/opt/logstash/plugins",
    source  => "/vagrant/files/plugins",
    recurse => true,
    force   => true,
}

file { 'logstash_init':
    ensure  => present,
    path    => "/etc/init/logstash.conf",
    source  => "/vagrant/files/logstash.init.conf",
    owner   => 'root',
    group   => 'root',
    mode    => 644,
}

exec { 'update_init':
    command => "/sbin/initctl reload-configuration",
    subscribe   => File["logstash_init"],
    require => File["logstash_plugins"],
}

exec { 'start_logstash':
    command => "/sbin/initctl restart logstash || /sbin/initctl start logstash",
    subscribe   => Exec["update_init"],
}


Package["logstash"] -> File["logstash.conf"] -> File["logstash_init"] -> File["logstash_plugins"]
