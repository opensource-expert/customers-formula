{# vim: set ft=jinja: -#}
# v{{ 'im' }}: set ft=yaml:
#
# DON'T EDIT THIS FILE: salt managed file
#
{# will import on the pillar side a generated passwords database -#}
{{ '{%' }} import_yaml "{{ password_db }}" as pass with context {{ '%}' }}
# Managed shell users for customers
users:
{%- for name, client in salt['pillar.get']('%s:customers'|format(customers_top), {}).items() %}
{%-   if 'webhost' in client['services'] %}
        {%- set customer_deleted = client.get('deleted') or client.get('delete') %}
        {%- set customer_was_present = salt['pillar.get']('users:%s'|format(name)) %}
{%-     if not customer_deleted %}
{%-       if client['enabled'] or customer_was_present %}
  {{ name }}:
{%-         if not client['enabled'] %}
    # user {{ name }} is disabled
    {#- password: must use hashed password #}
    password: '*'
{%-         else %}
    password: {{ '"{{' }} pass['{{ name }}']['hash'] {{ '}}"' }}
{%-         endif %}
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
      {%-   if 'sftp' in client['services'] %}
      - sftponly
      {%-   endif -%}
{#      END IF enabled  -#}
{%        endif -%}
{%      else %}
  ## Absent user
  {{ name }}:
    absent: True
    purge: True
    force: True
{#   END IF deleted  -#}
{%      endif -%}
{# END IF webhost  -#}
{%    endif -%}
{%  endfor -%}
