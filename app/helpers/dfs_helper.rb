module DfsHelper
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
      if adj_list_of_node.nil? && ENV['REMOTE'] == 'TRUE'
        if node.is_a? String
          adj_list_of_node = @adj_list[node.to_i]
        else
          if node.is_a? Integer
            adj_list_of_node = @adj_list[node.to_s]
          end
        end
      end
      adj_list_of_node.each do |vertex|
        unless parent.key?(vertex)
          parent[vertex] = node
          dfs_visit!(vertex, @adj_list[vertex])
        end
      end
    rescue => e
      puts e.to_s
    end
  end
end
