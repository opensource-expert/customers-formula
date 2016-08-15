{# vim: set ft=jinja: -#}
#
# DON'T EDIT THIS FILE: salt managed file
#
mysql:
  # Managed databases for customers
  database:
{%- for name, client in salt['pillar.get']('%s:customers'|format(customers_top), {}).items() %}
{%-   if not client.get('deleted') and client['enabled'] and 'db' in client['services'] %}
      {%- set db_name = client.get('override', {}).get('database', name) %}
    - {{ db_name -}}
{%    endif -%}
{% endfor %}
