class subversion (
        $svn_dir = '/opt/subversion'
  ){
  package { 'subversion':
    ensure  => present,
  }
  package { 'libapache2-svn':
    ensure  => present,
  }
  package { 'libapache2-mod-svn':
    ensure  => present,
  }
  package { 'libsvn-dev':
    ensure  => present,
  }
  file {"$svn_dir":
    ensure => 'directory',
    recurse => true,
    require => [Package["subversion"],Package["libapache2-svn"],Package["libapache2-mod-svn"],Package["libsvn-dev"]],
  }
  file {"$svn_dir/conf/svnserve.conf":
          ensure  => present,
          replate => true,
          source  => 'puppet:///modules/subversion/svnserve.conf',
          require => Exec["$svn_dir"],
  }
  exec { "Create Repository":
          command => "/usr/bin/svnadmin create $svn_dir",
          cwd     => "/tmp",
          require => File["$svn_dir"],
  }
  exec { "Subversion as daemon":
          command => "/usr/bin/svnserve -d",
          require => [File["$svn_dir/conf/svnserve.conf"], Exec["Create Repository"]],
  }
  exec { "Enable a2enmod":
          command => "/usr/bin/a2enmod dav_svn",
          cwd     => "/tmp",
          require => Exec["Subversion as daemon"],
  }
  file {"/etc/apache2/mods-available/dav_svn.conf":
          ensure  => present,
          replate => true,
          content => template("subversion/dav_svn.conf.erb"),
          require => Exec["Enable a2enmod"],
  }
  exec { "Restart Apache":
          command => "/bin/systemctl restart apache2",
          require => File["/etc/apache2/mods-available/dav_svn.conf"],
  }
}
