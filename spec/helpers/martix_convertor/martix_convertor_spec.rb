require 'spec_helper'
require './app/helpers/martix_convertor/martix_convertor.rb'
describe MatrixConvertor, type: :helper do
  target = 'tmp/matrix_target.csv'
  small_csv = './spec/helpers/martix_convertor/small_matrix.csv'
  big_csv = './spec/helpers/martix_convertor/big_matrix.csv'
  after do
    FileUtils.rm_rf target
  end

  describe 'extract_external_ids' do
    it 'should return array of extract_external_ids' do
      expect(MatrixConvertor.extract_external_ids(small_csv).count).to be 6
      expect(MatrixConvertor.extract_external_ids(big_csv).count).to be 290
    end
    it 'should map int to row/column of the id' do
      res = MatrixConvertor.extract_external_ids(small_csv)
      expect(res[0]).to eq nil
      expect(res[2]).to eq '#2'
    end
  end

  describe 'process_src_file' do
    describe 'when input is invalid' do
      it 'shuold raise error' do
        expect { MatrixConvertor.process_src_file('') }.to raise_error
      end
    end

    describe 'when input is valid' do
      it 'should return an array of [id, id]' do
        res = MatrixConvertor.process_src_file(small_csv)
        line = res[0]
        expect(line[0]).to eq '#1'
        expect(line[1]).to eq '#5'
        line = res[1]
        expect(line[0]).to eq '#2'
        expect(line[1]).to eq '#2'
        line = res[3]
        expect(line[0]).to eq '#3'
        expect(line[1]).to eq '#4'
        line = res[4]
        expect(line[0]).to eq '#5'
        expect(line[1]).to eq '#4'
      end
    end
  end

  describe 'convert' do
    it 'should create csv with line [id, id, 1] for matcing matrix ids' do
      MatrixConvertor.convert(small_csv, target, 'trust')
      res = CSV.read(target)
      expect(res[0]).to eq %w(employee_exteranl_id  trusted_external_id relation_type Snapshot)
      expect(res[1]).to eq ['#1', '#5', '1', 'Monthly-2015-09-1']
      expect(res[2]).to eq ['#2', '#2', '1', 'Monthly-2015-09-1']
      expect(res[3]).to eq ['#3', '#2', '1', 'Monthly-2015-09-1']
      expect(res[4]).to eq ['#3', '#4', '1', 'Monthly-2015-09-1']
      expect(res[5]).to eq ['#5', '#4', '1', 'Monthly-2015-09-1']
    end
    it 'should create csv with line [id, id, 1] for matcing matrix ids' do
      MatrixConvertor.convert(big_csv, target, 'trust')
      res = CSV.read(target)
      expect(res[0]).to eq %w(employee_exteranl_id  trusted_external_id relation_type Snapshot)
      expect(res[1]).to eq ['#1', '#67', '1', 'Monthly-2015-09-1']
      expect(res[2]).to eq ['#2', '#180', '1', 'Monthly-2015-09-1']
      expect(res[10]).to eq ['#9', '#111', '1', 'Monthly-2015-09-1']
      expect(res[43]).to eq ['#37', '#149', '1', 'Monthly-2015-09-1']
    end
  end
end
