#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: set ft=python:
#
# python password generator
# Depend: pwqgen
# Usage:
#  ./customers_passwords.py customers_top pillarpath/to/customers.sls pillarpath/user_passwords.yaml
#
# Output: Int, the number of created passwords in pillarpath/user_passwords.sls
#
# fileformat:
#   /!\ input files are PURE yaml file format
#
#  customers.sls:
#    customers_top:
#      customers:
#        client1: <-- key used for password match as username
#          […]
#        client2:
#        client3:
#
#  user_passwords.yaml: will be overwritten if any, don't put anything non-yaml
#    client1:
#      mysql: bla
#      shell: piou
#    client2:
#      mysql: somepassword
#      shell: shelllpassword
#    client3:
#      mysql: Them3symbol-Sit
#      shell: flint*forbid_false

from __future__ import absolute_import
import subprocess
import sys
import yaml
import random
from collections import OrderedDict

def random_pass():
    res = subprocess.check_output(["pwqgen"]).rstrip()
    return res

def unix_pass(password):
    saltpw = str(random.randint(2**10, 2**32))
    args = ['openssl', 'passwd', '-1', '-salt', saltpw, password]
    res = subprocess.check_output(args).rstrip()
    return res

def read_yaml(filename):
    f = open(filename)
    data = yaml.safe_load(f)
    f.close()
    return data

def create_all_pass():
    """
    retrun an OrderedDict of all password

        new_pass['mysql'] = random_pass()
        new_pass['shell'] = shell_pass
        new_pass['hash'] = unix_pass(shell_pass)
    """
    shell_pass = random_pass()
    new_pass = OrderedDict()
    new_pass['mysql'] = random_pass()
    new_pass['shell'] = shell_pass
    new_pass['hash'] = unix_pass(shell_pass)
    return new_pass

def write_password_db_yaml(fname, passDB):
    """
    write ordered password db, in an yaml compatible way.
    """

    f = open(fname, 'w')
    for u, passwd in passDB.items():
        f.write("%s:\n" % u)
        for k in passwd.keys():
            f.write("  %s: %s\n" % (k, passwd[k]))

    # this outputer as some difficulties with OrderedDict
    # f.write(yaml.dump(passDB, default_flow_style=False))
    f.close()

def update_missing_fields(passDB, force_hash=False):
    """
    check for missing fields, if new fields have been added
    loop over all fields, and complete if any.

    if force_hash is True, recompute hashes

    return number of updated records
    """

    # fetch fields
    fields = create_all_pass().keys()
    n = 0

    for u, passwd in passDB.items():
        # check for new added possibly missing fields
        for p in fields:
            # reads this passsword
            myp = passwd.get(p)
            if (myp == None or myp == '') or (force_hash and p == 'hash'):
                if p == 'hash':
                    hashed = unix_pass(passDB[u]['shell'])
                    passDB[u]['hash'] = hashed
                elif p == 'shell':
                    # reset hash, will be computed in next loop
                    passDB[u]['hash'] = None
                    passDB[u][p] = random_pass()
                else:
                    passDB[u][p] = random_pass()
                # we have modified some entries
                n += 1
    return n

def main(customers_top, user_db, password_db):
    userDB = read_yaml(user_db)

    # we can handle non existant password file
    try:
        passDB = read_yaml(password_db)
    except IOError as e:
        passDB = {}

    # hardcoded path to access data for customers
    mysql_users = userDB[customers_top]['customers'].keys()

    # keys names matching username are top level
    if passDB:
        user_with_pass = passDB.keys()
    else:
        # empty
        user_with_pass = []
        passDB = {}

    missing_password =  set(mysql_users) - set(user_with_pass)

    n = 0
    # add missing passwords
    for u in missing_password:
        passDB[u] = create_all_pass()
        n += 1

    # update is some new fields has been added
    n += update_missing_fields(passDB)

    # write back modified yaml
    if n > 0:
        write_password_db_yaml(password_db, passDB)

    # return number of new created password entries
    return n


if __name__ == '__main__':
    customers_top = sys.argv[1]
    user_db = sys.argv[2]
    password_db = sys.argv[3]
    print(main(customers_top, user_db, password_db))
