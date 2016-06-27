{# vim: set ft=jinja: -#}
#
# DON'T EDIT THIS FILE: salt managed file
#
customers:
  # Managed domains for customers
  domains:
{#- produce managed domains, if customer is enabled, and has DNS the service #}
{%- for name, client in salt['pillar.get']('wsf:customers', {}).items() -%}
{%-   if 'dns' in client['services'] %}
{%-     set customer_deleted = client.get('deleted') or client.get('delete') %}
{%-     set customer_was_present = salt['pillar.get']('customers:domains:%s'|format(client.domain_name)) %}
{%-     if not customer_deleted or customer_was_present %}
{%-       if client['enabled'] %}
    - {{ client.domain_name -}}
{%-       else %}
    - {{ client.domain_name -}}:
      disable: True
{%-       endif %}
{%-     endif %}
{%-   endif %}
{%- endfor -%}
