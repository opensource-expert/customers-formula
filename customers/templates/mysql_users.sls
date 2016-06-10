# vim: set ft=jinja:
#
# DON'T EDIT THIS FILE: salt managed file
#
{# will import on the pillar side a generated passwords database -#}
{{ '{%' }} import_yaml "{{ password_db }}" as pass with context {{ '%}' }}
mysql:
  # Managed mariaDB users for customers
  user:
{% set db_server = 'localhost' -%}
{%- for name, client in salt['pillar.get']('wsf:customers', {}).items() %}
{%-   if not client.get('deleted') and client['enabled'] and 'db' in client['services'] %}
    {{ name }}:
      password: {{ '"{{' }} pass['{{ name }}']['mysql'] {{ '}}"' }}
      hosts:
        - {{ db_server }}
      databases:
        - database: {{ name }}
          grants: ['all privileges']
{%    endif -%}
{% endfor -%}
