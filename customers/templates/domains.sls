{# vim: set ft=jinja: -#}
#
# DON'T EDIT THIS FILE: salt managed file
#
customers:
  # Managed domains for customers
  domains:
{#- produce managed domains, if customer is enabled, and has DNS the service #}
{%- for name, client in salt['pillar.get']('wsf:customers', {}).items() -%}
{%-   if not client.get('deleted') and client['enabled'] and 'dns' in client['services'] %}
    - {{ client.domain_name -}}
{%    endif -%}
{% endfor %}
