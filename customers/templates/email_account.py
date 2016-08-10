#!py
# vim: set ft=python et sw=4 sts=4 ts=4:

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
customers:
  email:
    domain:
""".lstrip()

    global output
    output = header

    if test:
        for k, v in test.items():
            globals()[k] = v

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
    for name, emails in account.items():
        if len(emails) > 0:
            _p(indent, name + ':')
            for email in emails:
                _p(indent + 2, '- ' + email)

    return output
