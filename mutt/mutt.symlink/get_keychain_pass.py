#!/usr/bin/python
#
# http://stevelosh.com/blog/2012/10/the-homely-mutt/#configuring-offlineimap
#

import os, re, subprocess

def get_keychain_pass(account=None, server=None):
  params = {
    'user': os.environ['USER'],
    'security': '/usr/bin/security',
    'command': 'find-internet-password',
    'account': account,
    'server': server,
    'keychain': os.environ['HOME'] + '/Library/Keychains/login.keychain'
  }

  command = "sudo -u %(user)s %(security)s -v %(command)s -g -a %(account)s -s %(server)s %(keychain)s" % params
  output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
  outtext = [line for line in output.splitlines() if line.startswith('password: ')][0]
  return re.match(r'password: "(.*)"', outtext).group(1)
