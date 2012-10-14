require 'test_helper'

class ProductTest < ActiveSupport::TestCase
	fixtures :products
	#The fixtures directive loads the fixture data corresponding to the given model
	#name into the corresponding database table before each test method in the
	#test case is run. The name of the fixture file determines the table that is loaded,
	#so using :products will cause the products.yml fixture file to be used.
	#
	#fixtures directive means that the products table will be emptied out and then
	#populated with the rows defined in the fixture before each test method
	#is run.
	#
	#default for tests is to load all fixtures before running the test
	#
	#For each fixture it loads into a
	#test, Rails defines a method with the same name as the fixture. You can use
	#this method to access preloaded model objects containing the fixture data:
	#simply pass it the name of the row as defined in the YAML fixture file, and it’ll
	#return a model object containing that row’s data
	#
	#products(:ruby) will return the row object
	#to run unit test: rake test:units

	test "product is not valid without a unique title" do

		product = Product.new(:title => products(:ruby).title,
				      :description => "yyy" ,
				      :price => 1,
				      :image_url => "fred.gif" )
		assert !product.save
		assert_equal "has already been taken" , product.errors[:title].join('; ' )
	end
  
end
