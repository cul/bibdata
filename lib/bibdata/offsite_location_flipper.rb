# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength, Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
module Bibdata::OffsiteLocationFlipper
  MATERIAL_TYPE_MICROFORMAT = 'Microformat'

  # For the given location_code and barcode, returns the "flipped" equivalent code that should be used
  # when an item has arrived at the ReCAP facility.
  # @return [String, nil] a "flipped" string location code, or nil if the given location_code cannot be mapped
  #                       to a "flipped" version.
  def self.location_code_to_recap_flipped_location_code(location_code, barcode, material_type)
    # If the location code starts with "off," no modification is needed.
    # Return the unmodified location code because it is already an offsite ReCAP code.
    return location_code if location_code.start_with?('off,')

    # For any location code that ends with "4off", we will remove the ending "4off" part and prefix the remaining part
    # with "off,".  So "abc4off" becomes "off,abc".  None of the rules below will be evaluated.
    # "4off"-ending locations are applied with design and intention and this is what they always mean.
    return off(location_code[0...-4]) if location_code.end_with?('4off')

    # Variants that should be reviewed in the future, but we will keep them in place for now
    return off('avda') if location_code == 'avda' && barcode.start_with?('AD')
    return off('glx') if location_code == 'glx' && barcode.start_with?('CU', 'CR')
    return off('rbx') if location_code == 'glx' && barcode.start_with?('RS')
    return off('msc') if location_code == 'msc' && barcode.start_with?('MR')
    return off('msr') if location_code == 'msr' && barcode.start_with?('MR')
    return off('prd') if location_code == 'prd' && barcode.start_with?('CM')
    return off('mat') if location_code == 'mat' && barcode.start_with?('CU', 'CR')

    # Avery Special Collections
    return off('avda') if location_code == 'avda,anx2'
    return off('avr') if location_code == 'avr'
    return off('far') if location_code == 'far'
    return off('vmc') if location_code == 'vmc'

    # Burke Special Collections
    return off('uta') if location_code == 'uts,arc'
    return off('utmrl') if location_code == 'uts,mrld'
    return off('utmrl') if location_code == 'uts,mrldxf'
    return off('utmrl') if location_code == 'uts,mrlo'
    return off('utmrl') if location_code == 'uts,mrloxf'
    return off('unr') if location_code == 'uts,unnr'
    return off('utp') if location_code == 'uts,unnxxp'

    # East Asian Special Collections
    return off('ean') if location_code == 'ean'
    return off('ear') if location_code == 'ear'
    return off('eaa') if location_code == 'eaa'

    # Health Sciences
    return off('hsl') if barcode.start_with?('HS') && location_code.include?('hs')
    return off('hsl') if barcode.start_with?('HR') && location_code.include?('hs')
    return off('hssc') if barcode.start_with?('HX') && location_code.include?('hs')

    # RBML
    return off('dic') if location_code == 'dic,anx2'
    return off('oral') if location_code == 'oral'
    return off('rbms') if location_code == 'rbms'
    return off('rbx') if location_code == 'rbx'
    return off('rbx') if location_code == 'rbx,anx2'
    return off('uacl') if location_code == 'uacl,low'
    return off('uacl') if location_code == 'uacl'

    # SESSL Special Collections
    return off('bssc') if barcode.start_with?('BS')

    # Microforms
    return off('mrr') if barcode.start_with?('CR') && material_type == MATERIAL_TYPE_MICROFORMAT
    return off('mrr') if location_code == 'mrr'
    if location_code == 'mus' && barcode.start_with?('CU') && material_type == MATERIAL_TYPE_MICROFORMAT
      return off('mrr')
    end
    return off('mrr') if location_code == 'uts,fic'
    return off('mrr') if location_code == 'uts,fil'
    return off('mrr') if location_code == 'uts,unn' && material_type == MATERIAL_TYPE_MICROFORMAT
    if ['fax', 'ave'].include?(location_code) && barcode.start_with?('CU') && material_type == MATERIAL_TYPE_MICROFORMAT
      return off('mrr')
    end

    # Avery General Collections
    return off('ave') if location_code == 'ave' && barcode.start_with?('AR')
    return off('ave') if location_code == 'ave,anx2'
    return off('ave') if location_code == 'avelc'
    return off('ave') if location_code == 'avelcn'
    return off('fax') if location_code == 'fax' && barcode.start_with?('AR')
    return off('fax') if location_code == 'fax,anx2'
    return off('fax') if location_code == 'faxlc'
    return off('fax') if location_code == 'faxlcn'
    return off('war') if location_code == 'war' && barcode.start_with?('CU')
    return off('war') if location_code == 'war,anx2'

    # SESSL General Collections
    return off('bus') if location_code == 'bus,anx2'
    return off('bus') if location_code == 'bus'
    return off('bus') if location_code == 'busn'
    return off('bus') if location_code == 'bus,stor'
    return off('docs') if location_code == 'docs'
    return off('glg') if location_code == 'glg,anx2'
    return off('jou') if location_code == 'jou'
    return off('leh') if location_code == 'leh'
    return off('leh') if location_code == 'leh,anx2'
    return off('bus') if location_code == 'leh,bdis'
    return off('leh') if location_code == 'leh,ref'
    return off('leh') if location_code == 'leh,slav'
    return off('les') if location_code == 'les,anx2'
    return off('leh') if location_code == 'lsw,ref'
    return off('sci') if location_code == 'sci'
    return off('sci') if location_code == 'sci,anx'
    return off('sci') if location_code == 'sci,anx2'
    return off('sci') if location_code == 'sci,ref'
    return off('swx') if location_code == 'swx'
    return off('swx') if location_code == 'swx,anx2'

    # SESSL Obsolete Locations
    return off('sci') if location_code == 'ariz'
    return off('bio') if location_code == 'bio,anx2'
    return off('bio') if location_code == 'bio'
    return off('bio') if location_code == 'bio,ser'
    return off('bio') if location_code == 'bio,ref'
    return off('che') if location_code == 'che,anx2'
    return off('che') if location_code == 'che,ser'
    return off('che') if location_code == 'che,ref'
    return off('che') if location_code == 'che,anx'
    return off('che') if location_code == 'che'
    return off('eng') if location_code == 'eng,anx2'
    return off('eng') if location_code == 'eng'
    return off('eng') if location_code == 'eng,ref'
    return off('eng') if location_code == 'eng,anx'
    return off('gsc') if location_code == 'gsc,anx2'
    return off('glg') if location_code == 'gsc,ref'
    return off('glg') if location_code == 'gsc'
    return off('glg') if location_code == 'gsc,jour'
    return off('phy') if location_code == 'phy'
    return off('phy') if location_code == 'phy,anx2'
    return off('phy') if location_code == 'phy,ser'
    return off('psy') if location_code == 'pren,psy'
    return off('psy') if location_code.start_with?('psy')

    # Butler General Collections
    return off('glx') if location_code == 'glx,anx'
    return off('glx') if location_code == 'glx,anx2'
    return off('glx') if location_code == 'glx,rare'
    return off('gnc') if location_code == 'gnc'
    return off('glx') if location_code == 'leh,pl'
    return off('glx') if location_code == 'manc'
    return off('glx') if location_code == 'mil' && barcode.start_with?('CU')
    return off('glx') if location_code == 'mil,res' && barcode.start_with?('CU')
    return off('glx') if location_code == 'mil,anx2'
    return off('glx') if location_code == 'sls'
    return off('glx') if location_code == 'pren'
    return off('glx') if location_code == 'pren,fol'

    # Butler Media Collection
    return off('bmc') if location_code == 'bmc'
    return off('bmcr') if location_code == 'bmc,res'
    return off('bmcr') if location_code == 'bmcr'

    # Butler Reference
    return off('ref') if location_code == 'pren,ref'
    return off('ref') if location_code == 'ref'
    return off('ref') if location_code == 'ref,anx2'

    # East Asian General Collections
    return off('eal') if location_code == 'eal'
    return off('eal') if location_code == 'eal,anx'
    return off('eal') if location_code == 'eal,anx2'
    return off('eax') if location_code == 'eax'
    return off('eax') if location_code == 'eax,anx'
    return off('eax') if location_code == 'eax,anx2'
    return off('eax') if location_code == 'eax,tib'
    return off('eax') if location_code == 'eax,sky'
    return off('eax') if location_code == 'leh,tib'
    return off('eal') if location_code == 'pren,eal'
    return off('eax') if location_code == 'pren,eax'

    # Music General Collections
    return off('msr') if location_code == 'msa'
    return off('msc') if location_code == 'msc,anx'
    return off('msc') if location_code == 'msc,anx2'
    return off('msc') if location_code == 'msc,fol'
    return off('msc') if location_code == 'msc,ref'
    return off('msr') if location_code == 'msr,anx2'
    return off('mus') if location_code == 'mus' && barcode.start_with?('MR')
    if location_code == 'mus' && barcode.start_with?('CU') && material_type != MATERIAL_TYPE_MICROFORMAT
      return off('mus')
    end
    return off('mus') if location_code == 'mus,anx'
    return off('mus') if location_code == 'mus,anx2'
    return off('mus') if location_code == 'mus,ref'
    return off('mvr') if location_code == 'mvr'
    return off('msc') if location_code == 'pren,msc'
    return off('msc') if location_code == 'pren,mscr'
    return off('msr') if location_code == 'pren,msr'

    # Burke General Collections
    return off('uts') if location_code == 'uts'
    return off('uts') if location_code == 'uts,per' && barcode.start_with?('CU', 'CR')
    return off('uts') if location_code == 'uts,unnxxf' && barcode.start_with?('CR')
    return off('uts') if location_code == 'uts,unn' && material_type != MATERIAL_TYPE_MICROFORMAT

    # If none of the above rules matched, return nil
    nil
  end

  # Returns the given location code, prefixed with 'off,'
  def self.off(location_code)
    "off,#{location_code}"
  end
end
# rubocop:enable Metrics/ModuleLength, Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
