module ConvertHelper

  def self.convert_new_network_snapshot_data
    convert_trust_snapshot_data
    convert_advice_snapshot_data
    convert_friendship_snapshot_data
  end

  def self.convert_trust_snapshot_data
    ActiveRecord::Base.transaction do
      begin
        TrustsSnapshot.all.each do |row|
          if row.snapshot
            network_id = get_network_company_if_exist('Trust', row.snapshot.company_id)
            if network_id == -1
              network_names = NetworkName.create!(name: 'Trust', company_id: row.snapshot.company_id)
              network_id = network_names.id
            end
            if row.trust_flag.nil?
              value = 0
            else
              value = row.trust_flag
            end
            NetworkSnapshotData.create!(snapshot_id: row.snapshot_id, network_id: network_id, company_id: row.snapshot.company_id, from_employee_id: row.employee_id, to_employee_id: row.trusted_id, value: value)
          end
        end
      rescue
        ap '*' * 100
        ap 'Error creating trust network snapshot data'
        raise ActiveRecord::Rollback
      end
    end
  end

  def self.convert_advice_snapshot_data
    ActiveRecord::Base.transaction do
      begin
        AdvicesSnapshot.all.each do |row|
          if row.snapshot
            network_id = get_network_company_if_exist('Advice', row.snapshot.company_id)
            if network_id == -1
              network_names = NetworkName.create!(name: 'Advice', company_id: row.snapshot.company_id)
              network_id = network_names.id
            end
            if row.advice_flag.nil?
              value = 0
            else
              value = row.advice_flag
            end
            NetworkSnapshotData.create!(snapshot_id: row.snapshot_id, network_id: network_id, company_id: row.snapshot.company_id, from_employee_id: row.employee_id, to_employee_id: row.advicee_id, value: value)
          end
        end
      rescue
        ap '*' * 100
        ap 'Error creating advice network snapshot data'
        raise ActiveRecord::Rollback
      end
    end
  end

  def self.convert_friendship_snapshot_data
    ActiveRecord::Base.transaction do
      begin
        FriendshipsSnapshot.all.each do |row|
          if row.snapshot
            network_id = get_network_company_if_exist('Friendship', row.snapshot.company_id)
            if network_id == -1
              network_names = NetworkName.create!(name: 'Friendship', company_id: row.snapshot.company_id)
              network_id = network_names.id
            end
            if row.friend_flag.nil?
              value = 0
            else
              value = row.friend_flag
            end
            NetworkSnapshotData.create!(snapshot_id: row.snapshot_id, network_id: network_id, company_id: row.snapshot.company_id, from_employee_id: row.employee_id, to_employee_id: row.friend_id, value: value)
          end
        end
      rescue
        ap '*' * 100
        ap 'Error creating advice network snapshot data'
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def self.get_network_company_if_exist(network, company_id)
    row = nil
    row = NetworkName.find_by(name: network, company_id: company_id)
    if row
      return row.id
    end
    return -1
  end
end
