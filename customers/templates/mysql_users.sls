# vim: set ft=jinja:
#
# DON'T EDIT THIS FILE: salt managed file
#
{# Will import on the pillar side a generated passwords database -#}
{{ '{%' }} import_yaml "{{ password_db }}" as pass with context {{ '%}' }}
mysql:
  # Managed mariaDB users for customers
  user:
{% set webserver = salt['pillar.get']('%s:global:webserver'|format(customers_top), 'localhost') -%}
{%- for name, client in salt['pillar.get']('%s:customers'|format(customers_top), {}).items() %}
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
      # ==========================
      # customer formula Extension
      # ==========================
      db_server: {{ salt['pillar.get']('%s:global:dbserver'|format(customers_top), 'localhost') }}
{%-     elif customer_deleted or not client['enabled'] %}
    {#- It wont add any database user if customer.absent: True #}
    # customer {{ name }} is disabled{{ ' (deleted)' if customer_deleted else '' }}, will be deleted if it was present
    {{ name }}:
      absent: True
{%-     endif %}
{%    endif -%}
{% endfor -%}
