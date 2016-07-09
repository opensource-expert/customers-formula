# process customers in customers.sls pillar
#
# !! Warning: this is a state which create pillar for other states
#
# generated files are in the pillar and must be reviewed by the admin
# before applying any other state
#

# target folder for generated pillar
{% set pillar_dir = '/srv/salt/pillar' -%}
{% set customers_top = salt['pillar.get']('customers_top') %}

{% if not customers_top %}
Fail - no customers_top:
  test.fail_without_changes:
    # https://docs.saltstack.com/en/latest/ref/states/failhard.html
    - failhard: True
{% endif %}

{% if not salt['pillar.get']('%s:customers'|format(customers_top)) %}
Fail - no customers found:
  test.fail_without_changes:
    - failhard: True
{% endif %}

{% set customers_dir = salt['pillar.get']('%s:global:customers_dir'|format(customers_top), '.') -%}
{# # replace with destination dir -#}
{% set target_dir = (pillar_dir + '/' + customers_dir + '/auto')|replace('/./', '/') -%}
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
    - defaults:
        customers_top: {{ customers_top }}

# generate password for customers
{% set password_db = target_dir + '/managed_password.yaml' -%}
{% set user_db = pillar_dir + '/' + customers_dir + '/customers.sls' -%}
{% set formuladir = '/srv/salt/formulas/customers-formula/customers' %}
{% set password_gen = formuladir ~ '/customers_passwords.py' %}
check_passwords:
  cmd.run:
    - name: {{ password_gen }} {{ customers_top }} {{ user_db }} {{ password_db }} && touch {{ password_db }}
    - cwd: {{ formuladir }}
    # run only if: the script is newer or customers.sls is newer, but may not generate any new password
    - onlyif: test {{ password_gen }} -nt {{ password_db }} -o {{ user_db }} -nt {{ password_db }}


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
       customers_top: {{ customers_top }}

# produce managed domains, if customer is enabled, and has DNS service
{{ target_dir }}/domains.sls:
  file.managed:
    - source: salt://customers/templates/domains.sls
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
       customers_top: {{ customers_top }}

# produce webconfig
{{ target_dir }}/webconfig.sls:
  file.managed:
    - source: salt://customers/templates/webconfig.sls
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
       customers_top: {{ customers_top }}

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
       customers_top: {{ customers_top }}

# produce email domains and mail account
{{ target_dir }}/email_account.sls:
  file.managed:
    - source: salt://customers/templates/email_account.sls
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
       customers_top: {{ customers_top }}
