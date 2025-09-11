# frozen_string_literal: true

module Bibdata::OffisteLocationFlipper
  LOCATION_CODE_NORMALIZATION_MAP = {
    'avda,anx2' => 'avda',
    'ave,anx2' => 'ave',
    'avelc' => 'ave',
    'avelcn' => 'ave',
    'ariz' => 'sci',
    'avr' => 'avr',

    'bus,anx2' => 'bus',
    'bus' => 'bus',
    'busn' => 'bus',
    'bus,stor' => 'bus',
    'bio,anx2' => 'bio',
    'bio' => 'bio',
    'bmc' => 'bmc',
    'bmc,res' => 'bmc',
    'bmcr' => 'bmcr',
    'bio,ser' => 'bio',
    'bio,ref' => 'bio',

    'che,anx2' => 'che',
    'che,ser' => 'che',
    'che,ref' => 'che',
    'che,anx' => 'che',
    'che' => 'che',

    'dic,anx2' => 'dic',
    'docs' => 'docs',

    'eal,anx2' => 'eal',
    'eax' => 'eax',
    'eax,anx2' => 'eax',
    'eax,tib' => 'eax',
    'eax,sky' => 'eax',
    'eng,anx2' => 'eng',
    'eng' => 'eng',
    'eng,ref' => 'eng',
    'eng,anx' => 'eng',
    'eal,anx' => 'eal',
    'eax,anx' => 'eax',
    'eal' => 'eal',
    'ean' => 'ean',
    'ear' => 'ear',
    'eaa' => 'eaa',

    'fax,anx2' => 'fax',
    'faxlc' => 'fax',
    'faxlcn' => 'fax',
    'far' => 'far',

    'glg,anx2' => 'glg',
    'glx,anx' => 'glx',
    'glx,anx2' => 'glx',
    'glx,rare' => 'glx',
    'gnc' => 'gnc',
    'gsc,anx2' => 'gsc',
    'gsc,ref' => 'glg',
    'gsc' => 'glg',
    'gsc,jour' => 'glg',

    'jou' => 'jou',

    'leh' => 'leh',
    'leh,anx2' => 'leh',
    'leh,bdis' => 'bus',
    'leh,pl' => 'glx',
    'leh,ref' => 'leh',
    'leh,slav' => 'leh',
    'leh,tib' => 'eax',
    'les,anx2' => 'les',
    'lsw,ref' => 'leh',

    'manc' => 'glx',
    'mil,anx2' => 'glx',
    'mrr' => 'mrr',
    'msa' => 'msr',
    'msc,anx' => 'msc',
    'msc,anx2' => 'msc',
    'msc,fol' => 'msc',
    'msc,ref' => 'msc',
    'msr,anx2' => 'msr',
    'mus,anx' => 'mus',
    'mus,anx2' => 'mus',
    'mus,ref' => 'mus',
    'mvr' => 'mvr',

    'oral' => 'oral',

    'phy' => 'phy',
    'phy,anx2' => 'phy',
    'phy,ser' => 'phy',
    'pren' => 'glx',
    'pren,eal' => 'eal',
    'pren,eax' => 'eax',
    'pren,fol' => 'glx',
    'pren,msc' => 'msc',
    'pren,mscr' => 'msc',
    'pren,msr' => 'msr',
    'pren,psy' => 'psy',
    'pren,ref' => 'ref',

    'rbms' => 'rbms',
    'rbx' => 'rbx',
    'rbx,anx2' => 'rbx',
    'ref' => 'ref',
    'ref,anx2' => 'ref',

    'sci' => 'sci',
    'sci,anx' => 'sci',
    'sci,anx2' => 'sci',
    'sci,ref' => 'sci',
    'sls' => 'glx',
    'swx' => 'swx',
    'swx,anx2' => 'swx',

    'uts,fic' => 'mrr',
    'uts,fil' => 'mrr',
    'uts,mrld' => 'utmrl',
    'uts,mrldxf' => 'utmrl',
    'uts,mrlo' => 'utmrl',
    'uts,mrloxf' => 'utmrl',
    'uts,unnr' => 'unr',
    'uts,unnxxp' => 'utp',
    'uts' => 'uts',
    'uts,arc' => 'uta',
    'uacl,low' => 'uacl',
    'uacl' => 'uacl',

    'vmc' => 'vmc',

    'war,anx2' => 'war'
  }

  def self.location_code_to_recap_flipped_location_code(location_code, barcode) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return location_code if location_code.start_with?('off,')

    return off('bssc') if barcode.start_with?('BS')
    # return off('mrr') if barcode.start_with?('CR') && type == 'microform' # TODO: Where does item type come from in FOLIO?

    return LOCATION_CODE_NORMALIZATION_MAP[location_code] if LOCATION_CODE_NORMALIZATION_MAP.key?(location_code)

    return off('hsl') if barcode.start_with?('HS') && location_code.include?('hs')
    return off('hsr') if barcode.start_with?('HR') && location_code.include?('hs')
    return off('hssc') if barcode.start_with?('HX') && location_code.include?('hs')

    if /4off/i.match?(location_code)
      new_location_code = location_code.sub(/4off/i, '')
      if LOCATION_CODE_NORMALIZATION_MAP.key?(new_location_code)
        new_location_code = LOCATION_CODE_NORMALIZATION_MAP[new_location_code]
      end
      return new_location_code
    end

    nil

    # Continue with perl script on line 589: https://github.com/cul/libsys-scripts/blob/master/recap/daily/recap.dbi.pl#L589C5-L589C30
  end

  # Prefixes the given location code with 'off,'
  def self.off(location_code)
    "off,#{location_code}"
  end
end
