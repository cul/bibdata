require 'rails_helper'

RSpec.describe Bibdata::OffsiteLocationFlipper do
  describe ".location_code_to_recap_flipped_location_code" do

    context "locations that start with 'off,'" do
      {
        'off,abc' => 'off,abc',
        'off,def' => 'off,def',
        'off,ghi' => 'off,ghi',
      }.each do |original_location_code, expected_flipped_location_code|
        barcode = 'XYZplaceholder'
        material_type = 'Book'
        it "returns the code without modification" do
          expect(
            described_class.location_code_to_recap_flipped_location_code(original_location_code, barcode, material_type)
          ).to eq(
            expected_flipped_location_code
          )
        end
      end
    end

    context "locations that end with '4off'" do
      {
        'abc4off' => 'off,abc',
        'def4off' => 'off,def',
        'ghi4off' => 'off,ghi',
      }.each do |original_location_code, expected_flipped_location_code|
        barcode = 'XYZplaceholder'
        material_type = 'Book'
        it "flips #{original_location_code} to #{expected_flipped_location_code}" do
          expect(
            described_class.location_code_to_recap_flipped_location_code(original_location_code, barcode, material_type)
          ).to eq(
            expected_flipped_location_code
          )
        end
      end
    end

    context "specific location flipping rules" do
      [
        # Variants that should be reviewed in the future, but we will keep them in place for now
        [{ location_code: 'avda', barcode: 'AD...' }, 'off,avda'],
        [{ location_code: 'glx', barcode: 'CU...' }, 'off,glx'],
        [{ location_code: 'glx', barcode: 'CR...' }, 'off,glx'],
        [{ location_code: 'glx', barcode: 'RS...' }, 'off,rbx'],
        [{ location_code: 'msc', barcode: 'MR...' }, 'off,msc'],
        [{ location_code: 'msr', barcode: 'MR...' }, 'off,msr'],
        [{ location_code: 'prd', barcode: 'CM...' }, 'off,prd'],
        [{ location_code: 'mat', barcode: 'CU...' }, 'off,mat'],
        [{ location_code: 'mat', barcode: 'CR...' }, 'off,mat'],
        # Avery Special Collections
        [{ location_code: 'avda,anx2' }, 'off,avda'],
        [{ location_code: 'avr' }, 'off,avr'],
        [{ location_code: 'far' }, 'off,far'],
        [{ location_code: 'vmc' }, 'off,vmc'],
        # Burke Special Collections
        [{ location_code: 'uts,arc' }, 'off,uta'],
        [{ location_code: 'uts,mrld' }, 'off,utmrl'],
        [{ location_code: 'uts,mrldxf' }, 'off,utmrl'],
        [{ location_code: 'uts,mrlo' }, 'off,utmrl'],
        [{ location_code: 'uts,mrloxf' }, 'off,utmrl'],
        [{ location_code: 'uts,unnr' }, 'off,unr'],
        [{ location_code: 'uts,unnxxp' }, 'off,utp'],
        # East Asian Special Collections
        [{ location_code: 'ean' }, 'off,ean'],
        [{ location_code: 'ear' }, 'off,ear'],
        [{ location_code: 'eaa' }, 'off,eaa'],
        # Health Sciences
        [{ location_code: '...hs...', barcode: 'HS...' }, 'off,hsl'],
        [{ location_code: '...hs...', barcode: 'HR...' }, 'off,hsl'],
        [{ location_code: '...hs...', barcode: 'HX...' }, 'off,hssc'],
        # RBML
        [{ location_code: 'dic,anx2' }, 'off,dic'],
        [{ location_code: 'oral' }, 'off,oral'],
        [{ location_code: 'rbms' }, 'off,rbms'],
        [{ location_code: 'rbx' }, 'off,rbx'],
        [{ location_code: 'rbx,anx2' }, 'off,rbx'],
        [{ location_code: 'uacl,low' }, 'off,uacl'],
        [{ location_code: 'uacl' }, 'off,uacl'],
        # SESSL Special Collections
        [{ barcode: 'BS...' }, 'off,bssc'],
        # Microforms
        [{ barcode: 'CR...', material_type: described_class::MATERIAL_TYPE_MICROFORMAT }, 'off,mrr'],
        [{ location_code: 'mrr' }, 'off,mrr'],
        [{ location_code: 'mus', barcode: 'CU...', material_type: described_class::MATERIAL_TYPE_MICROFORMAT }, 'off,mrr'],
        [{ location_code: 'uts,fic' }, 'off,mrr'],
        [{ location_code: 'uts,fil' }, 'off,mrr'],
        [{ location_code: 'uts,unn', material_type: described_class::MATERIAL_TYPE_MICROFORMAT }, 'off,mrr'],
        [{ location_code: 'fax', barcode: 'CU...', material_type: described_class::MATERIAL_TYPE_MICROFORMAT }, 'off,mrr'],
        [{ location_code: 'ave', barcode: 'CU...', material_type: described_class::MATERIAL_TYPE_MICROFORMAT }, 'off,mrr'],
        # Avery General Collections
        [{ location_code: 'ave', barcode: 'AR...' }, 'off,ave'],
        [{ location_code: 'ave,anx2' }, 'off,ave'],
        [{ location_code: 'avelc' }, 'off,avec'],
        [{ location_code: 'avelcn' }, 'off,ave'],
        [{ location_code: 'fax', barcode: 'AR...' }, 'off,fax'],
        [{ location_code: 'fax,anx2' }, 'off,fax'],
        [{ location_code: 'faxlc' }, 'off,faxc'],
        [{ location_code: 'faxlcn' }, 'off,fax'],
        [{ location_code: 'ave', barcode: 'CU...' }, 'off,avec'],
        [{ location_code: 'avelc', barcode: 'CU...' }, 'off,avec'],
        [{ location_code: 'fax', barcode: 'CU...' }, 'off,faxc'],
        [{ location_code: 'faxlc', barcode: 'CU...' }, 'off,faxc'],
        [{ location_code: 'war', barcode: 'CU...' }, 'off,war'],
        [{ location_code: 'war,anx2' }, 'off,war'],
        # SESSL General Collections
        [{ location_code: 'bus,anx2' }, 'off,bus'],
        [{ location_code: 'bus' }, 'off,bus'],
        [{ location_code: 'busn' }, 'off,bus'],
        [{ location_code: 'bus,stor' }, 'off,bus'],
        [{ location_code: 'docs' }, 'off,docs'],
        [{ location_code: 'glg,anx2' }, 'off,glg'],
        [{ location_code: 'glg' }, 'off,glg'],
        [{ location_code: 'jou' }, 'off,jou'],
        [{ location_code: 'leh' }, 'off,leh'],
        [{ location_code: 'leh,anx2' }, 'off,leh'],
        [{ location_code: 'leh,bdis' }, 'off,bus'],
        [{ location_code: 'leh,ref' }, 'off,leh'],
        [{ location_code: 'leh,slav' }, 'off,leh'],
        [{ location_code: 'les,anx2' }, 'off,les'],
        [{ location_code: 'lsw,ref' }, 'off,leh'],
        [{ location_code: 'sci' }, 'off,sci'],
        [{ location_code: 'sci,anx' }, 'off,sci'],
        [{ location_code: 'sci,anx2' }, 'off,sci'],
        [{ location_code: 'sci,ref' }, 'off,sci'],
        [{ location_code: 'swx' }, 'off,swx'],
        [{ location_code: 'swx,anx2' }, 'off,swx'],
        # SESSL Obsolete Locations
        [{ location_code: 'ariz' }, 'off,sci'],
        [{ location_code: 'bio,anx2' }, 'off,bio'],
        [{ location_code: 'bio' }, 'off,bio'],
        [{ location_code: 'bio,ser' }, 'off,bio'],
        [{ location_code: 'bio,ref' }, 'off,bio'],
        [{ location_code: 'che,anx2' }, 'off,che'],
        [{ location_code: 'che,ser' }, 'off,che'],
        [{ location_code: 'che,ref' }, 'off,che'],
        [{ location_code: 'che,anx' }, 'off,che'],
        [{ location_code: 'che' }, 'off,che'],
        [{ location_code: 'eng,anx2' }, 'off,eng'],
        [{ location_code: 'eng' }, 'off,eng'],
        [{ location_code: 'eng,ref' }, 'off,eng'],
        [{ location_code: 'eng,anx' }, 'off,eng'],
        [{ location_code: 'gsc,anx2' }, 'off,gsc'],
        [{ location_code: 'gsc,ref' }, 'off,glg'],
        [{ location_code: 'gsc' }, 'off,glg'],
        [{ location_code: 'gsc,jour' }, 'off,glg'],
        [{ location_code: 'phy' }, 'off,phy'],
        [{ location_code: 'phy,anx2' }, 'off,phy'],
        [{ location_code: 'phy,ser' }, 'off,phy'],
        [{ location_code: 'pren,psy' }, 'off,psy'],
        [{ location_code: 'psy...' }, 'off,psy'],
        # Butler General Collections
        [{ location_code: 'glx,anx' }, 'off,glx'],
        [{ location_code: 'glx,anx2' }, 'off,glx'],
        [{ location_code: 'glx,rare' }, 'off,glx'],
        [{ location_code: 'gnc' }, 'off,gnc'],
        [{ location_code: 'leh,pl' }, 'off,glx'],
        [{ location_code: 'manc' }, 'off,glx'],
        [{ location_code: 'mil', barcode: 'CU...' }, 'off,glx'],
        [{ location_code: 'mil,res', barcode: 'CU...' }, 'off,glx'],
        [{ location_code: 'mil,anx2' }, 'off,glx'],
        [{ location_code: 'sls' }, 'off,glx'],
        [{ location_code: 'pren' }, 'off,glx'],
        [{ location_code: 'pren,fol' }, 'off,glx'],
        # Butler Media Collection
        [{ location_code: 'bmc' }, 'off,bmc'],
        [{ location_code: 'bmc,res' }, 'off,bmcr'],
        [{ location_code: 'bmcr' }, 'off,bmcr'],
        # Butler Reference
        [{ location_code: 'pren,ref' }, 'off,ref'],
        [{ location_code: 'ref' }, 'off,ref'],
        [{ location_code: 'ref,anx2' }, 'off,ref'],
        # East Asian General Collections
        [{location_code: 'eal' }, 'off,eal'],
        [{location_code: 'eal,anx' }, 'off,eal'],
        [{location_code: 'eal,anx2' }, 'off,eal'],
        [{location_code: 'eax' }, 'off,eax'],
        [{location_code: 'eax,anx' }, 'off,eax'],
        [{location_code: 'eax,anx2' }, 'off,eax'],
        [{location_code: 'eax,tib' }, 'off,eax'],
        [{location_code: 'eax,sky' }, 'off,eax'],
        [{location_code: 'eax,ref' }, 'off,eax'],
        [{location_code: 'leh,tib' }, 'off,eax'],
        [{location_code: 'pren,eal' }, 'off,eal'],
        [{location_code: 'pren,eax' }, 'off,eax'],

        # Music General Collections
        [{ location_code: 'msa' }, 'off,msr'],
        [{ location_code: 'msc,anx' }, 'off,msc'],
        [{ location_code: 'msc,anx2' }, 'off,msc'],
        [{ location_code: 'msc,fol' }, 'off,msc'],
        [{ location_code: 'msc,ref' }, 'off,msc'],
        [{ location_code: 'msr,anx2' }, 'off,msr'],
        [{ location_code: 'mus', barcode: 'MR...' }, 'off,mus'],
        [{ location_code: 'mus', barcode: 'CU...', material_type: "NOT-#{described_class::MATERIAL_TYPE_MICROFORMAT}" }, 'off,mus'],
        [{ location_code: 'mus,anx' }, 'off,mus'],
        [{ location_code: 'mus,anx2' }, 'off,mus'],
        [{ location_code: 'mus,ref' }, 'off,mus'],
        [{ location_code: 'mvr' }, 'off,mvr'],
        [{ location_code: 'pren,msc' }, 'off,msc'],
        [{ location_code: 'pren,mscr' }, 'off,msc'],
        [{ location_code: 'pren,msr' }, 'off,msr'],
        # Burke General Collections
        [{ location_code: 'uts' }, 'off,uts'],
        [{ location_code: 'uts,per', barcode: 'CU...' }, 'off,uts'],
        [{ location_code: 'uts,per', barcode: 'CR...' }, 'off,uts'],
        [{ location_code: 'uts,unnxxf', barcode: 'CR...' }, 'off,uts'],
        [{ location_code: 'uts,unn', material_type: "NOT-#{described_class::MATERIAL_TYPE_MICROFORMAT}" }, 'off,uts'],
      ].each do |inputs, expected_flipped_location_code|
        it "inputs: #{inputs.inspect}, expected_flipped_location_code: #{expected_flipped_location_code}" do
          location_code = inputs.fetch(:location_code, '_location_code_does_not_matter_for_this_test_')
          barcode = inputs.fetch(:barcode, '_barcode_does_not_matter_for_this_test_')
          material_type = inputs.fetch(:material_type, '_material_type_does_not_matter_for_this_test_')
          expect(
            described_class.location_code_to_recap_flipped_location_code(location_code, barcode, material_type)
          ).to eq(
            expected_flipped_location_code
          )
        end
      end
    end
  end
end

