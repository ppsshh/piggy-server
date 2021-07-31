# KNN stands for k-Nearest Neighbors (kNN)

module Arel
  module Nodes
    class KNN < Binary
      def initialize(left, right)
        super(left, right)
      end
    end
  end

  module Visitors
    class PostgreSQL < ToSql
      private

      def visit_Arel_Nodes_KNN(o, collector)
        collector = infix_value o, collector, ' <-> '
      end
    end
  end
end
