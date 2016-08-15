#!py
# vim: set ft=python et sw=4 sts=4 ts=4:
#
# template pure python
#
# Produces:
#
# customers:
#   email:
#     domain:
#       cavagnoud.com:
#         customer_name: cavagnoud
#       esprit-montagne.com:
#         customer_name: esprit-mon
#       type-top-remorques.fr:
#         customer_name: typetop
#       mariageclosteph.com:
#         customer_name: client1
#       crylax.com:
#         customer_name: crylaxcom
#       deco-des-cimes.com:
#         customer_name: decodescim
#     accounts:
#       cavagnoud:
#         - contact@cavagnoud.com
#       typetop:
#         - stats@type-top-remorques.fr
#       client1:
#         - sylvain@mariageclosteph.com
#         - vincent@mariageclosteph.com
#         - spamtrap@mariageclosteph.com
#         - someone@mariageclosteph.com
#       crylaxcom:
#         - contact@crylax.com
#         - info@crylax.com
#       decodescim:
#         - contact@deco-des-cimes.com
#         - stats@deco-des-cimes.com

import sys

def _is_present(client):
    customer_deleted = client.get('deleted') or client.get('delete')
    customer_was_present = __salt__['pillar.get']('customers:email:domain:%s'% (client['domain_name']))
    return not customer_deleted or customer_was_present

def _p(indent, txt):
    global output
    output += "%s%s\n" % (' ' * indent, txt)

output = ''

def run(test = None):
    """
    generate mail account template for customers
    """

    header = """
#
# DON'T EDIT THIS FILE: salt managed file
#
{%% import_yaml "%(password_db)s" as pass with context %%}
customers:
  email:
    domain:
""".lstrip() % context

    global output
    output = header

    if test:
        for k, v in test.items():
            globals()[k] = v

    # context[] not avaible outside the function
    sys.path.append(context['customers_path'])
    import password_manager
    import customers_passwords

    customers_top = context['customers_top']
    customers = __salt__['pillar.get']('%s:customers' % customers_top, {})
    account = {}
    indent = 6

    # produce managed domains, if customer is enabled, and has email the service
    for name, client in customers.items():
        if 'email' in client['services']:
            if _is_present(client):
                _p(indent, client['domain_name'] + ':')

            if not client['enabled']:
                _p(indent + 2, 'disable: True')

            _p(indent + 2, 'customer_name: %s' %  name)

            # email account collector
            account[name] = []
            for email in customers[name].get('email_accounts', []):
                # allow the
                dom = '@' + client['domain_name']
                # the replace allow to write name or name@ or name@fuldom
                email = (email + dom).replace('@@', '@').replace(dom * 2, dom)
                account[name].append(email)

    # output emails accounts, for customers only if they have some
    _p(indent - 2, 'accounts:')
    # open password_manager database
    db = customers_passwords.read_yaml(context['password_db'])
    # output template for echo email account with password
    tmpl = "%(email)s: \"{{ pass['%(name)s']['%(email)s'] }}\""
    for name, emails in account.items():
        if len(emails) > 0:
            _p(indent, name + ':')
            for email in emails:
                passwd = { 'create' : context.get('create_pass') }
                password_manager.email_pass_get(name, email, db, passwd)
                # password is included from password store
                s = tmpl % dict(email=email, name=name)
                _p(indent + 2, s)

    # created password must be saved
    if context.get('create_pass'):
        customers_passwords.write_password_db_yaml(context['password_db'], db)


    return output
