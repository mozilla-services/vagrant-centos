Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin/' }

# Mozilla packages to install
$moz_packages = ['nginx', 'gunicorn', 'logstash', 'python26', 'python26-setuptools', 'rubygem-petef-statsd', 'zeromq']

# Add rpmforge
exec { 'install-rpmforge-gpg-key':
    command => 'rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt',
    unless  => 'rpm -q --quiet gpg-pubkey-6b8d79e6',
}

exec { 'install-rpmforge':
    command => 'rpm -i http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm',
    unless  => 'rpm -q rpmforge-release',
    require => Exec['install-rpmforge-gpg-key'],
}

define add_yum_repo {
    file { $name:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        path    => "/etc/yum.repos.d/${name}",
        source  => "/vagrant/files/${name}",
        purge   => true,
    }
}

add_yum_repo { 
    ['mozilla-services.repo', 'packages-mozilla.repo']: }

package { $moz_packages:
    ensure  => present,
    require => [File['mozilla-services.repo'], File['packages-mozilla.repo']]
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
    require => Package["logstash"],
}