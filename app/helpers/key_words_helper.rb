module KeyWordsHelper
  OVERLAY_ENTITY = 0
  EMPLOYEE = 1
  def create_key_words(sid)
    cid = Snapshot.where(id: sid).first.try(:company_id)
    overlay_entity_type = OverlayEntityType.find_or_create_by(overlay_entity_type: 1, name: 'keywords')
    overlay_entity_type.update(color_id: 2)
    filter_words = FilterKeyword.where(company_id: cid).pluck(:word).map { |word| clear_strings_from_pactuation(word) }
    filter_words = FilterKeyword.where(company_id: -1).pluck(:word).map { |word| clear_strings_from_pactuation(word) } if filter_words.blank?
    # reject stop words (lib/assets/stop_words.txt)
    filter_words += static_stop_words
    o_e_group = OverlayEntityGroup.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: cid, name: 'All keywords')
    emp_ids = Employee.where(company_id: 1).pluck(:id)
    puts "Getting subjects"
    subjects = EmailSubjectSnapshotData.where(employee_from_id: emp_ids, snapshot_id: sid).map { |row| clear_strings_from_pactuation(row.subject.downcase) }
    subjects_merge = ''
    subjects.each { |subj| subjects_merge += subj + ' ' }
    puts "Filtering"
    words = subjects_merge.split(' ') - filter_words
    # reject one letter words
    puts "Reject small keywords"
    words = words.reject { |word| word.length < 2 }
    puts "Remove old snapshot data"
    remove_old_overlay_snapshot_data(sid, overlay_entity_type)
    puts "Going into handle_filtered_subj()"
    words_hash = handle_filtered_subj(words, o_e_group, overlay_entity_type, sid, cid)
    puts "Going into create_overlay_snapshot_data()"
    create_overlay_snapshot_data(emp_ids, sid, words_hash)
  end

  def handle_filtered_subj(subject_array, o_e_group, overlay_entity_type, sid, cid)
    word_values = {}
    subject_array.each do |word|
      word_values[word] = (word_values[word] || 0) + 1
    end
    word_values = word_values.sort_by { |i, val| - val }.take(Configuration.number_of_keywords)
    words_hash = {}
    puts "Have #{word_values.count} to work on"
    ii = 0
    word_values.each do |key, value|
      ii += 1
      puts "In value number: #{ii}" if (ii % 1000 == 0)
      overlay_entity = OverlayEntity.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: cid, overlay_entity_group_id: o_e_group.id, name: key)
      words_hash[overlay_entity.name] = overlay_entity
    end
    words_hash
  end

  def create_overlay_snapshot_data(emp_ids, sid, words_hash)
    ii = 0
    EmailSubjectSnapshotData.where(employee_from_id: emp_ids, snapshot_id: sid).each do |row|
      ii += 1
      puts "In cycle #{ii} of EmailSubjectSnapshotData" if (ii % 1000 == 0)
      subjects = clear_strings_from_pactuation(row.subject.downcase)
      subjects = subjects.split(' ')
      jj = 0
      puts "Number of subjects is: #{subjects.length}" if (ii % 1000 == 0)
      subjects.each do |word|
        jj += 1
        puts "In subject #{jj}" if ((ii % 1000 == 0) && (jj % 1000 == 0))
        overlay_entity = words_hash[word]
        next unless overlay_entity
        a = OverlaySnapshotData.find_by(snapshot_id: sid, from_id: overlay_entity.id, from_type: OVERLAY_ENTITY, to_id: row.employee_to_id, to_type: EMPLOYEE)
        if a.nil?
          OverlaySnapshotData.create(snapshot_id: sid, from_id: overlay_entity.id, from_type: OVERLAY_ENTITY, to_id: row.employee_to_id, to_type: EMPLOYEE, value: 1)
        else
          a.value = a.value + 1
          a.save!
        end
        b = OverlaySnapshotData.find_by(snapshot_id: sid, from_id: row.employee_from_id, from_type: EMPLOYEE, to_id: overlay_entity.id, to_type: OVERLAY_ENTITY)
        if b.nil?
          OverlaySnapshotData.create(snapshot_id: sid, from_id: row.employee_from_id, from_type: EMPLOYEE, to_id: overlay_entity.id, to_type: OVERLAY_ENTITY, value: 1)
        else
          b.value = b.value + 1
          b.save!
        end
      end
    end
  end

  def remove_old_overlay_snapshot_data(sid, overlay_entity_type)
    entity_ids = OverlayEntity.where(overlay_entity_type_id: overlay_entity_type.id).pluck(:id)
    OverlaySnapshotData.where(snapshot_id: sid, from_id: entity_ids, from_type: OVERLAY_ENTITY).delete_all
    OverlaySnapshotData.where(snapshot_id: sid, to_id: entity_ids, to_type: OVERLAY_ENTITY).delete_all
  end

  def static_stop_words
    words = []
    open(Rails.root.join('lib', 'assets', 'stop_words.txt').to_s, 'r') do |f|
      f.each_line do |word|
        words << word.strip
      end
    end
    words
  end

  def clear_strings_from_pactuation(str)
    return str.downcase.gsub(/[-'"\.:+0-9,\\\/?&\(\)]/i, '')
  end
end
