{# vim: set ft=jinja: -#}
#
# DON'T EDIT THIS FILE: salt managed file
#
customers:
  email:
    domain:
      {%- set customers = salt['pillar.get']('%s:customers'|format(customers_top), {}) %}
{#- produce managed domains, if customer is enabled, and has email the service #}
{%- for name, client in customers.items() -%}
{%-   if 'email' in client['services'] %}
{%-     set customer_deleted = client.get('deleted') or client.get('delete') %}
{%-     set customer_was_present = salt['pillar.get']('customers:email:domain:%s'|format(client.domain_name)) %}
{%-     if not customer_deleted or customer_was_present %}
      {{ client.domain_name -}}:
{%-       if not client['enabled'] %}
        disable: True
{%-       endif %}
        customer_name: {{ name }}
{%-     endif %}
    accounts:
      {{ name }}:
      {%- for email in customers[name].get('email_accounts', []) %}
          {%- set dom = '@' ~ client.domain_name %}
          {#- the replace allow to write name or name@ or name@fuldom #}
          - {{ (email ~ dom)|replace('@@', '@')|replace(dom * 2, dom) }}
      {%- endfor %}
{%-   endif %}
{%- endfor -%}
