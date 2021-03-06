require File.dirname(__FILE__) + '/test_helper'
require 'attribute_normalizer'

describe AttributeNormalizer do
  
  it 'should add the class method Class#normalize_attributes when included' do
  
    klass = Class.new do
      include AttributeNormalizer
    end
  
    klass.respond_to?(:normalize_attributes).should be_true
  end
  
end

describe '#normalize_attributes without a block' do
  
  before do  

    class Klass
      attr_accessor :attribute
      include AttributeNormalizer
      normalize_attributes :attribute
    end
    
  end

  {
    ' spaces in front and back ' => 'spaces in front and back', 
    "\twe hate tabs!\t"          => 'we hate tabs!'
  }.each do |key, value|
    it "should normalize '#{key}' to '#{value}'" do
      Klass.send(:normalize_attribute, key).should == value
    end
  end
  
end

describe '#normalize_attributes with a block' do
  
  before do  

    class Klass
      attr_accessor :attribute
      include AttributeNormalizer
      normalize_attributes :attribute do |value|
        value = value.strip.upcase if value.is_a?(String)
        value = value * 2          if value.is_a?(Fixnum)
        value = value * 0.5        if value.is_a?(Float)
        value
      end
    end
    
  end

  {
    "\tMichael Deering" => 'MICHAEL DEERING', 
    2                   => 4,
    2.0                 => 1.0
  }.each do |key, value|
    it "should normalize '#{key}' to '#{value}'" do
      Klass.send(:normalize_attribute, key).should == value
    end
  end
end

describe 'Normalizing attribute in an AR model' do
  before do
    User.class_eval do
      include AttributeNormalizer
      normalize_attributes :name
    end
    @user = User.new
  end

  it "should normalize the attribute" do
    @user.name = ' Jimi Hendrix '
    @user.name.should == 'Jimi Hendrix'
  end

  context 'when another instance of the same saved record has been changed' do
    before do
      @user = User.create!(:name => 'Jimi Hendrix')
      @user2 = User.find(@user.id)
      @user2.update_attributes(:name => 'Thom Yorke')
    end

    it "should reflect the change when the record is reloaded" do
      lambda { @user.reload }.should change(@user, :name).from('Jimi Hendrix').to('Thom Yorke')
    end
  end
end