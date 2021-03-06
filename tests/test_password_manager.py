#
# unittest
#
import sys
sys.path.append('../customers')
import pytest

import os
import copy
from shutil import copyfile
import password_manager
import customers_passwords

import difflib

def _read_yaml(password_db = 'old_pass.yaml'):
    assert os.path.isfile(password_db)
    return customers_passwords.read_yaml(password_db)

def test_email_pass_present():
    db = _read_yaml()

    c = 'client8'
    address = 'test@domain.com'
    with pytest.raises(ValueError):
        assert not password_manager.email_pass_present(c, address, db)

    db[c][address] = ''
    assert db[c].has_key(address)
    assert not password_manager.email_pass_present(c, address, db)

    db[c][address] = 'some'
    assert password_manager.email_pass_present(c, address, db)

def test_email_pass_set():
    db = _read_yaml()

    address = 'test@domain.com'
    c = 'client8'
    assert password_manager.email_pass_set(c, address, db)

    assert db[c][address] != ''

    with pytest.raises(ValueError):
        assert password_manager.email_pass_set('unexsitant', address, db)

def test_email_pass_get():
    db = _read_yaml()

    address = 'test@domain.com'
    c = 'client8'
    db[c][address] = 'some'
    ret = {}
    r = password_manager.email_pass_get(c, address, db, ret)
    assert r
    assert ret['ret'] == 'some'

    # raise with unexistant emil
    with pytest.raises(ValueError):
        password_manager.email_pass_get(c, address+'rand', db, ret)

    with pytest.raises(ValueError):
        password_manager.email_pass_get('unexsitant', address, db, ret)

    # test create True
    ret = {'create' : True }
    del db[c][address]
    assert not db[c].has_key(address)
    assert password_manager.email_pass_get(c, address, db, ret)
    passwd = ret['ret']
    assert len(db[c][address]) > 8
    assert db[c][address] == passwd

    # don't overwrit password
    assert password_manager.email_pass_get(c, address, db, ret)
    assert db[c][address] == passwd

def test_main(capsys):
    password_file = 'old_pass.yaml'
    password_file_new = password_file + '.new'
    copyfile(password_file, password_file_new)

    c = 'client1'
    a = 'sylvain@email.com'

    # present is failing
    with pytest.raises(ValueError):
        password_manager.main('present', c, a, password_file_new)

    # ADD new email and generate password
    password_manager.main('add', c, a, password_file_new)

    # diff genrator$
    r = difflib.context_diff(open(password_file).readlines(),
                             open(password_file_new).readlines())

    # fetch the row that containsthe address
    newv = [ l for l in r if l.startswith('+   ' + a)]

    assert len(newv) == 1
    assert newv[0] != ''

    # newv is a diff output of the yaml line, keep only the value
    new_pass = newv[0].split(':')[1].lstrip()

    # read the generated pass
    password_manager.main('read', c, a, password_file_new)
    # output captured via fixture, See def (capsys):
    # http://doc.pytest.org/en/latest/capture.html#accessing-captured-output-from-a-test-function
    out, err = capsys.readouterr()
    assert out == new_pass

    # recheck
    assert password_manager.main('present', c, a, password_file_new)

    os.remove(password_file_new)
