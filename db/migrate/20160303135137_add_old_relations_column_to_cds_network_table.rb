class AddOldRelationsColumnToCdsNetworkTable < ActiveRecord::Migration[4.2]
  def change
    add_column :network_names, :optional_relation, :integer
    update_current_networks
  end

  def update_current_networks
    NetworkName.all.map do |network|
      if network.name == 'Friendship'
        network.update(optional_relation: 1)
      elsif network.name == 'Advice'
        network.update(optional_relation: 2)
      elsif network.name == 'Trust'
        network.update(optional_relation: 3)
      end
    end
  end
end
