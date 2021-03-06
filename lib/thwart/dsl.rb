module Thwart
  class DslError < NoMethodError; end
  # Handy internal class for mapping calls in config blocks onto instances and allowing for some
  # syntax flexibility and goodness.
  class Dsl
    attr_accessor :extra_methods, # Hash of the extra method mappings of this DSL => target
                  :method_map,    # Holds the whole method map hash
                  :target,        # What object the DSL maps methods on to
                  :all            # Wheather or not to allow all methods (including dynamic ones like method missing) to be mapped
    
    def initialize(map = {})
      self.extra_methods = map
    end
   
    # Evaluates some code written in the DSL in the context of some target which conforms to the map.
    # @param [Object] a_target The object to which the mapped methods will apply if called in the block
    # @param [Block] block The code written in the DSL to be evaluated.
    def evaluate(a_target, &block)
      self.target = a_target
      self.method_map = target.public_methods.inject({}) do |acc, m| 
        key = m.to_s.gsub(/=$/, "").to_sym
        acc[key] = m if acc[key].nil? || m != key
        acc 
      end.merge(self.extra_methods)
      self.instance_eval(&block)
      self.target
    end
    
    def respond_to?(name, other = false)
      if @all
        return target.respond_to?(name)
      else
        return true if self.method_map.has_key?(name) && !!self.method_map[name]
        super
      end
    end
    
    def method_missing(name, *args, &block)
      if self.respond_to?(name)
        return self.target.send(self.method_map[name], *args, &block) if self.method_map.has_key?(name)
        return self.target.send(name, *args, &block) if @all
      end
      super
    end
  end
  
end
