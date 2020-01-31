#!/bin/bash

# Restart ESGF services on this node
su tomcat -c '{{ tomcat_ctrl }} restart'

# Restart COG
supervisorctl restart cog:

# Restart SLCS
supervisorctl restart slcs:

# Restart HTTPD
service httpd restart

# Restart SOLR shards
/usr/local/solr/bin/solr restart -s /usr/local/solr-home/master-8984 -p 8984 -a -Denable.master=true -Ddisable.configEdit=true -Dsolr.disable.shardsWhitelist=true
/usr/local/solr/bin/solr restart -s /usr/local/solr-home/slave-8983 -p 8983 -a -Denable.slave=true -Ddisable.configEdit=true -Dsolr.disable.shardsWhitelist=true
