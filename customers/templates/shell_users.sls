# vim: set ft=jinja:
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
    password: {{ '"{{' }} pass['{{ name }}']['shell'] {{ '}}"' }}
    fullname: web user {{ name }}
    enforce_password: True
    empty_password: False
    home: /home/{{ name }}
    createhome: False
    sudouser: False
    shell: /bin/bash
    prime_group:
      name: {{ name }}
    groups:
      - www-data
{%    endif -%}
{% endfor -%}
