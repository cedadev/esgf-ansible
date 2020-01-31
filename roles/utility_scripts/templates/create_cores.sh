#!/bin/bash

{% for core in ['datasets', 'files', 'aggregations'] %}
# Create {{ core }} core
{{ solr.path }}/bin/solr create_core -c {{ core }} -d /tmp/solr-home/mycore -p 8985
{% endfor %}
