#!/usr/bin/pythoargsn
# -*- coding: utf-8 -*-
# vim: set ft=python:
#
# python password generator
# Depend: pwqgen
# Usage:
#  ./customers_passwords.py pillarpath/to/customers.sls pillarpath/user_passwords.yaml
#
# Output: Int, the number of created passwords in pillarpath/user_passwords.sls
#
# fileformat:
#   /!\ input files are PURE yaml file format
#
#  customers.sls:
#    wsf:
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

def random_pass():
    res = subprocess.check_output(["pwqgen"]).rstrip()
    return res

def unix_pass(password):
    saltpw = str(random.randint(2**10, 2**32))
    args = ['openssl', 'passwd', '-1', '-salt', saltpw, password]
    res = subprocess.check_output(args).rstrip()
    return res

def main():
    user_db = sys.argv[1]
    f = open(user_db)
    userDB = yaml.safe_load(f)
    f.close()

    password_db = sys.argv[2]
    try:
        f = open(password_db)
        passDB = yaml.safe_load(f)
        f.close()
    except IOError as e:
        passDB = {}

    # hardcoded path to access data
    mysql_users = userDB['wsf']['customers'].keys()
    if passDB:
        user_with_pass = passDB.keys()
    else:
        user_with_pass = []
        passDB = {}

    missing_password =  set(mysql_users) - set(user_with_pass)

    n = 0
    for u in missing_password:
        shell_pass = random_pass()
        new_pass = {'mysql' : random_pass(),
                    'shell' : shell_pass,
                    'hash': unix_pass(shell_pass) }
        passDB[u] = new_pass
        n += 1

    # check for missing fields
    # loop over missing fields if any and complete
    fields = ['mysql', 'shell', 'hash']
    for u, passwd in passDB.items():
        for p in fields:
            myp = passwd.get(p)
            if myp == None or myp == '':
                if p == 'hash':
                    hashed = unix_pass(passDB[u]['shell'])
                    passDB[u]['hash'] = hashed
                elif p == 'shell':
                    passDB[u]['hash'] = None
                    passDB[u][p] = random_pass()
                else:
                    passDB[u][p] = random_pass()

                n += 1

    # write back modified yaml
    if n > 0:
        f = open(password_db, 'w')
        f.write(yaml.dump(passDB, default_flow_style=False))
        f.close()

    return n


if __name__ == '__main__':
    print(main())
