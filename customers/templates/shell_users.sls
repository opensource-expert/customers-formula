{# vim: set ft=jinja: -#}
# v{{ 'im' }}: set ft=yaml:
#
# DON'T EDIT THIS FILE: salt managed file
#
{# will import on the pillar side a generated passwords database -#}
{{ '{%' }} import_yaml "{{ password_db }}" as pass with context {{ '%}' }}
# Managed shell users for customers
users:
{%- for name, client in salt['pillar.get']('wsf:customers', {}).items() %}
{%-   if not client.get('deleted') and client['enabled'] and 'webhost' in client['services'] %}
  {{ name }}:
    {#-                   use hashed password #}
    password: {{ '"{{' }} pass['{{ name }}']['hash'] {{ '}}"' }}
    fullname: web user {{ name }}
    # enforce_password: True
    empty_password: False
    # chrooted: sftp goes to /home/{{ name }}/vhost web in www/
    home: /home/{{ name }}/vhost
    createhome: False
    sudouser: False
    shell: /bin/bash
    prime_group:
      name: {{ name }}
    groups:
      - www-data
      {%- if 'sftp' in client['services'] %}
      - sftponly
      {%- endif %}
{%    endif -%}
{% endfor -%}
