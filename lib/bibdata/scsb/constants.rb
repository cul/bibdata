# frozen_string_literal: true

module Bibdata::Scsb::Constants
  CGD_PRIVATE = 'Private'
  CGD_SHARED = 'Shared'
  CGD_COMMITTED = 'Committed'
  CGD_OPEN = 'Open' # NOTE: we don't actually ever send this value

  CGD_PRIVATE_LOCATION_CODES = [
    'avda',
    'off,avda',
    'avr4off',
    'bmcr4off',
    'off,bmcr',
    'off,avr',
    'off,bssc',
    'dic',
    'dic4off',
    'off,dic',
    'eaa4off',
    'off,eaa',
    'ean',
    'off,ean',
    'ear',
    'off,ear',
    'far',
    'far4off',
    'off,far',
    'off,hssc',
    'hsx',
    'off,hsx',
    'les',
    'off,les',
    'oral',
    'off,oral',
    'prd',
    'off,prd',
    'rbms',
    'off,rbms',
    'rbx',
    'rbx4off',
    'off,rbx',
    'uacl',
    'off,uacl',
    'unr',
    'off,unr',
    'uta',
    'off,uta',
    'utmrl',
    'off,utrml',
    'vmc',
    'off,vmc'
  ].freeze

  CGD_PRIVATE_BARCODE_PREFIXES = [
    'RS',
    'AD',
    'HX',
    'UA',
    'UT'
  ].freeze

  USE_RESTRICTION_IN_LIBRARY_USE = 'In Library Use'
  USE_RESTRICTION_SUPERVISED_USE = 'Supervised Use'
  USE_RESTRICTION_BLANK = ''

  # Any code in this list should result in an "In Library Use" Use Restriction value.
  USE_RESTRICTION_IN_LIBRARY_USE_LOCATION_CODES = [
    'off,ave',
    'off,fax',
    'off,mrr',
    'off,msr',
    'off,mvr'
  ].freeze
end
