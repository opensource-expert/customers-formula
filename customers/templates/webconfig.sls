{# vim: set ft=jinja: -#}
#
# DON'T EDIT THIS FILE: salt managed file
#
#
{# will import on the pillar side a generated passwords database -#}
{{ '{%' }} import_yaml "{{ password_db }}" as pass with context {{ '%}' }}

# pillar for apache formula for "sites:"
apache:
  sites:
{%- for user, client in salt['pillar.get']('%s:customers'|format(customers_top), {}).items() %}
{%-   if 'webhost' in client['services'] %}
        {%- set customer_deleted = client.get('deleted') or client.get('delete') %}
        {%- set customer_was_present = salt['pillar.get']('apache:sites:%s'|format(client.domain_name)) %}
{%-     if not customer_deleted %}
{#-     webmaster is computed globally but can be set by customer also #}
{%-     set webmaster         = salt['pillar.get']('%s:global:webmaster'|format(customers_top), 'no@webmaster') %}
{%-     set webmaster         = client.get('webmaster', webmaster) %}
        {#- userHome_dir is the same a ApacheHome_dir See template/shell_users.sls  #}
{%-     set userHome_dir      = '/home/' ~ user ~ '/vhost' %}
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
      {#- extra pillar value for other rules #}
      CustomerName: {{ user }}
      HomeDir: {{ userHome_dir }}
      MailPassword: {{ '"{{' }} pass['{{ user }}']['websmtp'] {{ '}}"' }}

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
