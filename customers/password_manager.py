#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: set ft=python:
#
# python password manager for customer email account
#
# Depend: pwqgen, customers_passwords.py
#
# Usage:
#  ./password_manager.py add CUSTOMER EMAIL YAML_PASSWORD
#  ./password_manager.py present CUSTOMER EMAIL YAML_PASSWORD
#  ./password_manager.py read CUSTOMER EMAIL YAML_PASSWORD
#
# Output:
#
# fileformat:
#   /!\ input files are PURE yaml file format, no jinja
#
#  user_passwords.yaml: will be overwritten if any, don't put anything non-yaml
#    client1:
#      mysql: bla
#      shell: piou
#      websmtp: somepass_for_controling_email_from_the_web
#      hash: $1$17391272$rgWtYpRIDVUrT202c89Fp1
#      someemail@domain.com
#      email2@domain.com
#    client2:
#      mysql: somepassword
#      shell: shelllpassword
#      websmtp: my_web_pass_for_mail
#      hash: $1$17391272$rgWtYpRIDVUrT202c89Fp1
#      info@client2.com

# unittest: See ../tests/test_password_manager.py

from __future__ import absolute_import
import sys

# import other tool
import customers_passwords

def email_pass_present(customer, email, passDB):
    try:
        has_email = passDB.get(customer).has_key(email)
    except AttributeError:
        raise ValueError("not found: %s:%s" % (customer, email))

    if not has_email:
        raise ValueError("no password found: %s:%s" % (customer, email))
    else:
        email_pass = passDB.get(customer).get(email)
        if email_pass:
            return True
        else:
            return False

# get value back in ret['ret'],
# call:
#   ret = {}
#   email_pass_get(customer, email, db, ret)
def email_pass_get(customer, email, passDB, ret):
    try:
        r = email_pass_present(customer, email, passDB)
    except ValueError:
        if ret.has_key('create') and ret['create']:
            email_pass_set(customer, email, passDB)
            r = True
        else:
            raise
    if r:
        ret['ret'] = passDB[customer][email]
        return True
    else:
        return False

def email_pass_set(customer, email, passDB):
    email_pass = customers_passwords.random_pass()
    try:
        passDB[customer][email] = email_pass
    except KeyError:
        raise ValueError("customer not found: %s" % (customer))

    return True

def main(action, customer, email, password_file):
    # we can handle non existant password file
    try:
        passDB = customers_passwords.read_yaml(password_file)
    except IOError as e:
        print("password_file not found: '%s'" % password_file)
        sys.exit(15)

    # check if customer exists
    if not passDB.get(customer):
        raise "you must init customer first, See customers_passwords.py"

    if action == 'present':
        return email_pass_present(customer, email, passDB)
    elif action == 'add':
        r = email_pass_set(customer, email, passDB)
        if r:
            customers_passwords.write_password_db_yaml(password_file, passDB)
        return True
    elif action == 'read':
        ret = {}
        r = email_pass_get(customer, email, passDB, ret)
        if r:
            print(ret['ret'])
        return r

if __name__ == '__main__':
    actions = ['add', 'present', 'read']

    action = sys.argv[1]
    if action not in actions:
        raise ValueError('invalide action not in: %s' % ', '.join(actions))
    customer = sys.argv[2]
    email = sys.argv[3]
    password_file = sys.argv[4]


    r = main(action, customer, email, password_file)
    if r:
        sys.exit(0)
    else:
        sys.exit(1)

