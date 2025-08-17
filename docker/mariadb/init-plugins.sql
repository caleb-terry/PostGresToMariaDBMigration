-- Load plugins after MariaDB initialization
-- This script will be executed after the database is initialized

-- Install CONNECT storage engine
INSTALL SONAME 'ha_connect';

-- Install SPIDER storage engine
INSTALL SONAME 'ha_spider';

-- Create required Spider tables
CREATE TABLE IF NOT EXISTS mysql.spider_xa(
  format_id int not null default 0,
  gtrid_length int not null default 0,
  bqual_length int not null default 0,
  data char(128) charset binary not null default '',
  status char(8) not null default '',
  primary key (data, format_id, gtrid_length),
  key idx1 (status)
) engine=MyISAM default charset=utf8 collate=utf8_bin;

CREATE TABLE IF NOT EXISTS mysql.spider_xa_member(
  format_id int not null default 0,
  gtrid_length int not null default 0,
  bqual_length int not null default 0,
  data char(128) charset binary not null default '',
  scheme char(64) not null default '',
  host char(64) not null default '',
  port char(5) not null default '',
  socket text not null,
  username char(64) not null default '',
  password char(64) not null default '',
  ssl_ca text,
  ssl_capath text,
  ssl_cert text,
  ssl_cipher char(64) default null,
  ssl_key text,
  ssl_verify_server_cert tinyint not null default 0,
  default_file text,
  default_group char(64) not null default '',
  key idx1 (data, format_id, gtrid_length, host)
) engine=MyISAM default charset=utf8 collate=utf8_bin;

CREATE TABLE IF NOT EXISTS mysql.spider_xa_failed_log(
  format_id int not null default 0,
  gtrid_length int not null default 0,
  bqual_length int not null default 0,
  data char(128) charset binary not null default '',
  scheme char(64) not null default '',
  host char(64) not null default '',
  port char(5) not null default '',
  socket text not null,
  username char(64) not null default '',
  password char(64) not null default '',
  ssl_ca text,
  ssl_capath text,
  ssl_cert text,
  ssl_cipher char(64) default null,
  ssl_key text,
  ssl_verify_server_cert tinyint not null default 0,
  default_file text,
  default_group char(64) not null default '',
  thread_id int default null,
  status char(8) not null default '',
  failed_time timestamp not null default current_timestamp,
  key idx1 (data, format_id, gtrid_length, host)
) engine=MyISAM default charset=utf8 collate=utf8_bin;

-- Install Mroonga storage engine
INSTALL SONAME 'ha_mroonga';

-- Note: ColumnStore requires additional configuration and services
-- It cannot be simply loaded as a plugin