{# vim: set ft=jinja: -#}
#
# DON'T EDIT THIS FILE: salt managed file
#
{% macro define_if(key, client, override_key) %}
      {%- if client.get('override', {}).get(override_key) %}
      {{ key }}: {{ client['override'][override_key] }}
      {%- endif -%}
{% endmacro -%}

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
      {{- define_if('mailserver', client, 'mailserver') }}
      {{- define_if('web_ip', client, 'interface') }}
      {{- define_if('ns2', client, 'ns2') }}
{%-     endif %}
{%-   endif %}
{%- endfor -%}
