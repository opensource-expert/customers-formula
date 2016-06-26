# vim: set ft=jinja:
#
# DON'T EDIT THIS FILE: salt managed file
#
{# Will import on the pillar side a generated passwords database -#}
{{ '{%' }} import_yaml "{{ password_db }}" as pass with context {{ '%}' }}
mysql:
  # Managed mariaDB users for customers
  user:
{% set webserver = salt['pillar.get']('wsf:global:webserver', 'localhost') -%}
{%- for name, client in salt['pillar.get']('wsf:customers', {}).items() %}
{%-   if 'db' in client['services'] %}
{#-     # delete or deleted key, disabled (enabled == False) will be removed by mysql-formula #}
        {%- set customer_deleted =  client.get('deleted') or client.get('delete') %}
{%-     if not customer_deleted and client['enabled'] %}
    {{ name }}:
      password: {{ '"{{' }} pass['{{ name }}']['mysql'] {{ '}}"' }}
      hosts:
        - {{ webserver }}
      databases:
        - database: {{ name }}
          grants: ['all privileges']
{%-     elif customer_deleted or not client['enabled'] %}
    {#- It wont add any database user if customer.absent: True #}
    # customer {{ name }} is disabled{{ ' (deleted)' if customer_deleted else '' }}, will be deleted if it was present
    {{ name }}:
      absent: True
{%-     endif %}
{%    endif -%}
{% endfor -%}
