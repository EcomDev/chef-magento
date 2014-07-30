require 'chefspec'
require 'chefspec/berkshelf'
require 'ecomdev/chefspec'

module SpecHelper
  def test_params(&block)
    chef_run_proxy.before(:converge, false) do |runner|
      if block.arity == 1
        block.call(runner.node.set[:test])
      else
        block.call(runner.node.set[:test], runner.node)
      end
    end
  end
end


RSpec.configure do |c|
  c.include SpecHelper
end



ChefSpec::Coverage.start!