{# vim: set ft=jinja: -#}
#
# DON'T EDIT THIS FILE: salt managed file
#
#
# pillar for apache formula for "sites:"
apache:
  sites:
{%- for user, client in salt['pillar.get']('wsf:customers', {}).items() %}
{%-   if 'webhost' in client['services'] %}
        {%- set customer_deleted = client.get('deleted') or client.get('delete') %}
        {%- set customer_was_present = salt['pillar.get']('apache:sites:%s'|format(client.domain_name)) %}
{%-     if not customer_deleted %}
{#-     webmaster is computed globally but can be set by customer also #}
{%-     set webmaster         = salt['pillar.get']('wsf:global:webmaster', 'nowebmaster@localhost') %}
{%-     set webmaster         = client.get('webmaster', webmaster) %}
{%-     set userHome_dir      = '/home/' ~ user %}
{%-     set ApacheHome_dir    = '/home/' ~ user ~ '/vhost' %}
{%-     set DocumentRoot_dir  = '/home/' ~ user ~ '/vhost/www' %}
{%-     set Log_dir           = '/home/' ~ user ~ '/logs' %}
{%-     set Cron_dir          = '/home/' ~ user ~ '/cron' %}
{%-     set Bin_dir           = '/home/' ~ user ~ '/bin' %}
{%-       if client['enabled'] or customer_was_present %}
    {{ client.domain_name }}:
{%-        if not client['enabled'] %}
      enabled: False
{%         endif %}
      CustomerName: {{ user }}

      #template_file: salt://webserver/config/vhost.conf
      ServerName: {{ client.domain_name }}
      ServerAlias: www.{{ client.domain_name }}
      ServerAdmin: {{ webmaster }}

      LogLevel: warn
      {#- LogDir is a shorcut for webserver/create_dir.sls #}
      LogDir: {{ Log_dir }}
      ErrorLog: {{ Log_dir }}/error.log
      CustomLog: {{ Log_dir }}/access.log

      DocumentRoot: {{ DocumentRoot_dir }}

      Directory:
        {{ DocumentRoot_dir }}:
          Options: -Indexes +FollowSymLinks
          Order: allow,deny
          Allow: from all
          Require: all granted
          AllowOverride: None

      Formula_Append: |
        <IfModule mod_fastcgi.c>
            AddType application/x-httpd-fastphp .php
            Action application/x-httpd-fastphp /php-{{ user }}-fcgi
            Alias /php-{{ user }}-fcgi /usr/lib/cgi-bin/php-{{ user }}-fcgi
            FastCgiExternalServer /usr/lib/cgi-bin/php-{{ user }}-fcgi -appConnTimeout 10 -idle-timeout 250 -socket /var/run/php-fpm/fpm-{{ user }}.sock -pass-header Authorization
            ### Apache 2.4+ ###
            <Directory /usr/lib/cgi-bin>
                Require all granted
            </Directory>
            ###
        </IfModule>

{%        endif -%}
{%      endif -%}
{%    endif -%}
{% endfor -%}
