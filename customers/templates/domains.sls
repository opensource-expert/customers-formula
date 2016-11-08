{# vim: set ft=jinja: -#}
#
# DON'T EDIT THIS FILE: salt managed file
#
customers:
  # Managed domains for customers
  domains:
{#- produce managed domains, if customer is enabled, and has DNS the service #}
{%- for name, client in salt['pillar.get']('%s:customers'|format(customers_top), {}).items() -%}
{%-   if 'dns' in client['services'] %}
{%-     set customer_deleted = client.get('deleted') or client.get('delete') %}
{%-     set customer_was_present = salt['pillar.get']('customers:domains:%s'|format(client.domain_name)) %}
{%-     set disable = not client['enabled'] %}
{%-     if not customer_deleted or customer_was_present %}
    {{ client.domain_name -}}:
      disable: {{ disable }}
      {%- if client.get('override', {}).get('mailserver') %}
      mailserver: {{ client['override']['mailserver'] }}
      {%- endif %}
      {%- if client.get('override', {}).get('interface') %}
      web_ip: {{ client['override']['interface'] }}
      {%- endif %}
{%-     endif %}
{%-   endif %}
{%- endfor -%}
