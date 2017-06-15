
hours_12 = Reoccurrence::HOUR_MINUTES * 12
ten_min = 10
one_hour = 60

Reoccurrence.create_new_occurrence(hours_12, hours_12, '12_12')
Reoccurrence.create_new_occurrence(Reoccurrence::MONTH_MINUTES, Reoccurrence::MONTH_MINUTES, 'month')
Reoccurrence.create_new_occurrence(Reoccurrence::DAY_MINUTES, Reoccurrence::DAY_MINUTES, 'day')
Reoccurrence.create_new_occurrence(ten_min, ten_min, '10m')
Reoccurrence.create_new_occurrence(ten_min, one_hour, '10m_1h')
Reoccurrence.create_new_occurrence(2, 2, '2_2')
