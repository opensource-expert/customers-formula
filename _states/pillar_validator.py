# -*- coding: utf-8 -*-
'''
:maintainer: Sylvain Viart (opensource-expert@github)
:maturity: prototype
:requires: none
:platform: all
'''

from __future__ import absolute_import
import logging
import salt.exceptions

LOG = logging.getLogger(__name__)

# name of the state functions
__virtualname__ = 'customers'

def __virtual__():
    '''
    Determine whether or not to load this module
    '''
    return True

def validate_pillar(name, customers_top, **kwargs):
    '''
    "validate_pillar" check pillar for customers

    .. code-block:: yaml

        check_customers_pillar:
          # it use a custom state in _state/
          customers.validate_pillar:
            - customers_top: {{ customers_top }}
            - failhard: True
    '''
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': '',
        'pchanges': {},
        }

    customers_pillar = __salt__['pillar.get'](customers_top, {})

    required_keys = ['domain_name', 'services']
    error = {}
    count = 0
    tested = 0

    # validation loop
    for customer, conf in customers_pillar['customers'].items():
        # check for key
        ckeys = conf.keys()
        error[customer] = []
        for k in required_keys:
            if k not in ckeys:
                error[customer].append("missing key '%s'" % k)
                count += 1
        tested += 1

    if count > 0:
        ret['changes'] = { 'ret': ('tested customers: %d' % tested) }
        ret['comment'] = error
    else:
        ret['result'] = True
        ret['comment'] = 'pillar OK'

    return ret
