#
# unittest
#

# NOT WORKING
import sys
sys.path.append('../customers/templates/')

import email_account

def test__is_present():
    customer = { 'delete' : True }
    globals()['__salt__'] = {}
    assert not email_account._is_present(customer)
    del(customers['delete'])
    assert email_account._is_present(customer)
