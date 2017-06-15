module CdsDfsHelper
  class DFS
    attr_accessor :adj_list, :parent
    def initialize(adj_list = {})
      @adj_list = adj_list
      @parent = {}
    end

    def dfs_run!(starting_node)
      @parent[starting_node] = :none
      dfs_visit!(starting_node, @adj_list[starting_node])
    end

    private

    def dfs_visit!(node, adj_list_of_node)
      adj_list_of_node.each do |vertex|
        unless parent.key?(vertex)
          parent[vertex] = node
          dfs_visit!(vertex, @adj_list[vertex])
        end
      end
    end
  end
end
