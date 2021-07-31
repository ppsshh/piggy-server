class Price < ActiveRecord::Base
  belongs_to :currency

  # record_type = 0 # default (кажется, в дальнейшем они удаляются)
  # record_type = 1 # permanent record (eg.: start of the month)
  # record_type = 2 # это последний (самый актуальный) курс

  # actual_date - это дата, на которую действителен курс
  # date - у [record_type == 1] это 1 число месяца (actual date при этом обычно либо 1, либо 2 число)
  #        у [record_type == 0] может быть nil, а может равняться actual_date

  scope :knn, ->(date) do
    order(
      Arel::Nodes::KNN.new(
        Price.arel_table[:actual_date],
        Arel::Nodes.build_quoted(date)
      )
    ).take
  end
end
