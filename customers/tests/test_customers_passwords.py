#
# unittest
#
import sys
sys.path.append('..')

import os
from customers_passwords import *

def _create_yaml(fname):
    f = open(fname, "wt")
    f.write("key: val\n")
    f.close()

def _create_passDB(count=3):
    data = OrderedDict()
    i = 1
    while i <= count:
        data['user%d' % i] = create_all_pass()
        i += 1
    return data

def test_read_yaml():
    fname = 'some.yaml'
    _create_yaml(fname)
    data = read_yaml(fname)

    assert type(data) == dict
    assert len(data) == 1
    assert data['key'] == 'val'

    os.remove(fname)

def test_random_pass():
    data = random_pass()

    assert type(data) == str
    assert len(data) >= 8

def test_create_all_pass():
    data = create_all_pass()

    assert len(data) == 3
    for k, p in data.items():
        assert len(p) >= 8

    assert data['hash'] != data['shell']
    assert data['mysql'] != data['shell']

    # OrderedDict
    assert data.keys() == ['mysql', 'shell', 'hash' ]

def test_write_password_db_yaml():
    fname = 'pass.yaml'
    data = _create_passDB(3)

    write_password_db_yaml(fname, data)

    assert os.path.isfile(fname)

    f = open(fname)
    content = f.readlines()
    f.close()
    assert content[0] == "user1:\n"

    # reread as yaml
    data2 = read_yaml(fname)

    assert data['user1'] == data2['user1']

    os.remove(fname)
    assert not os.path.isfile(fname)

def test_update_missing_fields():
    passDB = _create_passDB(5)

    n = update_missing_fields(passDB)
    assert n == 0

    # remove hash
    for k in passDB:
        del passDB[k]['hash']

    n = update_missing_fields(passDB)

    assert n == 5
    assert len(passDB['user1']['hash']) >= 8

    # noting new
    n = update_missing_fields(passDB)
    assert n == 0

    # remove shell so hash is computed too
    old_hash = passDB['user5']['hash']
    del passDB['user5']['shell']
    n = update_missing_fields(passDB)
    assert n == 2
    assert len(passDB['user5']['hash']) >= 8
    assert passDB['user5']['hash'] != old_hash

    # force_hash computation
    old_hash = passDB['user5']['hash']
    n = update_missing_fields(passDB, force_hash=True)
    assert n == 5
    assert passDB['user5']['hash'] != old_hash


def test_main():
    user_db = '../pillar.example'
    password_db = 'pass.yaml'

    assert os.path.isfile(user_db)
    assert not os.path.isfile(password_db)

    main(user_db, password_db)
    assert os.path.isfile(password_db)

    users = read_yaml(user_db)
    passwords = read_yaml(password_db)

    user_names = users['wsf']['customers'].keys()
    pass_user_names = passwords.keys()
    assert user_names == pass_user_names

    os.remove(password_db)


