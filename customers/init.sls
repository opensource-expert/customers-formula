# process customers in customers.sls pillar
#
# !! Warning: this is a state which create pillar for other states
#
# generated files are in the pillar and must be reviewed by the admin
# before applying any other state
#

# target folder for generated pillar
{% set pillar_dir = '/srv/salt/pillar' -%}
{% set target_dir = pillar_dir + '/auto' -%}
{{ target_dir }}:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755

# produce managed databases for customers in pillar/customers
{{ target_dir }}/mysql_db.sls:
  file.managed:
    - source: salt://customers/templates/databases.sls
    - user: root
    - group: root
    - mode: 644
    - template: jinja

# generate password for customers
{% set password_db = target_dir + '/managed_password.yaml' -%}
{% set user_db = pillar_dir + '/customers.sls' -%}
{% set formuladir = '/srv/salt/formulas/customers-formula/customers' %}
{% set password_gen = formuladir ~ '/customers_passwords.py' %}
check_passwords:
  cmd.run:
    - name: {{ password_gen }}  {{ user_db }} {{ password_db }}
    - cwd: {{ formuladir }}
    - unless: test {{ password_db }} -nt {{ password_gen }} -a {{ password_db }} -nt {{ user_db }}

# just ensure restricted permissions
generate_customers_passwords:
  file.managed:
    - name: {{ password_db }}
    - user: root
    - group: root
    - mode: 600

# produce managed databases for customers in pillar/customers
{{ target_dir }}/mysql_users.sls:
  file.managed:
    - source: salt://customers/templates/mysql_users.sls
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
       password_db: {{ password_db }}

# produce managed domains, if customer is enabled, and has DNS service
{{ target_dir }}/domains.sls:
  file.managed:
    - source: salt://customers/templates/domains.sls
    - user: root
    - group: root
    - mode: 644
    - template: jinja

# produce webconfig
{{ target_dir }}/webconfig.sls:
  file.managed:
    - source: salt://customers/templates/webconfig.sls
    - user: root
    - group: root
    - mode: 644
    - template: jinja

# produce shellusers
{{ target_dir }}/shell_users.sls:
  file.managed:
    - source: salt://customers/templates/shell_users.sls
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
       password_db: {{ password_db }}
