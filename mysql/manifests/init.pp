class mysql (
        $mysql_password = 'adminpass',
        $sonar_db_user  = 'sonardb',
        $sonar_db_pass  = 'sonarpass',
        $ospos_db_user  = 'osposuser',
        $ospos_db_pass  = 'ospospass',
        $ospos_db_name  = 'osposdb',
        ){
        package { 'mysql-server':
                ensure  => present,
        }
        package { 'mysql-common':
                ensure  => present,
        }
        package { 'python-mysqldb':
                ensure  => present,
        }
        service {'mysql':
                name =>'mysql',
                ensure => running,
                require => Package['mysql-server','mysql-common'],
        }
        exec { "Set mysql-password":
                unless => "mysqladmin -uroot -p$mysql_password status",
                path => ["/bin", "/usr/bin"],
                command => "mysqladmin -uroot password $mysql_password",
                require => Service["mysql"],
        }
        exec {"Create Sonar database":
                command => "/usr/bin/mysql -uroot -p$mysql_password -e \"create database $sonar_db_user;\"",
                require => [Service["mysql"],Exec['Set mysql-password']],
        }
        exec { "Create Sonar user for database":
                path => ["/bin", "/usr/bin"],
                command => "mysql -u root -p$mysql_password -e \"CREATE USER '$sonar_db_user'@'localhost' IDENTIFIED BY '$sonar_db_pass'; GRANT ALL PRIVILEGES ON * . * TO '$sonar_db_user'@'localhost'; FLUSH PRIVILEGES;\"",
                require => Exec["Create Sonar database"],
        }
        exec {"Create OSPOS database":
                command => "/usr/bin/mysql -uroot -p$mysql_password -e \"create database $ospos_db_name;\"",
                require => [Service["mysql"],Exec['Set mysql-password']],
        }
        exec { "Create OSPOS user for database":
                path => ["/bin", "/usr/bin"],
                command => "mysql -u root -p$mysql_password -e \"CREATE USER '$ospos_db_user'@'localhost' IDENTIFIED BY '$ospos_db_pass'; GRANT ALL PRIVILEGES ON * . * TO '$ospos_db_user'@'localhost'; FLUSH PRIVILEGES;\"",
                require => Exec["Create OSPOS database"],
        }
        file {"/tmp/database.sql":
                mode    => "0644",
                replace => "true",
                source  => 'puppet:///modules/mysql/database.sql',
        }
        exec { "Import OSPOS DB":
                path => ["/bin", "/usr/bin"],
                command => "mysql -u root -p$mysql_password $ospos_db_name < /tmp/database.sql",
                require => Exec["Create OSPOS user for database"],
        }

}