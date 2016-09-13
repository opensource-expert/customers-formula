# Manage data override

See: `templates/databases.sls`

read from pillar

~~~yaml
{%- for name, client in salt['pillar.get']('%s:customers'|format(customers_top), {}).items() %}
~~~

choose override parameter if any, over `name` as default `db_name`

~~~yaml
      {%- set db_name = client.get('override', {}).get('database', name) %}
    - {{ db_name -}}
~~~
