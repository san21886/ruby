class Product < ActiveRecord::Base
  attr_accessible :description, :image_url, :price, :title
  validates :description, :image_url, :title, :presence => true #description, title, image to be non empty string
  validates :title, :uniqueness => true #title to be uniq
  validates :price, :numericality => {:greater_than_or_equal_to => 0.01} #price to be numeric value greater than 0
  #format option, matches a field against a regular expression
  validates :image_url, :format => {
	  :with => %r{\.(gif|jpg|png)$}i,
	  :message => 'must be a URL for GIF, JPG or PNG image.'}
end
