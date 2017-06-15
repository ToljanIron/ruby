class OverlayEntityGroup < ActiveRecord::Base
  has_many :overlay_entities
  belongs_to :overlay_entity_type

  def self.sorted_of_types(type_ids, cid)
    fetched = ActiveRecord::Base.connection.select_all("select oeg.id, oeg.name, oeg.overlay_entity_type_id, oet.name as overlay_entity_type_name, colors.rgb as color, count(oe.id) as entities
                                                        from overlay_entity_groups as oeg
                                                        left join overlay_entities as oe on oeg.id = oe.overlay_entity_group_id
                                                        left join overlay_entity_types as oet on oet.id = oeg.overlay_entity_type_id
                                                        left join colors on colors.id = oet.color_id
                                                        where oeg.company_id = #{cid} and oeg.overlay_entity_type_id in (#{type_ids.join(',')})
                                                        group by oeg.id, oet.name, colors.rgb, oeg.name, oeg.overlay_entity_type_id
                                                        order by entities desc").to_json
    # return OverlayEntityGroup.where(company_id: cid, overlay_entity_type_id: type_ids).sort { |a, b| b.overlay_entities.length <=> a.overlay_entities.length }
    return JSON.parse(fetched)
  end

  def num_of_connections
    overlay_entities.inject(0) do |a, e|
      a + e.connections.count
    end
  end

  # def as_json(options)
  #   super(options).merge(
  #     color: overlay_entity_type[:color].try(:rgb),
  #     overlay_entity_type_name: overlay_entity_type[:name]
  #   )
  # end
end
