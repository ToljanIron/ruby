require 'spec_helper'

describe RawDataEntriesHelper, :type => :helper do

  describe ', wrap_array_to_str' do
    describe ', with valid input' do
      it ", when str=='[]'' should return empty arr" do
        res = wrap_array_to_str '[]'
        expect(res).to eq('{}')
      end

      it ', should return arr with given emails' do
        valid_str = '["email1@company.com"," email2@company.com"," email3@company.com"]'
        valid_str2 = '[" email1@company.com  "," email2@company.com ", "  email3@company.com"]'
        valid_str3 = '[" email1@company.com  "," email2@company.com ", "  email3@company.com  "]'
        valid_input = [valid_str, valid_str2, valid_str3]
        expected_str = '{email1@company.com,email2@company.com,email3@company.com}'

        valid_input.each do |v|
          res = wrap_array_to_str v
          expected_array = expected_str.gsub('{', '').gsub('}', '').split(',')
          expected_array.each do |e|
            expect(res).to include(e)
          end
        end
      end
    end

    describe ', with incalid input' do
      it ', should reutn empty arr' do
        valid_input = ['', 'some invalidstring']
        valid_input.each do |_v|
          res = wrap_array_to_str ''
          expect(res).to eq('{}')
        end
      end
    end
  end

  describe ', zip_to_csv' do
    it ',with invalid zip should raise exception' do
      res = zip_to_csv 'invalid'
      expect(res).to eq(-1)
    end
  end

  describe ', process_request' do
    it ',with invalid request should raise exception' do
      expect { process_request nil }.to raise_exception
      expect { process_request 'nil' }.to raise_exception
    end

    describe ', with valid request' do
      before do
        Company.create(name: 'some company')
        file = File.open("#{Rails.root}/spec/test-201507141047-1.zip", 'rb')
        contents = Base64.encode64(file.read)
        @req = { 'company' => 'some company', 'file' => contents }
      end

      after do
        DatabaseCleaner.clean_with(:truncation)
      end

      it 'should not raise exception' do
        expect { process_request @req }.not_to raise_exception
      end

      it 'should write to the db' do
        process_request @req
        expect(RawDataEntry.count).to be > 0
        expect( RawDataEntry.last.subject ).not_to be(nil)
      end

      it 'should be able to handl duplicates' do
        process_request @req
        count1 = RawDataEntry.count
        process_request @req
        count2 = RawDataEntry.count
        expect( count1 ).to eq(count2)
      end

      it 'Check all inserted values' do
        process_request @req
        rde = RawDataEntry.first
        expect( rde['company_id'] ).to be(1)
        expect( rde['msg_id'] ).not_to be_nil
        expect( rde['from'] ).to eq('g-emp19@g-company.com')
        expect( rde['date'] ).not_to be_nil
        expect( rde['fwd'] ).to be_truthy
        expect( rde['processed'] ).to be_falsey
        expect( rde['subject'] ).to eq('a subject')

        if is_sql_server_connection?
          expect( rde['to'].class ).to be(String)
          expect( rde['to'].class ).to be(String)
          expect( rde['to'][0] ).to eq('{')
          expect( rde['cc'][0] ).to eq('{')
          expect( rde['bcc'][0]).to eq('{')
        else
          expect( rde['to'].class ).to be(Array)
          expect( rde['to'][0].class ).to be(String)
          expect( rde['to'][0] ).to eq('g-emp37@g-company.com')
          expect( rde['cc'][0] ).to eq('google-employee13@google-company-50-emps.com')
          expect( rde['bcc'][0]).to eq('g-emp14@g-company.com')
        end
      end
    end
  end

end
