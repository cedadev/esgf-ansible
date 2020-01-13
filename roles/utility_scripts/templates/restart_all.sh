#!/bin/bash

# Restart ESGF services on this node
nohup {{ tomcat_ctrl }} start

# Restart COG
supervisorctl restart cog:

# Restart SLCS
supervisorctl restart slcs:

# Restart HTTPD
service httpd restart
