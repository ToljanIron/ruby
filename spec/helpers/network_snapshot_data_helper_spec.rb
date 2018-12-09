require 'spec_helper'

SIG_SPORADIC ||= 'sporadic'
SIG_MEANINGFULL ||= 'meaningfull'
SIG_NOT_SIGNIFICANT ||= 'not_significant'

describe NetworkSnapshotDataHelper, type: :helper do

  describe ', running test for weight_algorithm and create a list to view the present in the Graph ' do
    before do
      NetworkName.create!(company_id: 1, name: 'Communication Flow')
      NetworkSnapshotData.create_email_adapter(company_id: 1)
      emp_1, emp_2 = FactoryBot.create_list(:employee, 2)

      @network_nodes_1 = {company_id:1, employee_from_id: emp_1.id, employee_to_id: emp_2.id, snapshot_id: 1}
      (1..18).each do |i|
        @network_nodes_1['n' + i.to_s] = i
      end
      NetworkSnapshotData.create_email_adapter(@network_nodes_1)
      @network_nodes_2 = {company_id: 1,employee_from_id: emp_2.id, employee_to_id: emp_1.id, snapshot_id: 1}
      (1..18).each do |i|
        @network_nodes_2['n' + i.to_s] = i + 2
      end
      NetworkSnapshotData.create_email_adapter(@network_nodes_2)

      @network_nodes_3 = {company_id: 1, employee_from_id: emp_1.id, employee_to_id: emp_1.id, snapshot_id: 1}
      (1..18).each do |i|
        @network_nodes_3['n' + i.to_s] = i + 1
      end
      NetworkSnapshotData.create_email_adapter(@network_nodes_3)
      @snapshot_list = NetworkSnapshotData.all
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    describe ', #check weight_algorithm divide to correct intervals' do
      it ',when list is less then 10 edge the result should be not null' do
        list = [10, 13, 16, 18, 20, 40]
        min = 10
        max = 40
        arr_weight = create_weight_to_netowrk_node(list, min, max)
        expect(arr_weight[0]).to  eq(1)
        expect(arr_weight[5]).to  eq(6)
      end
    end
  end

  describe 'calculate_significant_field_for_all_the_email_snapshot_data()' do
    before do
      @s = FactoryBot.create(:snapshot, timestamp: 6.weeks.ago)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    xit 'Should mark traffic significant because there are few snapshots and traffic is above median' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      email = NetworkSnapshotData.create_email_adapter(snapshot_id: 1, above_median: 1, employee_from_id: 1, employee_to_id: 2, id: 1)
      EmailSnapshotDataHelper::calculate_significant_field_for_all_the_email_snapshot_data(@s, [email])
      significant_level = NetworkSnapshotData.last.significant_level
      expect( significant_level ).to eq( SIG_MEANINGFULL )
    end

    context 'With 4 snpashots' do
      before do
        (2..5).each { |i| FactoryBot.create(:snapshot, timestamp: (6-i).weeks.ago) }
        @s = Snapshot.last
      end

      xit 'Should mark traffic as meaningfull because 60% of traffic is above median' do
        NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
        NetworkSnapshotData.create_email_adapter(snapshot_id: 1, above_median: 1, employee_from_id: 1, employee_to_id: 2)
        NetworkSnapshotData.create_email_adapter(snapshot_id: 2, above_median: 0, employee_from_id: 1, employee_to_id: 2)
        NetworkSnapshotData.create_email_adapter(snapshot_id: 3, above_median: 1, employee_from_id: 1, employee_to_id: 2)
        NetworkSnapshotData.create_email_adapter(snapshot_id: 4, above_median: 1, employee_from_id: 1, employee_to_id: 2)
        NetworkSnapshotData.create_email_adapter(snapshot_id: 5, above_median: 0, employee_from_id: 1, employee_to_id: 2)
        email = NetworkSnapshotData.last

        EmailSnapshotDataHelper::calculate_significant_field_for_all_the_email_snapshot_data(@s, [email])
        significant_level = NetworkSnapshotData.last.significant_level
        expect( significant_level ).to eq( SIG_MEANINGFULL )
      end
    end
  end
  describe 'calc_meaningfull_emails' do
    before do
      @comp = Company.create!(name: 'Comp1')
      @e1 = Employee.create!(external_id: 1, email: 'e1@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
      @e2 = Employee.create!(external_id: 1, email: 'e2@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
      @e3 = Employee.create!(external_id: 1, email: 'e3@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
      @e4 = Employee.create!(external_id: 1, email: 'e4@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')

      @snapshot_a = Snapshot.create!(name: '2015-15', company_id: @comp.id, timestamp: Time.now - 4.month)
      NetworkSnapshotData.create_email_adapter(id: 1, employee_from_id: @e1.id, employee_to_id: @e2.id, n1: 1, n2: 0, snapshot_id: @snapshot_a.id)
      NetworkSnapshotData.create_email_adapter(id: 2, employee_from_id: @e2.id, employee_to_id: @e3.id, n1: 1, n2: 1, snapshot_id: @snapshot_a.id)
      NetworkSnapshotData.create_email_adapter(id: 3, employee_from_id: @e3.id, employee_to_id: @e1.id, n1: 1, n2: 2, snapshot_id: @snapshot_a.id)

      @snapshot_b = Snapshot.create!(name: '2015-16', company_id: @comp.id, timestamp: Time.now - 3.month)
      NetworkSnapshotData.create_email_adapter(id: 4, employee_from_id: @e1.id, employee_to_id: @e2.id, n1: 1, n2: 0, snapshot_id: @snapshot_b.id)
      NetworkSnapshotData.create_email_adapter(id: 5, employee_from_id: @e2.id, employee_to_id: @e3.id, n1: 2, n2: 2, snapshot_id: @snapshot_b.id)
      NetworkSnapshotData.create_email_adapter(id: 6, employee_from_id: @e3.id, employee_to_id: @e1.id, n1: 1, n2: 2, snapshot_id: @snapshot_b.id)
      NetworkSnapshotData.create_email_adapter(id: 17, employee_from_id: @e4.id, employee_to_id: @e1.id, n1: 1, n2: 0, snapshot_id: @snapshot_b.id)

      @snapshot_c = Snapshot.create!(name: '2015-17', company_id: @comp.id, timestamp: Time.now - 2.month)
      NetworkSnapshotData.create_email_adapter(id: 7, employee_from_id: @e1.id, employee_to_id: @e2.id, n1: 1, n2: 0, snapshot_id: @snapshot_c.id)
      NetworkSnapshotData.create_email_adapter(id: 8, employee_from_id: @e2.id, employee_to_id: @e3.id, n1: 2, n2: 2, snapshot_id: @snapshot_c.id)
      NetworkSnapshotData.create_email_adapter(id: 9, employee_from_id: @e3.id, employee_to_id: @e1.id, n1: 1, n2: 2, snapshot_id: @snapshot_c.id)

      @snapshot_d = Snapshot.create!(name: '2015-18', company_id: @comp.id, timestamp: Time.now - 1.month)
      NetworkSnapshotData.create_email_adapter(id: 10, employee_from_id: @e1.id, employee_to_id: @e2.id, n1: 4, n2: 4, snapshot_id: @snapshot_d.id)
      NetworkSnapshotData.create_email_adapter(id: 11, employee_from_id: @e2.id, employee_to_id: @e3.id, n1: 2, n2: 2, snapshot_id: @snapshot_d.id)
      NetworkSnapshotData.create_email_adapter(id: 12, employee_from_id: @e3.id, employee_to_id: @e1.id, n1: 1, n2: 2, snapshot_id: @snapshot_d.id)

      @snapshot_e = Snapshot.create!(name: '2015-19', company_id: @comp.id, timestamp: Time.now)
      NetworkSnapshotData.create_email_adapter(id: 13, employee_from_id: @e1.id, employee_to_id: @e2.id, n1: 1, n2: 0, snapshot_id: @snapshot_e.id)
      NetworkSnapshotData.create_email_adapter(id: 14, employee_from_id: @e2.id, employee_to_id: @e3.id, n1: 2, n2: 2, snapshot_id: @snapshot_e.id)
      NetworkSnapshotData.create_email_adapter(id: 15, employee_from_id: @e3.id, employee_to_id: @e1.id, n1: 1, n2: 2, snapshot_id: @snapshot_e.id)
      NetworkSnapshotData.create_email_adapter(id: 16, employee_from_id: @e4.id, employee_to_id: @e1.id, n1: 3, n2: 0, snapshot_id: @snapshot_e.id)
      EmailSnapshotDataHelper.calc_meaningfull_emails
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    xit 'should calculate for all the emails which are above median and below the median' do
      expect(NetworkSnapshotData.find(1).above_median).to eq 'below'
      expect(NetworkSnapshotData.find(2).above_median).to eq 'above'
      expect(NetworkSnapshotData.find(3).above_median).to eq 'above'
    end

    xit 'should take into consideration old snapshots' do
      expect(NetworkSnapshotData.find(13).significant_level).to eq 'not_significant'
      expect(NetworkSnapshotData.find(14).significant_level).to eq 'meaningfull'
      expect(NetworkSnapshotData.find(15).significant_level).to eq 'meaningfull'
      expect(NetworkSnapshotData.find(16).significant_level).to eq 'sporadic'
    end
  end

  describe 'get_interfaces_map' do
    cid = 1
    sid = 1
    res = nil
    links_hash = {}

    before :all do

      Company.create!(id: cid, name: "Hevra10")
      Snapshot.create!(id: sid, name: "2016-01", company_id: cid, month: 'Jul/17', timestamp: '2017-07-11')
      NetworkName.create!(id: 1, name: "Communication Flow", company_id: cid).id
      Color.create!(id: 1, rgb: 'red')
      Color.create!(id: 2, rgb: 'green')
      Color.create!(id: 3, rgb: 'blue')

      Group.create!(id: 0, name: "root", company_id: cid, snapshot_id: sid, external_id: "root", nsleft: 1, nsright: 14)
      Group.create!(id: 9, name: "subroot", company_id: cid, parent_group_id: 0,  snapshot_id: sid,             external_id: "subroot", nsleft: 2,  nsright: 7)
      Group.create!(id: 1, name: "sister1", company_id: cid, parent_group_id: 9, color_id: 1, snapshot_id: sid, external_id: "sister1", nsleft: 3,  nsright: 4)
      Group.create!(id: 2, name: "sister2", company_id: cid, parent_group_id: 9, color_id: 2, snapshot_id: sid, external_id: "sister2", nsleft: 5,  nsright: 6)
      Group.create!(id: 3, name: "loner1",  company_id: cid, parent_group_id: 0, color_id: 3, snapshot_id: sid, external_id: "loner1",  nsleft: 8,  nsright: 9)
      Group.create!(id: 4, name: "loner2",  company_id: cid, parent_group_id: 0, color_id: 1, snapshot_id: sid, external_id: "loner2",  nsleft: 10, nsright: 11)
      Group.create!(id: 5, name: "loner3",  company_id: cid, parent_group_id: 0, color_id: 3, snapshot_id: sid, external_id: "loner3",  nsleft: 12, nsright: 13)

      all = [
      ## groups:
      ##   1 1 2 2 3 3 4 4 5 5
          [0,9,1,1,1,2,1,0,2,2], # 1
          [4,0,0,1,0,0,0,1,9,0], # 1
          [2,2,0,0,1,0,0,0,0,0], # 2
          [1,1,0,0,0,0,0,0,0,0], # 2
          [2,0,1,1,0,8,1,1,0,0], # 3
          [1,0,0,1,0,0,1,1,8,0], # 3
          [1,0,0,0,1,0,0,5,8,0], # 4
          [0,2,0,0,1,1,5,0,0,0], # 4
          [1,0,1,0,2,0,0,2,0,2], # 5
          [0,2,0,2,0,0,0,2,4,0]] # 5
      create_emps('moshe', 'acme.com', 10, {snapshot_id: sid})
      Employee.all.each { |e| e.update!(group_id: (5 * e.id / 10.0).ceil) }
      fg_emails_from_matrix(all)

    end

    after :all do
      DatabaseCleaner.clean_with(:truncation)
    end

    describe 'syntax checking for interfaces_traffic_volumes_query' do
      inside = 1
      outside = 2
      nid = 1
      extids = ['subroot', 'loner1', 'loner2', 'loner3', 'root']

      it 'out in' do
        ret = NetworkSnapshotDataHelper.interfaces_traffic_volumes_query(outside, inside, 'month', 'Jul/17', cid, nid, 2, 7, extids)
        expect(ret.length).to eq(3)
        expect(ret[0]['fromextid']).not_to be_nil
        expect(ret[0]['toextid']).to be_nil
      end

      it 'in in' do
        ret = NetworkSnapshotDataHelper.interfaces_traffic_volumes_query(inside, inside, 'month', 'Jul/17', cid, nid, 2, 7, extids)
        expect(ret.length).to eq(1)
        expect(ret[0]['fromextid']).to be_nil
        expect(ret[0]['toextid']).to be_nil
      end

      it 'out out' do
        ret = NetworkSnapshotDataHelper.interfaces_traffic_volumes_query(outside, outside, 'month', 'Jul/17', cid, nid, 2, 7, extids)
        expect(ret.length).to eq(9)
        expect(ret[0]['fromextid']).not_to be_nil
        expect(ret[0]['toextid']).not_to be_nil
      end

      it 'in out' do
        ret = NetworkSnapshotDataHelper.interfaces_traffic_volumes_query(inside, outside, 'month', 'Jul/17', cid, nid, 2, 7, extids)
        expect(ret.length).to eq(3)
        expect(ret[0]['fromextid']).to be_nil
        expect(ret[0]['toextid']).not_to be_nil
      end
    end

    describe 'get_interfaces_map_from_helper' do
      before :all do
        gids = [0,4,5,9]
        res = NetworkSnapshotDataHelper.get_interfaces_map_from_helper(1, "Jul/17", 9, gids)
        res[:links].each do |l|
          links_hash[[l[:source], l[:target]]] = l[:volume]
        end
      end

      it 'should have internal traffic of 20' do
        expect( links_hash[[9,9]] ).to eq(22)
      end

      it 'links should have traffic of less than 20' do
        res[:links].each do |l|
          expect(l[:volume]).to be >= 0
          expect(l[:volume]).to be <= 22
        end
      end

      it 'Group hierarchy 9 has more traffic towards 5 then 4' do
        expect( links_hash[[9,5]] ).to  be > links_hash[[9,4]]
      end

      it 'there should be no link for groups without traffic' do
        expect( links_hash[[0,4]] ).to be_nil
        expect( links_hash[[4,0]] ).to be_nil
      end

      it 'should have correct traffic to unincluded groups' do
        expect( links_hash[[9,-1]] ).to eq(4)
        expect( links_hash[[-1,9]] ).to eq(6)
      end

      it 'should be well formatted' do
        expect( res[:nodes]).not_to be_nil
        expect( res[:nodes][0][:col] ).to eq 'red'
        expect( res[:selected_group] ).to eq 9
      end
    end
  end
end
