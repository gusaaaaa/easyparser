# TODO move to spec_helper
require 'minitest/autorun'
require 'easyparser'

describe EasyParser do
  describe "on Allrecipes.com" do
    it "parses grandma's lemon meringue pie recipe" do
      memo = []
      easy_parser = EasyParser.new File.read(File.expand_path("../test_allrecipes_com/allrecipes_com.easyparser.html", __FILE__)) do |on|
        on.ingredients do |scope|
          memo << "# #{scope['ingredients']}:"
        end
        on.ingredient do |scope|
          memo << "- #{scope['amount']} of #{scope['ingredient']}"
        end
      end
      easy_parser.run File.read(File.expand_path("../test_allrecipes_com/grandmas-lemon-meringue-pie-2014-04-04.html", __FILE__))
      expected = <<-TXT
        # Ingredients :
        - 1 cup of white sugar
        - 2 tablespoons of all-purpose flour
        - 3 tablespoons of cornstarch
        - 1/4 teaspoon of salt
        - 1 1/2 cups of water
        - 2 of lemons, juiced and zested
        - 2 tablespoons of butter
        - 4 of egg yolks, beaten
        - 1 (9 inch) of pie crust, baked
        - 4 of egg whites
        - 6 tablespoons of white sugar
      TXT
      # TODO test helper that takes care of joining, stripping, etc.
      assert_equal memo.join("\n"), expected.strip.gsub(/^\s+/, '')
    end
  end
end
